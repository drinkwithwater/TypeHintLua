local H = require "goal.support"
local foreign
H.withTypes(function(manager) foreign = manager:Literal("foreign atom") end)
H.withTypes(function(manager)
	local localAtom = manager:Literal(123456)
	assert(foreign:getManager() ~= manager and foreign.id == localAtom.id)
	local set = manager:HashableTypeSet()
	set:putAtom(foreign)
	set:putAtom(localAtom)
	print("different managers and values, same id; retained members", set:getNum())
	assert(set:getNum() == 1, "ownership handling changed; review this characterization")
	-- Deliberate unsupported mixing, not evidence that normal checks mix managers.
	-- A future public handle API should reject it before collection insertion.
end)
