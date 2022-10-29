#!/usr/bin/python2.7

import os, sys, platform, string


opt = {
    "compiler"  : "gcc",
    "source"    : "src/lua_bindings.c",
    "link"      : "",
    "include"   : "",
    "flags"     : "-O2 -pedantic -Wall -Wextra",
    "outfile"   : "-o gifcatlib.so",
    "define"    : "",
}

template = "$compiler $outfile $source $include $link $flags $define"

if platform.system() == "Windows":
    opt["flags"] += " -fpic -shared"
    opt["link"] += " -lws2_32 -llua51 -Llib" # 
    opt["outfile"] = "-o gifcatlib.dll"

elif platform.system() == "Darwin":
    opt["flags"] += " -bundle -undefined dynamic_lookup"

else: # Assume Linux, BSD etc.
    opt["flags"] += " -fpic -shared"


print(string.Template(template).substitute(opt))
os.system(string.Template(template).substitute(opt))
