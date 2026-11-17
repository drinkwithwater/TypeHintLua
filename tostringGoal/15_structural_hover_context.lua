local H = require "tostringGoal.support"
local source = H.fixture("named_struct_hover.thlua")
local runtime = H.analyze(source)
local env = assert(runtime:getCodeEnv("[test]"))
local position = assert(source:find("print(customer)", 1, true)) + #"print("
local ident = assert(env:searchIdent(position))
local block, text = runtime:getStackManager():hoverNode(ident)
assert(block and type(text) == "string" and #text > 0, "hover business query failed")
H.show("actual-hover-business-text", text)
assert(text:find("Customer", 1, true) or text:find("customerId", 1, true),
	"T15: structural hover should expose an alias or readable fields, not only its source location")
