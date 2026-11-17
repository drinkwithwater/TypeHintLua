local H = require "tostringGoal.support"
local runtime = H.analyze("")
local manager = runtime:getTypeManager()
local schedule = manager:getScheduleManager()
local finished, displayOK, displayError = false, nil, nil
schedule:newHintTask(runtime:getRootNode()):runAsync(function()
	local fn = manager:checkedFn(manager.type.Integer):Ret(manager.type.String)
	displayOK, displayError = pcall(tostring, fn)
	finished = true
end)
-- Catch the drain failure separately: the failed metamethod has already
-- registered the task as a waiter before Lua rejects its coroutine.yield.
local scheduleOK, scheduleError = pcall(function() schedule:lateSchedule() end)
assert(finished, "display task did not run")
print("pending-tostring-ok", displayOK, "schedule-drain-ok", scheduleOK)
if not displayOK then
	H.show("pending-tostring-error", tostring(displayError))
	assert(tostring(displayError):find("yield across", 1, true), "unexpected display failure")
end
if not scheduleOK then
	H.show("subsequent-schedule-error", tostring(scheduleError))
	assert(tostring(scheduleError):find("cannot resume dead coroutine", 1, true), "unexpected schedule failure")
end
assert(displayOK and scheduleOK, "T17: pending function tostring must not cross an invalid yield boundary or leave dead waiters")
