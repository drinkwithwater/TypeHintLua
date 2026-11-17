local H = require "tostringGoal.support"
H.withTypes(function(manager)
	local T = manager.type
	local left = manager:checkedFn(T.Integer):Ret(T.String):Err(T.Integer)
	local right = manager:checkedFn(T.Integer):Ret(T.String):Err(T.False)
	local leftError, rightError = left:getRetTuples():getErrType(), right:getRetTuples():getErrType()
	assert(not H.equivalent(leftError, rightError))
	H.show("left-error-type", tostring(leftError))
	H.show("right-error-type", tostring(rightError))
	H.show("function-left", left:detailString(true))
	H.show("function-right", right:detailString(true))
	assert(left:detailString(true) ~= right:detailString(true),
		"T05: verbose function display must distinguish error-type contracts")
end)
