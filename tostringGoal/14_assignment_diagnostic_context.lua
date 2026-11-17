local H = require "tostringGoal.support"
local runtime = H.analyze(H.fixture("assignment_mismatch.thlua"), true)
local found = {}
for _, list in pairs(runtime:getAllDiagnostic()) do
	for _, diagnostic in ipairs(list) do
		if diagnostic.severity == 1 then
			assert(diagnostic.node.path == "[test]" and diagnostic.node.l == 1)
			assert(diagnostic.msg:find("type not match", 1, true))
			found[#found+1] = diagnostic.msg
			H.show("assignment-diagnostic", diagnostic.msg)
		end
	end
end
assert(#found == 1, "expected exactly one deliberate assignment mismatch")
assert(found[1]:find("Integer", 1, true) and (found[1]:find("String", 1, true) or found[1]:find("text", 1, true)),
	"T14: type mismatch diagnostics should identify expected and actual types")
