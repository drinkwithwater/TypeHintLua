local H = require "tostringGoal.support"
H.withTypes(function(manager)
	-- Actual quote, backslash, newline and NUL bytes, not fake types.
	local value = "a'b" .. string.char(92) .. "c" .. string.char(10, 0)
	local rendered = tostring(manager:Literal(value))
	H.show("escaped-input", value)
	H.show("literal-display", rendered)
	local chunk = load("return " .. rendered, "display-roundtrip", "t", {Literal=function(v) return v end})
	assert(chunk and chunk() == value and not rendered:find("[%z\r\n]"),
		"T02: string literal display must escape delimiters and control characters")
end)
