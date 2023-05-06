local ParseEnv = require "thlua.code.ParseEnv"

local boot = {}

boot.path = ""

boot.compile = ParseEnv.compile

boot.load = ParseEnv.load

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
function boot.runServer(vMode, vGlobalPathOrNil)
	boot.patch()
	local FastServer = require "thlua.server.FastServer"
	local SlowServer = require "thlua.server.SlowServer"
	local BothServer = require "thlua.server.BothServer"
	local server
	if vMode == "fast" then
		server = FastServer.new(vGlobalPathOrNil)
	elseif vMode == "slow" then
		server = SlowServer.new(vGlobalPathOrNil)
	else
		server = BothServer.new(vGlobalPathOrNil)
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
