local H = require "goal.support"
H.withTypes(function(manager, node)
	local events = {}
	local delayed = manager:AsyncTypeCom(node)
	delayed:setTypeAsync(node, function()
		events[#events + 1] = "resolved"
		return manager.type.Integer
	end)
	assert(not delayed:getResultType() and manager:tryResolveType(delayed) == false)
	assert(manager:tryResolveType(manager.type.Integer) == manager.type.Integer)
	local readyOK, readyError = pcall(function()
		return manager:unionReady(delayed, manager.type.String)
	end)
	assert(not readyOK and tostring(readyError):find("requires an initialized", 1, true))
	assert(not manager:getScheduleManager():isWaitingForbidden())
	-- A coroutine is not automatically a registered checker task.
	local outsideOK, outsideError
	local outside = coroutine.create(function()
		outsideOK, outsideError = pcall(function()
			return manager:checkedUnion(delayed, manager.type.String)
		end)
	end)
	assert(coroutine.resume(outside))
	assert(coroutine.status(outside) == "dead" and outsideOK == false)
	assert(tostring(outsideError):find("requires a registered checker task", 1, true))
	print("outside registered task", tostring(outsideError))
	events[#events + 1] = "before"
	local result = manager:resolveUnion(delayed, manager.type.String)
	events[#events + 1] = "after"
	assert(table.concat(events, ",") == "before,resolved,after")
	assert(result:includeAll(manager.type.Integer) and result:includeAll(manager.type.String))
	assert(manager:tryResolveType(delayed) == manager.type.Integer)
	local ready = manager:unionReady(manager.type.Integer, manager.type.String)
	assert(H.equivalent(ready, result))
	assert(manager:intersectReady(manager.type.Integer, manager.type.String):isEmpty())
	-- A ready atom can hide pending fields. Never silently yield in core operations.
	local left = manager:buildInterface(node, {x = manager.type.Integer})
	local right = manager:buildInterface(node, {y = manager.type.String})
	local structuralOK, structuralError = pcall(function() manager:intersectReady(left, right) end)
	assert(not structuralOK and tostring(structuralError):find("unresolved dependency", 1, true))
	assert(not manager:getScheduleManager():isWaitingForbidden())
	assert(manager:resolveIntersect(left, right):getKind() == "overlap")
	assert(manager:intersectReady(left, right):getKind() == "overlap")
	-- SealTask normally yields when it queues a HintTask. Ready operations
	-- must suppress that cooperative yield as well as event waits.
	local schedule = manager:getScheduleManager()
	local finished = schedule:makeWildEvent()
	local sealFailure
	schedule:newSealTask(manager:getStackManager():getRootStack()):runAsync(function()
		local ok, reason = pcall(function()
			local a = manager:buildInterface(node, {sealX = manager.type.Integer})
			local b = manager:buildInterface(node, {sealY = manager.type.String})
			local readyOK, readyError = pcall(function() return manager:intersectReady(a, b) end)
			assert(not readyOK and tostring(readyError):find("unresolved dependency", 1, true))
			assert(not schedule:isWaitingForbidden())
		end)
		if not ok then sealFailure = tostring(reason) end
		finished:wakeup()
	end)
	finished:wait()
	assert(not sealFailure, sealFailure)
	print("checkedUnion waited:", table.concat(events, ","))
end)
