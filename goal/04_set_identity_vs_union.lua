local H = require "goal.support"
H.withTypes(function(manager)
	local integer = manager.type.Integer
	local literal = manager:Literal(1)
	local first = manager:HashableTypeSet()
	first:putAtom(integer)
	first:putAtom(literal)
	local second = manager:HashableTypeSet()
	second:putAtom(integer)
	local firstSet = manager:unifyTypeSet(first)
	local secondSet = manager:unifyTypeSet(second)
	assert(firstSet ~= secondSet and firstSet:getNum() == 2 and secondSet:getNum() == 1)
	assert(firstSet:_buildType() == integer and secondSet:_buildType() == integer)
	print("different member sets normalize to the same Integer")
	-- Raw membership is not semantic containment.
	assert(not secondSet:findAtom(literal))
	assert(integer:includeAtom(literal) == integer)
end)
