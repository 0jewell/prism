local Tiniest = require('./lib/tiniest_for_lune').configure{{}}

local require: any = require

local tests = Tiniest.collect_tests(function()
    local describe = Tiniest.describe

    local function describeFromFile(name: string)
        describe(name, function()
            require(`./{name}.spec`)(Tiniest)
        end)
    end

    describeFromFile('prism/archetype')
    describeFromFile('prism/query')
    describeFromFile('prism/world')
end)

do
    local results = Tiniest.run_tests(tests, {})

    if results.status_tally.fail > 0 then
        error('one or more tests failed.')
    end
end