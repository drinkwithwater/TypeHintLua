
let fs = require('fs');
let plist = require('plist');

let src = fs.readFileSync("./Lua.plist.txt", "utf8");

let obj = plist.parse(src)

let dst = JSON.stringify(obj, null, 2)

fs.writeFileSync("./thlua.tmLanguage.json", dst)
