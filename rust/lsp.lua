local global = ...
local LangServer = require 'thlua.server.LangServer'
local server = LangServer.new(global)
server:setRootPath(require('path').cwd())
if not global then
    -- Use the same embedded standard declarations as the command-line checker.
    -- --global explicitly opts into the legacy on-disk declaration directory.
    local makeStageApi = server.makeStageApi
    function server:makeStageApi()
        local stage = makeStageApi(self)
        stage.parseGlobal = function(name)
            local uri = 'thlua://global/' .. name .. '.d.thlua'
            local state = self._provider:attachFileState(uri)
            state:syncContent(require('thlua.global.' .. name), 0)
            return state:checkLatestEnv(), uri
        end
        return stage
    end
end
return server
