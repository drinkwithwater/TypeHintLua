local H = require "goal.support"
H.withTypes(function(manager, node)
	local left = manager:buildInterface(node, {value = manager.type.Integer})
	local right = manager:buildInterface(node, {value = manager.type.Integer})
	assert(left:includeAll(right))
	-- Deliberate mutation after relation publication, not a supported edit API.
	right:getValueDict()[manager:Literal("value")] = manager.type.String
	local cached = left:includeAll(right)
	local fresh = left:assumeIncludeObject({}, right)
	print("cached comparison", cached, "fresh structural comparison", fresh)
	assert(cached == true and fresh == false,
		"invalidation or mutability contract changed; review this characterization")
	-- Future incremental edits need new immutable descriptions or invalidation.
end)
