local H = require "tostringGoal.support"
local rendered = {}
for _, names in ipairs({{"alpha", "omega"}, {"omega", "alpha"}}) do
	H.withTypes(function(manager)
		local a, b = manager:Literal(names[1]), manager:Literal(names[2])
		local union = manager:checkedUnion(a, b)
		assert(union:containsAtom(manager:Literal("alpha")) and union:containsAtom(manager:Literal("omega")))
		rendered[#rendered+1] = union:detailString(true)
	end)
end
H.show("first-manager", rendered[1])
H.show("reverse-creation-manager", rendered[2])
-- Different managers are compared by the known literal payloads, not cross-owner relations.
assert(rendered[1] == rendered[2], "T10: union display should not depend on literal allocation order")
