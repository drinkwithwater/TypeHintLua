local H = require "tostringGoal.support"
H.withTypes(function(manager)
	local fn = manager:checkedFn(manager.type.Integer):Ret(manager.type.String)
	local outsideOK, outsideError
	local co = coroutine.create(function()
		outsideOK, outsideError = pcall(function() return fn:detailString(false) end)
	end)
	assert(coroutine.resume(co))
	assert(coroutine.status(co) == "dead" and outsideOK == false)
	assert(tostring(outsideError):find("requires a registered checker task", 1, true))
	H.show("unregistered-print-error", tostring(outsideError))
	local sequence = {"before"}
	manager:getScheduleManager():newHintTask(manager:getRuntime():getRootNode()):runAsync(function()
		sequence[#sequence+1] = "scheduled"
	end)
	local displayed = fn:detailString(false)
	sequence[#sequence+1] = "after"
	H.show("registered-print", displayed)
	assert(table.concat(sequence, ",") == "before,scheduled,after")
	print("display-wait-order", table.concat(sequence, ","))
end)
