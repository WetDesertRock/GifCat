package = "gifcat"
version = "scm-1"
source = {
   url = "git://github.com/WetDesertRock/GifCat.git"
}
description = {
   summary = "A simple module for saving gifs from LOVE 0.10.x.",
   detailed = "A simple module for saving gifs from LOVE 0.10.x.",
   homepage = "https://github.com/WetDesertRock/GifCat",
   license = "MIT"
}
dependencies = {
   "lua ~> 5.1",
   "love ~> 0.10"
}
build = {
   type = "builtin",
   modules = {
      gifcatlib = { sources = "src/lua_bindings.c" },
	  gifcat = "gifcat.lua"
   }
}
