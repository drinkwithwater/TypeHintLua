tprint=function()
end
ttprint=function()
end

local ParseEnv = require "thlua.code.ParseEnv"

local boot = {}

boot.path = package.path:gsub("[.]lua", ".thlua")

function boot.compile(chunk, chunkName)
	local parser = ParseEnv.new(chunk, chunkName or "[anonymous script]")
	return parser:genLuaCode()
end

function boot.load(chunk, chunkName, ...)
	local luaCode = boot.compile(chunk, chunkName)
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

local patch = false

function boot.patch()
	if not patch then
		table.insert(package.searchers, boot.searcher)
		patch = true
	end
end

-- start check from a main file
function boot.runCheck(vMainFileName)
	boot.patch()
	local Runtime = require "thlua.runtime.Runtime"
	local thloader = require "thlua.code.thloader"
	local nRuntime = Runtime.new(thloader, vMainFileName)
	assert(nRuntime:main())
end

-- run language server
function boot.runServer(vMode)
	boot.patch()
	local Client = require "thlua.server.Client"
	local client = Client.new(vMode)

	print=function(...)
		--[[client:notify("window/logMessage", {
			message = client:packToString(3, ...),
			type = 3,
		})]]
	end

	client:mainLoop()
end

return boot
