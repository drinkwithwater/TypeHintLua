local H = require "goal.support"
H.withTypes(function(manager)
	local original = manager:checkedUnion(manager.type.Integer, manager.type.String)
	local set = manager:HashableTypeSet()
	set:initFromUnion(original)
	set:putAtom(manager.type.Nil)
	local result = set:frozen():_buildType()
	print("members", set:getNum(), "nilable", result:isNilable())
	assert(result:isNilable(),
		"G02: adding Nil after initFromUnion must invalidate the cached non-nil result")
end)
