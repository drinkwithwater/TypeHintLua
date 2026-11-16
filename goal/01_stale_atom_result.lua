local H = require "goal.support"
H.withTypes(function(manager)
	local set = manager:HashableTypeSet()
	set:initFromAtom(manager.type.Integer)
	set:putAtom(manager.type.String)
	local frozen = set:frozen()
	assert(frozen:getNum() == 2)
	local result = frozen:_buildType()
	print("members", frozen:getNum(), "result", tostring(result))
	assert(result:includeAll(manager.type.String),
		"G01: adding String after initFromAtom must invalidate the cached Integer result")
end)
