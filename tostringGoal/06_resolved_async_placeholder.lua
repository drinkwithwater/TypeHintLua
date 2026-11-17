local H = require "tostringGoal.support"
H.withTypes(function(manager, node)
	local ref = manager:AsyncTypeCom(node)
	ref:setTypeAsync(node, function() return manager.type.Integer end)
	assert(ref:checkAtomUnion() == manager.type.Integer)
	local tuple = manager:TypeTuple(node, {ref})
	H.show("resolved-tostring", tostring(ref))
	H.show("resolved-detail", ref:detailString(true))
	H.show("tuple-with-reference", tostring(tuple))
	assert(not ref:detailString(true):find("TODO", 1, true) and tuple:detailString(true):find("Integer", 1, true),
		"T06: resolved references must not become TODO placeholders in nested type display")
end)
