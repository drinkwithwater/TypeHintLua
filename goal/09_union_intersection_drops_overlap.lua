local H = require "goal.support"
H.withTypes(function(manager, node)
	local left = manager:buildInterface(node, {x = manager.type.Integer})
	local right = manager:buildInterface(node, {y = manager.type.String})
	local optionalRight = manager:checkedUnion(right, manager.type.Nil)
	assert(left:intersectAtom(right) == true)
	assert(left:intersectSome(optionalRight), "the union must have a nonempty overlap")
	local result = left:safeIntersect(optionalRight)
	print("overlap exists", true, "safe result", tostring(result))
	assert(result ~= manager.type.Never,
		"G09: safeIntersect must not discard a non-representable overlap inside a union")
end)
