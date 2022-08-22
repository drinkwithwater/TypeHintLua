tprint=function()
end
ttprint=function()
end

local CodeEnv = require "thlua.code.CodeEnv"

local function thluaSearcher(name)
	local ok, content, fileName = CodeEnv.thluaSearchContent(name)
	if not ok then
		return content
	end
	local env = CodeEnv.new(content, fileName, name)
	local luaCode = env:genLuaCode()
	local f, err3 = load(luaCode, name)
	return f or err3
end

local searchers = package.searchers
table.insert(searchers, thluaSearcher)

local Runtime = require "thlua.runtime.Runtime"


local thlua = Runtime.new()
thlua:init()

return thlua
