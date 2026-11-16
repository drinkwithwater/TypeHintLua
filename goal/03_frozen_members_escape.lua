local H = require "goal.support"
H.withTypes(function(manager)
	local set = manager:HashableTypeSet()
	set:putAtom(manager.type.Integer)
	set:putAtom(manager.type.String)
	local frozen = set:frozen()
	local contents = frozen:getDict()
	-- Deliberate external mutation through the exposed owned table.
	local accepted = pcall(function() contents[manager.type.String.id] = nil end)
	print("mutation accepted", accepted, "actual members", H.count(frozen:getDict()), "cached members", frozen:getNum())
	assert(H.count(frozen:getDict()) == frozen:getNum() and frozen:findAtom(manager.type.String) == manager.type.String,
		"G03: callers must not be able to corrupt frozen membership and its cached count")
end)
