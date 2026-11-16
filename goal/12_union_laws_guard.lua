local H = require "goal.support"
H.withTypes(function(manager)
	local function union(...) return manager:checkedUnion(...) end
	local integer, string, nilType = manager.type.Integer, manager.type.String, manager.type.Nil
	assert(union() == manager.type.Never)
	assert(union(integer) == integer)
	assert(union(integer, integer) == integer)
	assert(union(integer, manager:Literal(1)) == integer)
	assert(H.equivalent(union(integer, string), union(string, integer)))
	assert(H.equivalent(union(union(integer, string), nilType), union(integer, union(string, nilType))))
	local optional = union(integer, nilType)
	assert(optional:isNilable() and optional:notnilType() == integer)
	local falsable = union(string, manager.type.False, nilType)
	assert(falsable:trueType() == string)
	assert(H.equivalent(falsable:falseType(), union(manager.type.False, nilType)))
	print("basic union laws and nil/false projections hold")
	-- These laws do not authorize merging stateful Open/Auto objects by shape.
end)
