local boot = require "thlua.code.ParseEnv"

-- start check from a main file
function boot.runCheck(vMainFileName, vUseProfile)
	boot.patch()
	local CodeRuntime = require "thlua.runtime.CodeRuntime"
	local nRuntime = CodeRuntime.new()
	local t1 = os.clock()
	--local nRuntime = CompletionRuntime.new()
	nRuntime:promiseMain(vMainFileName, vUseProfile):next(function(_)
		local t2 = os.clock()
		print(t2-t1)
		local count1 = 0
		for k,v in pairs(nRuntime:getTypeManager()._hashToTypeSet) do
			count1 = count1 + 1
		end
		print(count1)
	end):forget()
	local uv = require "luv"
	uv.run()
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
function boot.runServer(vGlobalPathOrNil)
	boot.patch()
	local LangServer = require "thlua.server.LangServer"
	local server = LangServer.new(vGlobalPathOrNil)

	print=function(...)
		--[[client:notify("window/logMessage", {
			message = client:packToString(3, ...),
			type = 3,
		})]]
	end

	server:mainLoop()
end

return boot
