local H = require "tostringGoal.support"
H.withTypes(function(manager)
	local untouched = manager:checkedFn(manager.type.Integer)
	assert(pcall(function() untouched:Ret(manager.type.String) end))
	local printed = manager:checkedFn(manager.type.Integer)
	assert(not printed._retTuples)
	H.show("before-finalization", printed:detailString(false))
	print("printing-published-return", not not printed._retTuples)
	local ok, reason = pcall(function() printed:Ret(manager.type.String) end)
	print("append-return-after-print", ok)
	if not ok then H.show("append-failure", tostring(reason)) end
	assert(ok, "T07: inspecting a function builder must not silently finalize its return contract")
end)
