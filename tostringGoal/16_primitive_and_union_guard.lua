local H = require "tostringGoal.support"
H.withTypes(function(manager)
	local T = manager.type
	for _, entry in ipairs({{T.Integer,"Integer"}, {T.Number,"Number"}, {T.String,"String"},
		{T.Nil,"Nil"}, {T.Never,"Never"}, {T.True,"True"}, {T.False,"False"}}) do
		assert(tostring(entry[1]) == entry[2])
	end
	assert(T.True:detailString(true) == "Literal(true)")
	assert(T.False:detailString(true) == "Literal(false)")
	local union = manager:checkedUnion(manager:Literal("guard-alpha"), manager:Literal("guard-beta"), T.Nil)
	local first = tostring(union)
	for _=1, 5 do assert(tostring(union) == first) end
	H.show("stable-same-object-union", first)
	print("primitive names and repeated same-object union rendering hold")
end)
