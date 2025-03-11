local Tiniest = require('./lib/tiniest_for_lune').configure{{}}

local require: any = require

local tests = Tiniest.collect_tests(function()
    local describe = Tiniest.describe

    local function describe_from_file(name: string)
        describe(name, function()
            require(`./{name}.spec`)(Tiniest)
        end)
    end

    describe_from_file('prism/Query')
end)

local results = Tiniest.run_tests(tests, {})
if results.status_tally.fail > 0 then
    error('One or more tests failed.')
end