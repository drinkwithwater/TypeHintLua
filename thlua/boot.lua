local boot = require "thlua.code.ParseEnv"

-- start check from a main file
function boot.runCheck(vMainFileName, vUseProfile)
	boot.patch()
	local DiagnosticRuntime = require "thlua.runtime.DiagnosticRuntime"
	local nRuntime = DiagnosticRuntime.new()
	assert(nRuntime:pmain(vMainFileName, vUseProfile))
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
