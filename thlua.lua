tprint=function()
end
ttprint=function()
end

local CodeEnv = require "thlua.code.CodeEnv"

local thlua = {}

thlua.path = package.path:gsub("[.]lua", ".thlua")

function thlua.load(chunk, chunkName, ...)
	local codeEnv = CodeEnv.new(chunk, chunkName)
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

function thlua.createRuntimeByFile(vMainFileName)
	local envDict = {}
	local thloader = {}
	function thloader:thluaSearch(vPath)
		local thluaPath = package.path:gsub("[.]lua", ".thlua")
		local fileName, err1 = package.searchpath(vPath, thluaPath)
		if not fileName then
			return false, err1
		end
		return true, fileName
	end
	function thloader:thluaParseFile(vFileName)
		local nCodeEnv = envDict[vFileName]
		if not nCodeEnv then
			local file, err = io.open(vFileName, "r")
			if not file then
				error(err)
			end
			local nContent = file:read("*a")
			file:close()
			nCodeEnv = CodeEnv.new(nContent, vFileName, -1)
			nCodeEnv:loadTyping()
			envDict[vFileName] = nCodeEnv
		end
		local ok, err = nCodeEnv:checkOkay()
		if not ok then
			error(err)
		end
		return nCodeEnv
	end
	local Runtime = require "thlua.runtime.Runtime"
	return Runtime.new(thloader, vMainFileName)
end

return thlua
