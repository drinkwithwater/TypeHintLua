local H = require "goal.support"
H.withTypes(function(manager, node)
	local events = {}
	local delayed = manager:AsyncTypeCom(node)
	delayed:setTypeAsync(node, function()
		events[#events + 1] = "resolved"
		return manager.type.Integer
	end)
	assert(not delayed:getResultType())
	-- A coroutine is not automatically a registered checker task.
	local outsideOK, outsideError
	local outside = coroutine.create(function()
		outsideOK, outsideError = pcall(function()
			return manager:checkedUnion(delayed, manager.type.String)
		end)
	end)
	assert(coroutine.resume(outside))
	assert(coroutine.status(outside) == "dead" and outsideOK == false)
	print("outside registered task", tostring(outsideError))
	events[#events + 1] = "before"
	local result = manager:checkedUnion(delayed, manager.type.String)
	events[#events + 1] = "after"
	assert(table.concat(events, ",") == "before,resolved,after")
	assert(result:includeAll(manager.type.Integer) and result:includeAll(manager.type.String))
	print("checkedUnion waited:", table.concat(events, ","))
end)
