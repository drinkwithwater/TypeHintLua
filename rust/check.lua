local file = ...
-- Keep machine-readable output free from checker debug/profile prints.
print = function(...) io.stderr:write(table.concat((function(...)
    local values = {}
    for i = 1, select('#', ...) do values[i] = tostring(select(i, ...)) end
    return values
end)(...), '\t'), '\n') end
local Runtime = require 'thlua.runtime.CodeRuntime'
local runtime = Runtime.new()
local result = {done = false, items = require('thlua.server.json').array({})}
runtime:promiseMain(file):next(function()
    for _, list in pairs(runtime:getAllDiagnostic()) do
        for _, diagnostic in ipairs(list) do
            local node = diagnostic.node
            result.items[#result.items + 1] = {
                file = node.path or file,
                line = node.l or 1,
                column = node.c or 1,
                severity = diagnostic.severity,
                message = tostring(diagnostic.msg),
            }
        end
    end
    table.sort(result.items, function(a, b)
        if a.file ~= b.file then return a.file < b.file end
        if a.line ~= b.line then return a.line < b.line end
        if a.column ~= b.column then return a.column < b.column end
        if a.severity ~= b.severity then return a.severity < b.severity end
        return a.message < b.message
    end)
    result.done = true
end, function(err)
    result.error = tostring(err)
    result.done = true
end):forget()
return result
