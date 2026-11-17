local H = require "goal.support"
local QueryContext = require "thlua.type.QueryContext"
H.withTypes(function(manager, node)
	local ctx = QueryContext.new(manager)
	local a, b = manager.type.Integer, manager.type.String
	assert(ctx:include(a, b, function()
		assert(ctx:include(a, b, function() error("active inclusion should short circuit") end))
		-- An inclusion hypothesis must not prove overlap of the same pair.
		assert(not ctx:overlap(a, b, function() return false end))
		return true
	end))
	assert(not ctx:include(a, b, function() return false end), "successful hypotheses must leave scope")
	local ok = pcall(function()
		ctx:include(a, b, function() error("intentional query failure") end)
	end)
	assert(not ok and not ctx:include(a, b, function() return false end))
	assert(ctx:overlap(a, b, function()
		return ctx:overlap(b, a, function() error("overlap is symmetric") end)
	end))
	assert(not ctx:overlap(a, b, function() return false end))
	local function recursive(field)
		local ref = manager:AsyncTypeCom(node)
		local object = manager:buildInterface(node, {next = manager:buildOrNil(node, ref), value = field})
		ref:setTypeAsync(node, function() return object end)
		return object
	end
	local good, same, bad = recursive(a), recursive(a), recursive(b)
	assert(H.equivalent(good, same) and not good:intersectSome(bad))
	assert(not good:includeAll(bad) and H.equivalent(good, same))
	print("query hypotheses are scoped, exception safe and relation specific")
end)
