tprint=function()
end
ttprint=function()
end

local CodeEnv = require "thlua.code.CodeEnv"

local thlua = {}

thlua.path = package.path:gsub("[.]lua", ".thlua")

function thlua.load(chunk, chunkName, ...)
	local codeEnv = CodeEnv.new(chunk, chunkName, chunkName)
	local luaCode = codeEnv:genLuaCode()
	local f, err3 = load(luaCode, chunkName, ...)
	if not f then
		error(err3)
	end
	return f
end

function thlua.searcher(name)
	local fileName, err1 = package.searchpath(name, thlua.path)
	if not fileName then
		fileName, err1 = package.searchpath(name, package.path)
		if not fileName then
			return err1
		end
	end
	local file, err2 = io.open(fileName, "r")
	if not file then
		return err2
	end
	local thluaCode = file:read("*a")
	file:close()
	return thlua.load(thluaCode, name)
end

table.insert(package.searchers, thlua.searcher)

function thlua.newRuntime()
	local Runtime = require "thlua.runtime.Runtime"
	return Runtime.new()
end

return thlua
