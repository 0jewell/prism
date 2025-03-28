--!native
--!optimize 2
--!nolint LocalShadow
local Piece = require('./Piece')
local BuiltInPiece = Piece.BuiltInPiece
local PrismOnAdd = Piece.OnAdd
local PrismOnRemove = Piece.OnRemove

local Record = require('./Record')
local Pair = require('./Pair')

local Data = require('./Modules/Data')
local Clean = require('./Modules/Clean')

local Types = require('./Types')
type Cleaning = Types.Cleaning

type Entity = Types.Entity
type Piece<D> = Types.Piece<D>

type UsedAs<D = unknown> = Types.UsedAs<D>
type DeepTable<T> = Types.DeepTable<T>

type Query<Q... = ...any> = Types.Query<Q...>

type Bitmap = Types.Bitmap
type Record = Types.Record

type Registry = Types.Registry

local Registry = {}
do
    Registry.__index = Registry

    function Registry.New(): Registry
        local self = {
            nextId = 1,
            size = 0,
            cachedPieces = {},
            records = {},
            storage = {},
            queryStorage = {},
            queryMaps = {},
            consumedQueries = {}
        }
        setmetatable(self, Registry)

        self:add(PrismOnAdd, BuiltInPiece)
        self:add(PrismOnRemove, BuiltInPiece)
        self:add(BuiltInPiece, BuiltInPiece)

        return self
    end

    function Registry.entity(self: Registry): Entity
        return self:entityAt(self.nextId)
    end

    function Registry.entityAt(
        self: Registry,
        at: Entity
    ): Entity

        if self:contains(at) then
            error('Invalid id: entity already exist')
        end

        if at >= self.nextId then
            self.nextId = at + 1
        end

        local record = Record.generate(at)
        self.records[at] = record

        self.size += 1
        return at
    end

    function Registry.cast(
        self: Registry,
        ...: UsedAs
    ): ...Entity
    
        local results = {}

        local function casting(
            target: UsedAs
        ): Entity
        
            if typeof(target) == 'number' then
                return target
            end

            if typeof(target) == 'table' then
                local cached = self.cachedPieces[target]
                if cached then return cached end

                local entity = self:entity()
                self.cachedPieces[target] = entity

                return entity
            end

            error('Invalid entity: not piece or entity')
        end
        
        for _, target in { ... } do
            local casted = casting(target)
            table.insert(results, casted)
        end
        
        return unpack(results)
    end

    function Registry.pair(
        self: Registry,
        relation: UsedAs,
        target: UsedAs
    )
        local relation, target = self:cast(relation, target)

        local pair = Pair.pack(relation, target)
        return self:entityAt(pair)
    end

    local function AssembleQueryMap(
        registry: Registry,
        entities: { UsedAs }
    ): Bitmap

        local map = {}

        for _, entity in entities do
            local entity = registry:cast(entity)

            local record = registry.records[entity]
                or error('Invalid entity: no record')

            Record.append(map, record)
        end

        return map
    end

    function Registry.include(
        self: Registry,
        queries: { DeepTable<Query> }
    )
        for _, query in queries do
            assert(type(query) == 'table', 'Invalid query: must be a table')

            if not query.trait then
                local query: { DeepTable<Query> } = query :: any
                return self:include(query)
            end

            local priority = query.settings.priority
                or error('Invalid query: must have priority')

            local queryStorage = self.queryStorage
            queryStorage[priority] = queryStorage[priority] or {}

            table.insert(queryStorage[priority], query)
            
            local querying = { query.settings.query() }
            local map = AssembleQueryMap(self, querying)

            self.queryMaps[query] = map
        end
    end

    local function CallQueryRow(
        registry: Registry,
        row: { Query },
        entity: Entity
    )
        local consumed = registry.consumedQueries

        local record = registry.records[entity]
            or error('Invalid entity: no record')

        local function callTraitsFromQuery(
            query: Query
        )
            local queryData = consumed[query]
            if queryData and queryData[entity] then return end

            for _, traitRecord in query.traits do
                local cleaning, pieces = {}, {}

                local data = {
                    registry = registry,
                    entity = entity,
                    cleaning = cleaning
                }

                for _, piece in { query.settings.query() } do
                    local storedData = registry:ask(entity, piece)
        
                    table.insert(pieces, storedData)
                end
        
                consumed[query] = consumed[query] or {}
                consumed[query][entity] = cleaning

                traitRecord.trait(data, unpack(pieces))
            end
        end

        local function cleanupTraitsFromQuery(
            query: Query
        )
            for _, traitRecord in query.traits do
                local queryData = consumed[query]

                local cleaning = queryData and queryData[entity]
                if not cleaning then return end

                queryData[entity] = nil

                if not next(queryData) then
                    consumed[query] = nil
                end

                Clean(cleaning)
            end
        end

        local function tryMatching(
            query: Query
        )
            local queryMap = registry.queryMaps[query]
            local canMatch = Record.compare(record.bitmap, queryMap)

            return if canMatch
                then callTraitsFromQuery(query)
                else cleanupTraitsFromQuery(query)
        end

        for _, query in row do
            tryMatching(query)
        end
    end

    function Registry.match(
        self: Registry,
        entity: UsedAs
    )
        local castedEntity = self:cast(entity)

        for priority, row in self.queryStorage do
            CallQueryRow(self, row, castedEntity)
        end
    end

    function Registry.add<D>(
        self: Registry,
        entity: UsedAs,
        piece: UsedAs<D>,
        data: D?
    ): D?

        if self:contains(entity, piece) then return end
        
        local entity, castedPiece = self:cast(entity, piece)

        local records = self.records

        local record = records[entity]
        local pieceRecord = records[castedPiece]

        Record.append(record.bitmap, pieceRecord)

        local storage = self.storage

        if not storage[entity] then
            storage[entity] = {}
        end

        local entityStorage = storage[entity]
        
        if not data and typeof(piece) == 'table' and piece.data then
            local default = piece.data
        
            if typeof(default) == 'table' then
                local newData = Data.merge(default, {})
                data = Data.transform(newData)
            else
                data = default
            end
        end

        if data then
            entityStorage[castedPiece] = { data = data }
        end

        local onAdd = self:ask(entity, PrismOnAdd)
        if onAdd then
            onAdd.data(entity, castedPiece, data)
        end

        self:match(entity)

        return data
    end

    function Registry.remove<D>(
        self: Registry,
        entity: UsedAs,
        piece: UsedAs<D>
    )
        local entity, piece = self:cast(entity, piece)

        local records = self.records

        local record = records[entity]
        local pieceRecord = records[piece]

        Record.unappend(record.bitmap, pieceRecord)

        local storage = self.storage

        local entityStorage = storage[entity]
        if not entityStorage then return end

        local storedData = entityStorage[piece]
        
        if storedData then
            Clean(storedData)
            entityStorage[piece] = nil
        end

        local onRemove = self:ask(entity, PrismOnRemove)
        if onRemove then
            onRemove.data(entity, piece)
        end

        self:match(entity)
    end

    function Registry.delete(
        self: Registry,
        entity: UsedAs
    )
        local castedEntity = self:cast(entity)

        local records = self.records
        local storage = self.storage

        if not records[castedEntity] then return end

        local entityStorage = storage[castedEntity]

        if entityStorage then
            for piece in entityStorage do
                self:remove(entity, piece)
            end

            storage[castedEntity] = nil
        end

        records[castedEntity] = nil

        if typeof(entity) == 'table' then
            self.cachedPieces[entity] = nil
        end
        
        self.size -= 1
    end

    function Registry.contains(
        self: Registry,
        entity: UsedAs,
        ...: UsedAs
    ): boolean
        
        local entity = self:cast(entity)

        local records = self.records

        local record = records[entity]
        if not record then return false end

        for i = 1, select('#', ...) do

            local piece = select(i, ...)
            local castedPiece = self:cast(piece)
            
            local pieceRecord = records[castedPiece]
            
            local hasPiece = Record.contains(record, pieceRecord)
            if not hasPiece then
                return false
            end
        end

        return true
    end

    function Registry.ask<D>(
        self: Registry,
        entity: UsedAs,
        piece: UsedAs<D>
    ): Piece<D>?

        local entity = self:cast(entity)

        local entityData = self.storage[entity]
        assert(
            entityData,
            'Invalid entity: does not have data. Check using contains first'
        )

        local piece = self:cast(piece)

        return entityData[piece]
    end
end

return table.freeze(Registry)