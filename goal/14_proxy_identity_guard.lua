-- Simulated wrappers for a future native backend, not current Rust userdata.
local meta = {__eq = function(left, right)
	return left.engine == right.engine and left.id == right.id
end}
local first = setmetatable({engine = 1, id = 7}, meta)
local second = setmetatable({engine = 1, id = 7}, meta)
assert(first == second and not rawequal(first, second))
local byType = {[first] = "branch facts"}
assert(byType[second] == nil, "metamethod equality must not be mistaken for table-key identity")
local cachedProxy = first
assert(byType[cachedProxy] == "branch facts")
local originalMeta = {}
local function legacyClassIs(value) return getmetatable(value) == originalMeta end
assert(not legacyClassIs(first))
print("equal wrapper values do not share table keys or legacy class metatables")
