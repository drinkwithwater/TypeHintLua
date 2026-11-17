local H = require "tostringGoal.support"
H.withTypes(function(manager, node)
	local member = manager:buildMfn(node, manager.type.Integer):Ret(manager.type.String)
	local headless = member:getHeadlessFn():getParTuple()
	assert(#headless == 1 and headless:get(1) == manager.type.Integer)
	local owner = manager:buildInterface(node, {})
	local bound = member:toTypeFn(owner):getParTuple()
	assert(#bound == 2 and bound:get(2) == manager.type.Integer)
	H.show("headless-parameters", tostring(headless))
	H.show("member-display", member:detailString(true))
	assert(member:detailString(true):find("Integer", 1, true),
		"T04: member display must not drop the first explicit parameter of a headless signature")
end)
