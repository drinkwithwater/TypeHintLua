local H = require "goal.support"
H.withTypes(function(manager, node)
	local T = manager.type
	local types = {T.Never, T.Nil, T.False, T.True, T.Integer, T.Number, T.String,
		T.Truth, manager:Literal(1), manager:Literal(2.5), manager:Literal("s")}
	for _, a in ipairs(types) do
		assert(H.equivalent(a:safeIntersect(a), a))
		for _, b in ipairs(types) do
			local ab, ba = a:intersectResult(b), b:intersectResult(a)
			assert(ab:getKind() == ba:getKind())
			assert(ab:getType() and H.equivalent(ab:getType(), ba:getType()))
			assert(a:includeAll(ab:getType()) and b:includeAll(ab:getType()))
			assert(a:intersectSome(b) == not ab:isEmpty())
		end
	end
	local choices = {T.Nil, T.False, T.Integer, T.String, manager:Literal(1)}
	for _, a in ipairs(choices) do
		for _, b in ipairs(choices) do
			for _, c in ipairs(choices) do
				local lhs = a:safeIntersect(manager:checkedUnion(b, c))
				local rhs = manager:checkedUnion(a:safeIntersect(b), a:safeIntersect(c))
				assert(H.equivalent(lhs, rhs), "primitive intersection must distribute over union")
			end
		end
	end
	local a = manager:buildInterface(node, {x = T.Integer})
	local b = manager:buildInterface(node, {y = T.String})
	local ua, ub = manager:checkedUnion(a, T.Nil), manager:checkedUnion(b, T.Nil)
	assert(ua:intersectResult(ub):getKind() == "overlap")
	assert(ub:intersectResult(ua):getKind() == "overlap")
	assert(ua:safeIntersect(ub) == false and ua:intersectSome(ub))
	local both = manager:checkedUnion(a, b)
	assert(both:includeAll(a) and both:includeAll(b))
	assert(both:safeIntersect(both) == both)
	assert(a:safeIntersect(both) == a)
	print("intersection symmetry, absorption, distribution and overlap propagation hold")
end)
