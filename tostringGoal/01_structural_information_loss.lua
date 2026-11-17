local H = require "tostringGoal.support"
H.withTypes(function(manager, node)
	local T = manager.type
	local structs = {manager:buildStruct(node, {x=T.Integer}), manager:buildStruct(node, {x=T.String})}
	local interfaces = {manager:buildInterface(node, {x=T.Integer}), manager:buildInterface(node, {x=T.String})}
	for _, pair in ipairs({structs, interfaces}) do
		assert(pair[1]:getValueDict()[manager:Literal("x")] ~= pair[2]:getValueDict()[manager:Literal("x")])
		assert(not H.equivalent(pair[1], pair[2]))
		H.show("shape-left", pair[1]:detailString(true))
		H.show("shape-right", pair[2]:detailString(true))
	end
	assert(structs[1]:detailString(true) ~= structs[2]:detailString(true)
		and interfaces[1]:detailString(true) ~= interfaces[2]:detailString(true),
		"T01: verbose structural display must expose incompatible fields")
end)
