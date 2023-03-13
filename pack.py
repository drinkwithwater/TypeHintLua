
import os
import re
import pyskynet
import pyskynet.foreign as foreign

pyskynet.start()
compileService = pyskynet.scriptservice("""
local foreign = require "pyskynet.foreign"
local pyskynet = require "pyskynet"
local ParseEnv = require "thlua.code.ParseEnv"
foreign.dispatch("compile", function(content)
    local env = ParseEnv.new(content, "default")
    return env:genLuaCode()
end)
pyskynet.start(function()
end)
""")

HEAD = """
local loaded, packages, require_ = {}, {}, require

local function require(path)
    if loaded[path] then
        return loaded[path]
    elseif packages[path] then
        loaded[path] = packages[path](path)
        return loaded[path]
    else
        return require_(path)
    end
end
"""

TEMPLATE = """
--{path} begin ==========(
do local _ENV = _ENV
packages['{path}'] = function (...)
{content}
end end
--{path} end ==========)
"""

TAIL = """
return require "thlua.boot"
"""

class Packer(object):
    def __init__(self):
        self.pathContentList = []

    def scanRoot(self):
        self.scan("./thlua")

    def scan(self, directory):
        prefixToSuffix = {}
        for fileName in os.listdir(directory):
            fullFileName = os.path.join(directory, fileName)
            if os.path.isdir(fullFileName):
                self.scan(fullFileName)
                continue
            thluaMatchs = re.findall("^([^.]+)[.]thlua$", fileName)
            luaMatchs = re.findall("^([^.]+)[.]lua$", fileName)
            if luaMatchs:
                prefixToSuffix[luaMatchs[0]] = "lua"
            if thluaMatchs:
                if not (thluaMatchs[0] in prefixToSuffix):
                    prefixToSuffix[thluaMatchs[0]] = "thlua"
        for prefix, suffix in prefixToSuffix.items():
            fullFileName = os.path.join(directory, prefix+"."+suffix)
            with open(fullFileName) as fi:
                content = fi.read()
            path = os.path.join(directory, prefix).replace("./", "").replace("/", ".")
            if suffix == "thlua":
                content, = foreign.call(compileService, "compile", content)
                content = content.decode("utf-8")
            self.pathContentList.append((path, content))

    def build(self):
        l = [HEAD]
        self.pathContentList.sort()
        for path, content in self.pathContentList:
            l.append(TEMPLATE.format(path=path,content=content))
        l.append(TAIL)
        with open("thlua.lua", "w") as fo:
            content = "".join(l)
            fo.write(content)

    def buildForVSC(self):
        l = [HEAD]
        self.pathContentList.sort()
        for path, content in self.pathContentList:
            l.append(TEMPLATE.format(path=path,content=content))
        l.append("""
            local boot = require "thlua.boot"
            local f = io.open("d:/log.txt", "w")
            boot.runServer(f)
        """)
        with open("3rd/vscode-lsp/server/thlua.lua", "w") as fo:
            content = "".join(l)
            fo.write(content)

packer = Packer()
packer.scanRoot()
packer.build()
packer.buildForVSC()
