tprint=function()
end
ttprint=function()
end

local ParseEnv = require "thlua.code.ParseEnv"

local boot = {}

boot.path = ""

function boot.compile(chunk, chunkName)
	return ParseEnv.compile(chunk, chunkName)
end

function boot.load(chunk, chunkName, ...)
	local luaCode, err = boot.compile(chunk, chunkName)
	if not luaCode then
		return false, err
	end
	local f, err = load(luaCode, chunkName, ...)
	if not f then
		return false, err
	end
	return f
end

function boot.searcher(name)
	local fileName, err1 = package.searchpath(name, boot.path)
	if not fileName then
		return err1
	end
	local file, err2 = io.open(fileName, "r")
	if not file then
		return err2
	end
	local thluaCode = file:read("*a")
	file:close()
	return assert(boot.load(thluaCode, fileName))
end

local patch = false

-- patch for load thlua code in lua
function boot.patch()
	if not patch then
		boot.path = package.path:gsub("[.]lua", ".thlua")
		table.insert(package.searchers, boot.searcher)
		patch = true
	end
end

-- start check from a main file
function boot.runCheck(vMainFileName)
	boot.patch()
	local DiagnosticRuntime = require "thlua.runtime.DiagnosticRuntime"
	local nRuntime = DiagnosticRuntime.new()
	assert(nRuntime:pmain(vMainFileName))
end

-- make play groud
function boot.makePlayGround()
	local PlayGround = require "thlua.server.PlayGround"
	local playground = PlayGround.new()
	return function(a, b)
		return playground:update(a, b)
	end
end

-- run language server
function boot.runServer(vMode)
	boot.patch()
	local FastServer = require "thlua.server.FastServer"
	local SlowServer = require "thlua.server.SlowServer"
	local server
	if vMode == "fast" then
		server = FastServer.new()
	else
		server = SlowServer.new()
	end

	print=function(...)
		--[[client:notify("window/logMessage", {
			message = client:packToString(3, ...),
			type = 3,
		})]]
	end

	server:mainLoop()
end

return boot
