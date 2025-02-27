--!native
--!optimize 2
--!nolint LocalShadow
local Package = script.Parent

local Record = require(script.Record)
local Pair = require(script.Pair)

local Data = require(Package.Common.Data)
local Clean = require(Package.Common.Clean)

local Types = require(Package.Common.Types)
type Cleaning = Types.Cleaning

type Entity = Types.Entity
type Piece<D> = Types.Piece<D>

type UsedAs<D = unknown> = Types.UsedAs<D>

type Query<Q... = ...any> = Types.Query<Q...>

type BitMap = Types.BitMap
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
            entityRecords = {},
            bitMaps = {},
            storage = {},
            queryStorage = {},
            queryMaps = {},
            consumedQueries = {}
        }

        return setmetatable(self, Registry)
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
        self.entityRecords[at] = record

        self.size += 1
        return at
    end

    function Registry.cast(
        self: Registry,
        ...: UsedAs
    ): ...Entity

        local results = {}
        
        for _, target in { ... } do
            if typeof(target) == 'number' then
                table.insert(results, target)

            else
                assert(
                    typeof(target) == 'table',
                    'Invalid entity: not a piece or id'
                )

                local cached = self.cachedPieces[target]
                if cached then
                    table.insert(results, cached)
                else
                    local castedEntity = self:entity()
                    self.cachedPieces[target] = castedEntity

                    table.insert(results, castedEntity)
                end
            end
        end
        
        return table.unpack(results)
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
    ): BitMap

        local map = {}

        for _, entity in entities do
            local castedEntity = registry:cast(entity)

            local record = registry.entityRecords[castedEntity]
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
        local BitMap = registry.bitMaps[entity]

        local function callTraitsFromQuery(
            query: Query
        )
            if consumed[query] and consumed[query][entity] then return end

            for _, traitRecord in query.traits do
                local cleaning = {}
                local entityDatas = {}

                local data = {
                    registry = registry,
                    entity = entity,
                    cleaning = cleaning
                }

                for _, piece in { query.settings.query() } do
                    local storedData = registry:ask(entity, piece)
        
                    table.insert(entityDatas, storedData)
                end
        
                local thread = task.spawn(
                    traitRecord.trait,
                    data, unpack(entityDatas)
                )
                table.insert(cleaning, thread)
        
                consumed[query] = consumed[query] or {}
                consumed[query][entity] = cleaning
            end
        end

        local function cleanupTraitsFromQuery(
            query: Query
        )
            for _, traitRecord in query.traits do
                local cleaning = consumed[query] and consumed[query][entity]
                if not cleaning then continue end

                consumed[query][entity] = nil

                if not next(consumed[query]) then
                    consumed[query] = nil
                end

                Clean(cleaning)
            end
        end

        local function tryMatching(
            query: Query
        )
            local queryMap = registry.queryMaps[query]
            local canMatch = Record.compare(BitMap, queryMap)

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

        local bitMaps = self.bitMaps
        local entityRecords = self.entityRecords

        if not bitMaps[entity] then
            bitMaps[entity] = {}
        end

        local map = bitMaps[entity]

        local record = entityRecords[castedPiece]
            or error('Invalid entity: no record')

        Record.append(map, record)

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

        self:match(entity)

        return data
    end

    function Registry.remove<D>(
        self: Registry,
        entity: UsedAs,
        piece: UsedAs<D>
    )
        local entity, piece = self:cast(entity, piece)

        local bitMaps = self.bitMaps
        local entityRecords = self.entityRecords

        local map = bitMaps[entity]
        if not map then return end

        local record = entityRecords[piece]
            or error('Invalid entity: no record')

        Record.unappend(map, record)

        local storage = self.storage

        local entityStorage = storage[entity]
        if not entityStorage then return end

        local storedData = entityStorage[piece]
        
        if storedData then
            Clean(storedData)
            entityStorage[piece] = nil
        end

        self:match(entity)
    end

    function Registry.delete(
        self: Registry,
        entity: UsedAs
    )
        local castedEntity = self:cast(entity)

        local bitMaps = self.bitMaps
        local storage = self.storage

        if not bitMaps[castedEntity] then return end

        local entityStorage = storage[castedEntity]

        if entityStorage then
            for piece in entityStorage do
                self:remove(entity, piece)
            end

            storage[castedEntity] = nil
        end

        bitMaps[castedEntity] = nil

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

        local entityMap = self.bitMaps[entity]
        if not entityMap then return false end

        for i = 1, select('#', ...) do

            local piece = select(i, ...)
            local castedPiece = self:cast(piece)
            
            local pieceRecord = self.entityRecords[castedPiece]
            assert(pieceRecord, 'Invalid entity: no record')

            local hasPiece = Record.contains(entityMap, pieceRecord)
            if hasPiece then
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