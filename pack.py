
import os
import re
import pyskynet
import pyskynet.foreign as foreign

pyskynet.start()
compileService = pyskynet.scriptservice("""
local foreign = require "pyskynet.foreign"
local pyskynet = require "pyskynet"
local ParseEnv = require "thlua.code.ParseEnv"
foreign.dispatch("compile", function(content, filename)
    return ParseEnv.compile(content, filename)
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
                content, = foreign.call(compileService, "compile", content, fullFileName)
                content = content.decode("utf-8")
            self.pathContentList.append((path, content))
        self.pathContentList.sort()

    def build(self):
        l = [HEAD]
        for path, content in self.pathContentList:
            l.append(TEMPLATE.format(path=path,content=content))
        l.append(TAIL)
        with open("thlua.lua", "w") as fo:
            content = "".join(l)
            fo.write(content)
        with open("../pyhello/thlua.lua", "w") as fo:
            content = "".join(l)
            fo.write(content)

    def buildForVSC(self):
        l = [HEAD]
        for path, content in self.pathContentList:
            l.append(TEMPLATE.format(path=path,content=content))
        l.append("""
            local boot = require "thlua.boot"
            -- local f = io.open("d:/log.txt", "w")
            boot.runServer(...)
        """)
        with open("3rd/vscode-lsp/server/thlua.lua", "w") as fo:
            content = "".join(l)
            fo.write(content)
        globalPath = "./thlua/global/"
        for fileName in os.listdir(globalPath):
            with open(globalPath + fileName, "r") as fi:
                lines = fi.readlines()
                lines = lines[1:-1]
            fileName = fileName.replace(".lua", ".d.thlua")
            with open("3rd/vscode-lsp/server/global/" + fileName, "w") as fo:
                fo.write("".join(lines))

    def buildForWeb(self):
        l = ["var THLUA_SCRIPT=(function(){/* ", HEAD]
        for path, content in self.pathContentList:
            l.append(TEMPLATE.format(path=path,content=content))
        l.append("""
            local boot = require "thlua.boot"
            return boot.makePlayGround()
                */}).toString().slice(14,-3)
        """)
        MY_PATH="../../github/drinkwithwater.github.io"
        with open(MY_PATH+"/src/thlua.js", "w") as fo:
            content = "".join(l)
            fo.write(content)
        l = []
        for fileName in os.listdir("examples"):
            singleName = fileName.split(".")[0]
            with open("examples/"+fileName) as fi:
                data = fi.read()
                l.append("'"+singleName+"':(function(){/* "+data+" */}).toString().slice(14, -3)")
        with open(MY_PATH+"/src/examples.js", "w") as fo:
            content = ",".join(l)
            fo.write("var THLUA_EXAMPLES={")
            fo.write(content)
            fo.write("}")

packer = Packer()
packer.scanRoot()
packer.build()
packer.buildForVSC()
packer.buildForWeb()
