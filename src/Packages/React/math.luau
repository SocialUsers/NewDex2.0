-- jsdotlua/math@1.2.7; see THIRD_PARTY_NOTICES.md
return {
["math/clz32"]=function()
return bit32.countlz

end,
["math"]=function()
return {
	clz32 = require(script:WaitForChild('clz32')),
}

end,
}
