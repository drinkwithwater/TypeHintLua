local H = require "tostringGoal.support"
H.withTypes(function(manager)
	local fn = manager:checkedFn(manager.type.Integer):Ret(manager.type.Integer)
	local levels = 8
	for _=1, levels do fn = manager:checkedFn(fn, fn):Ret(manager.type.Integer) end
	local rendered = fn:detailString(false)
	assert(tostring(fn) == rendered)
	local _, expanded = rendered:gsub("fn%-", "")
	print("shared-signature-levels", levels+1, "rendered-signatures", expanded, "display-bytes", #rendered)
	H.show("display-prefix", rendered:sub(1, 100))
	assert(expanded == 2^(levels+1)-1 and #rendered > 4096,
		"shared-subgraph rendering strategy changed; review this observation")
	-- Allocation count and byte length are observations, not a timing benchmark.
end)
