local H = require "goal.support"
H.withTypes(function(manager, node)
	local function recursive(valueType)
		local reference = manager:AsyncTypeCom(node)
		local object = manager:buildInterface(node, {
			value = valueType,
			next = manager:buildOrNil(node, reference),
		})
		reference:setTypeAsync(node, function() return object end)
		return object
	end
	local left = recursive(manager.type.Integer)
	local sameShape = recursive(manager.type.Integer)
	local different = recursive(manager.type.String)
	assert(left ~= sameShape and H.equivalent(left, sameShape))
	for _ = 1, 3 do
		assert(not left:includeAll(different), "recursive assumptions must not prove incompatible value fields")
		assert(not different:includeAll(left))
		assert(H.equivalent(left, sameShape), "failed comparisons must not contaminate successful ones")
	end
	print("recursive equality, inequality, and repeated queries remain consistent")
end)
