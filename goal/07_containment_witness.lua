local H = require "goal.support"
H.withTypes(function(manager)
	local literal = manager:Literal(1)
	local container = manager.type.Integer
	local witness = container:includeAtom(literal)
	assert(container:includeAll(literal) == true)
	assert(witness == container and witness ~= true)
	-- Mistake: == true loses a successful match.
	assert((witness == true) == false)
	-- Mistake: bool conversion loses the original dictionary key.
	local cases = {[container] = "integer branch"}
	assert(cases[witness] == "integer branch" and cases[true] == nil)
	assert(container:includeAtom(manager.type.String) == false)
	print("includeAll is boolean; includeAtom returns a covering atom or false")
end)
