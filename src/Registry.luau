--!native
--!optimize 2
--!nolint LocalShadow
local Piece = require('./Piece')
local TagMarker = Piece.TagMarker
local BuiltInPiece = Piece.BuiltInPiece
local PrismOnAdd = Piece.OnAdd
local PrismOnRemove = Piece.OnRemove
local IsPiece = Piece.is

local Record = require('./Record')
local Pair = require('./Pair')

local Data = require('./Modules/Data')
local Clean = require('./Modules/Clean')

local Types = require('./Types')
type Cleaning = Types.Cleaning

type Entity = Types.Entity
type Piece<D = unknown> = Types.Piece<D>

type UsedAs<D = unknown> = Types.UsedAs<D>
type DataMap = Types.DataMap

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

    local function Cast(
        registry: Registry,
        target: any
    ): Entity?

        if typeof(target) == 'number' then
            return target
        end

        if typeof(target) ~= 'table' then
            return
        end

        if not IsPiece(target) then
            return
        end
        
        local cached = registry.cachedPieces[target]
        if cached then return cached end

        local entity = registry:entity()
        registry.cachedPieces[target] = entity

        return entity
    end

    function Registry.cast(
        self: Registry,
        ...: UsedAs
    ): ...Entity
    
        local results = {}
        
        for _, target in { ... } do
            local casted = Cast(self, target)
            assert(casted, 'Invalid entity: not piece or entity')

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

    function Registry.include<Q...>(
        self: Registry,
        queries: { Query<Q...> }
    )
        for _, query in queries do
            assert(type(query) == 'table', 'Invalid query: must be a table')

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

                if query.settings.async then
                    local coroutine = task.spawn(
                        traitRecord.trait, data, unpack(pieces)
                    )
                    table.insert(data.cleaning, coroutine)
                else
                    traitRecord.trait(data, unpack(pieces))
                end
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

    function Registry.view(
        self: Registry,
        query: Query
    ): { Entity }
        
        local cachedEntities = self.consumedQueries[query]
        if not cachedEntities then return {} end

        local cache = {}
        for entity in pairs(cachedEntities)  do
            table.insert(cache, entity)
        end

        return cache
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

    local function Add<D>(
        registry: Registry,
        entity: UsedAs,
        piece: UsedAs<D>,
        data: D?
    ): Piece<D>?

        if registry:contains(entity, piece) then
            return
        end

        local entity, castedPiece = registry:cast(entity, piece)

        local records = registry.records
        local storage = registry.storage

        do
            local record = records[entity]
            local pieceRecord = records[castedPiece]
            Record.append(record.bitmap, pieceRecord)
        end

        if not storage[entity] then
            storage[entity] = {}
        end

        if not data and typeof(piece) == 'table' then
            local defaultData = piece.data

            if typeof(defaultData) == 'table' then
                local postData = Data.merge(defaultData, {}, 'merge')
                data = Data.transform(postData)
            else
                data = defaultData
            end
        end

        local entityStorage = storage[entity]

        if data then
            entityStorage[castedPiece] = Piece.New(data)
        end

        local onAdd = registry:ask(entity, PrismOnAdd)
        if onAdd then
            onAdd.data(entity, castedPiece, data)
        end

        return entityStorage[castedPiece]
    end

    function Registry.add<D>(
        self: Registry,
        entity: UsedAs,
        piece: UsedAs<D> | DataMap,
        data: D?
    ): (D | DataMap)?

        local isPiece = Cast(self, piece)

        if isPiece then
            local piece = piece :: UsedAs<D>
            local postData = Add(self, entity, piece, data)

            self:match(entity)
            return postData
        end

        local pieces = piece :: DataMap
        local dataMap = {}

        for piece, preData in pieces do
            if typeof(preData) == 'table' and getmetatable(preData) == TagMarker then
                Data.merge(preData, pieces)
                continue
            end

            local data = preData ~= TagMarker and preData
            local postData = Add(self, entity, piece, data)
            dataMap[piece] = postData
        end

        self:match(entity)
        return dataMap
    end
    
    local function UnnapendDataFromEntity(
        registry: Registry,
        entity: UsedAs,
        piece: UsedAs
    )
        local entity, piece = registry:cast(entity, piece)

        local records = registry.records

        do
            local record = records[entity]
            local pieceRecord = records[piece]
            Record.unappend(record.bitmap, pieceRecord)
        end
    end

    local function Remove(
        registry: Registry,
        entity: UsedAs,
        piece: UsedAs
    )
        local entity, piece = registry:cast(entity, piece)

        local storage = registry.storage

        local entityStorage = storage[entity]
        if not entityStorage then return end

        local storedData = entityStorage[piece]
        
        if storedData then
            local data = storedData.data

            if typeof(data) == 'table' then
                for index, value in data do
                    Clean(value)
                    data[index] = nil
                end
            else
                Clean(data)
                storedData.data = nil
            end

            entityStorage[piece] = nil
        end

        local onRemove = registry:ask(entity, PrismOnRemove)
        if onRemove then
            onRemove.data(entity, piece)
        end
    end

    function Registry.remove<D>(
        self: Registry,
        entity: UsedAs,
        ...: UsedAs
    )
        for index = 1, select('#', ...) do
            local piece = select(index, ...)
            UnnapendDataFromEntity(self, entity, piece)
            self:match(entity)
            Remove(self, entity, piece)
        end
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
            local pieces = {}

            for piece in entityStorage do
                table.insert(pieces, piece)
            end
            self:remove(entity, unpack(pieces))

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
        if not record then
            return false
        end

        for index = 1, select('#', ...) do

            local piece = select(index, ...)
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
    ): Piece<D>

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