tprint=function()
end
ttprint=function()
end

local CodeEnv = require "thlua.code.CodeEnv"

local boot = {}

boot.path = package.path:gsub("[.]lua", ".thlua")

function boot.load(chunk, chunkName, ...)
	local codeEnv = CodeEnv.new(chunk, chunkName)
	local luaCode = codeEnv:genLuaCode()
	local f, err3 = load(luaCode, chunkName, ...)
	if not f then
		error(err3)
	end
	return f
end

function boot.searcher(name)
	local fileName, err1 = package.searchpath(name, boot.path)
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
	return boot.load(thluaCode, name)
end

table.insert(package.searchers, boot.searcher)

local Runtime = require "thlua.runtime.Runtime"
local thloader = require "thlua.code.thloader"

function boot.createRuntimeByFile(vMainFileName)
	return Runtime.new(thloader, vMainFileName)
end

return boot
