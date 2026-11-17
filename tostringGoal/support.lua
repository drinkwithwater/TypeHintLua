-- Independent type-display probes. Run from the repository root using `thlua run`.
-- Real TypeManager instances and registered HintTasks; no fake type objects.
local TestCase = require "thlua.TestCase"
local uv = require "luv"
local json = require "rapidjson"
local M = {}
function M.count(values)
	local count = 0
	for _ in pairs(values) do count = count + 1 end
	return count
end
function M.equivalent(left, right)
	return left:includeAll(right) and right:includeAll(left)
end
function M.analyze(source, allowErrors)
	local runtime = TestCase.new(source or ""):getRuntime()
	local initialized, initializationError = false, nil
	runtime:promiseMain("[test]"):next(function()
		initialized = true
	end, function(reason)
		initializationError = tostring(reason)
	end):forget()
	uv.run()
	assert(initialized, initializationError or "probe runtime did not initialize")
	assert(not runtime:isReadyFail(), "probe runtime initialization failed")
	for _, diagnostics in pairs(runtime:getAllDiagnostic()) do
		for _, diagnostic in ipairs(diagnostics) do
			assert(allowErrors or diagnostic.severity ~= 1, diagnostic.msg)
		end
	end
	return runtime
end
function M.withTypes(body)
	local runtime = M.analyze("")
	local manager = runtime:getTypeManager()
	local schedule = manager:getScheduleManager()
	local finished, failure = false, nil
	schedule:newHintTask(runtime:getRootNode()):runAsync(function()
		local ok, reason = pcall(body, manager, runtime:getRootNode(), runtime)
		if not ok then failure = tostring(reason) end
		finished = true
	end)
	-- The initial schedule is closed. Drain new tasks explicitly.
	schedule:lateSchedule()
	assert(finished, "probe left an unresolved dependency")
	if failure then error(failure, 0) end
end
function M.fixture(name)
	local file = assert(io.open("tostringGoal/fixtures/" .. name, "rb"))
	local content = file:read("a")
	file:close()
	return content
end
function M.show(label, value)
	-- Quoted output keeps control characters visible and runner logs well formed.
	print(label, json.encode(value))
end
return M
