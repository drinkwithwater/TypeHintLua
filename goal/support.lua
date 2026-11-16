-- Run internal API probes from the repository root using `thlua run`.
-- Real TypeManager instances and registered HintTasks; no fake type objects.
local TestCase = require "thlua.TestCase"
local uv = require "luv"
local M = {}
function M.count(values)
	local count = 0
	for _ in pairs(values) do count = count + 1 end
	return count
end
function M.equivalent(left, right)
	return left:includeAll(right) and right:includeAll(left)
end
function M.withTypes(body)
	local runtime = TestCase.new(""):getRuntime()
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
			assert(diagnostic.severity ~= 1, diagnostic.msg)
		end
	end
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
return M
