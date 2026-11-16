local H = require "goal.support"
local HashableTypeSet = require "thlua.type.HashableTypeSet"
H.withTypes(function(manager)
	local set = manager:HashableTypeSet()
	set:putAtom(manager:Literal("goal-intern-a"))
	set:putAtom(manager:Literal("goal-intern-b"))
	local original = manager:unifyTypeSet(set)
	local freeze, calls = HashableTypeSet.frozen, 0
	HashableTypeSet.frozen = function(self)
		calls = calls + 1
		return freeze(self)
	end
	local ok, reason = pcall(function()
		for _ = 1, 5 do assert(manager:unifyTypeSet(set) == original) end
	end)
	HashableTypeSet.frozen = freeze
	assert(ok, reason)
	print("cache hits", 5, "FrozenTypeSet constructions", calls)
	-- Characterization, not a semantic bug or a timing benchmark.
	assert(calls == 5, "allocation strategy changed; review this characterization")
end)
