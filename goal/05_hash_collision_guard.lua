local H = require "goal.support"
H.withTypes(function(manager)
	local atoms, buckets = {}, {}
	for i = 1, 24 do atoms[i] = manager:Literal("goal-hash-" .. i) end
	for i = 1, #atoms do
		for j = i + 1, #atoms do
			local set = manager:HashableTypeSet()
			set:putAtom(atoms[i])
			set:putAtom(atoms[j])
			local previous = buckets[set:getHash()]
			if previous then
				local left = manager:unifyTypeSet(previous)
				local right = manager:unifyTypeSet(set)
				assert(left ~= right, "hash collision must not merge different sets")
				assert(left:findAtom(atoms[i]) ~= right:findAtom(atoms[i])
					or left:findAtom(atoms[j]) ~= right:findAtom(atoms[j]))
				assert(manager:unifyTypeSet(previous) == left)
				assert(manager:unifyTypeSet(set) == right)
				print("same hash, different sets, correct collision resolution")
				return
			end
			buckets[set:getHash()] = set
		end
	end
	error("no collision found; update this characterization for the new hash function")
end)
