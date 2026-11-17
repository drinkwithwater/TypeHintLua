local H = require "goal.support"
H.withTypes(function(manager)
	local function set(...)
		local builder = manager:HashableTypeSet()
		for _, atom in ipairs({...}) do builder:putAtom(atom) end
		return manager:unifyTypeSet(builder)
	end
	local I, S, N = manager.type.Integer, manager.type.String, manager.type.Nil
	local a, b, empty = set(I, S), set(S, N), set()
	assert(a:unionSet(b) == set(I, S, N))
	assert(a:intersectSet(b) == set(S))
	assert(a:subtractSet(b) == set(I))
	assert(a:unionSet(empty) == a and a:intersectSet(empty) == empty)
	assert(a:subtractSet(a) == empty and a:containsSet(empty))
	assert(a:containsSet(set(I)) and not a:containsSet(b))
	assert(a:unionSet(b) == b:unionSet(a))
	assert(a:intersectSet(b) == b:intersectSet(a))
	assert(a:subtractSet(b):unionSet(a:intersectSet(b)) == a)
	-- Identity membership is deliberately distinct from semantic containment.
	local literal = manager:Literal(1)
	assert(set(I):intersectSet(set(literal)) == empty)
	assert(set(I):subtractSet(set(literal)) == set(I))
	assert(I:containsAtom(literal))
	local builder = manager:HashableTypeSet()
	builder:putAtom(I)
	local frozen = manager:unifyTypeSet(builder)
	builder:getDict()[I.id] = nil
	assert(builder:getNum() == 1 and builder:findAtom(I) == I)
	builder:initFromUnion(manager:checkedUnion(S, N))
	assert(frozen == set(I) and frozen:getNum() == 1)
	assert(H.equivalent(manager:unifyAndBuild(builder), manager:checkedUnion(I, S, N)))
	local count = 0
	for atom in a:atoms() do count = count + 1; assert(a:findAtom(atom)) end
	assert(count == a:getNum())
	print("identity set algebra and snapshot isolation hold")
end)
