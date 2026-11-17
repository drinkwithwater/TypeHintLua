local H = require "tostringGoal.support"
H.withTypes(function(manager)
	local leftValue, rightValue = 1.0, 1.0 + 2.0^-52
	local left, right = manager:Literal(leftValue), manager:Literal(rightValue)
	assert(left ~= right and left:getLiteral() ~= right:getLiteral())
	print("precise-values", string.format("%.17g", leftValue), string.format("%.17g", rightValue))
	H.show("float-left", tostring(left))
	H.show("float-right", tostring(right))
	assert(tostring(left) ~= tostring(right), "T03: distinct adjacent float literals must remain distinguishable")
end)
