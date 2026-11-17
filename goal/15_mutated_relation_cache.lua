local H = require "goal.support"
local QueryContext = require "thlua.type.QueryContext"
H.withTypes(function(manager, node)
	local left = manager:buildInterface(node, {value = manager.type.Integer})
	local right = manager:buildInterface(node, {value = manager.type.Integer})
	assert(left:includeAll(right))
	-- The public field dictionary is now a snapshot, not an edit API.
	right:getValueDict()[manager:Literal("value")] = manager.type.String
	local cached = left:includeAll(right)
	local fresh = left:assumeIncludeObject(QueryContext.new(manager), right)
	print("cached comparison", cached, "fresh structural comparison", fresh)
	assert(cached == true and fresh == true)
	assert(right:getValueDict()[manager:Literal("value")] == manager.type.Integer)
	local ok, reason = pcall(function() right:lateInit({}, {}, false, false) end)
	assert(not ok and tostring(reason):find("already published", 1, true))
	-- Edits construct a new description and therefore receive a new TypeId.
	local edited = manager:buildInterface(node, {value = manager.type.String})
	assert(edited.id ~= right.id and not left:includeAll(edited))
end)
