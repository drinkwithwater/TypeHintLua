
import os
import re
import pyskynet
import pyskynet.foreign as foreign

pyskynet.start()
testService = pyskynet.scriptservice("""
local thlua = require "thlua.boot"
thlua.patch()
local TestCase = require "thlua.TestCase"
local foreign = require "pyskynet.foreign"
local pyskynet = require "pyskynet"
foreign.dispatch("test", function(name, content)
    TestCase.go(content, name)
end)
pyskynet.start(function()
end)
""")

class Test(object):
    def __init__(self, path):
        self._fileToContent = {}
        self._path = path

    def scanRoot(self):
        self.scan(self._path)

    def scan(self, directory):
        prefixToSuffix = {}
        for fileName in os.listdir(directory):
            fullFileName = os.path.join(directory, fileName)
            if os.path.isdir(fullFileName):
                self.scan(fullFileName)
                continue
            thluaMatchs = re.findall("^([^.]+)[.]thlua$", fileName)
            if thluaMatchs:
                with open(fullFileName) as fi:
                    content = fi.read()
                    self._fileToContent[fullFileName] = content
    def main(self):
        self.scanRoot()
        for k,v in self._fileToContent.items():
            foreign.call(testService, "test", k, v)

Test("./test/caseClass").main()
Test("./test/caseFunc").main()
Test("./test/caseType").main()
Test("./test/caseTable").main()
Test("./test/caseFlow").main()
