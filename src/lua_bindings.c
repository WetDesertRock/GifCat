/*
 * Copyright (c) 2016 WetDesertRock
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

#include <stdlib.h>
#include <string.h>

#include "lib/lua5.1/lua.h"
#include "lib/lua5.1/lauxlib.h"
#include "lib/lua5.1/lualib.h"
#include "lib/lextlib_lua52.h"

#include "jo_gif.c"

#define GIF_CLASS_NAME "jo_gif"

typedef struct {
  jo_gif_t gif;
  short delay; // Default delay for the gif
  int valid; // Indicates if the gif has been closed already.
} Gif;

#define checkvalid() if (!self->valid) return luaL_error(L, "Trying to use a invalid gif file.")

Gif *gif_new(lua_State *L) {
  Gif *self = lua_newuserdata(L, sizeof(*self));
  luaL_setmetatable(L, GIF_CLASS_NAME);
  memset(self, 0, sizeof(*self));
  return self;
}

static int l_gif_gc(lua_State *L) {
  Gif *self = luaL_checkudata(L, 1, GIF_CLASS_NAME);
  if (self->valid) {
    jo_gif_end(&self->gif);
  }
  return 0;
}
static int l_gif_frame(lua_State *L) {
  Gif *self = luaL_checkudata(L, 1, GIF_CLASS_NAME);
  checkvalid();
  size_t len;
  const char *data = luaL_checklstring(L, 2, &len);
  int delay = luaL_optint(L, 3, self->delay);

  jo_gif_frame(&self->gif, (unsigned char*)data, delay, 0);
  return 0;
}
static int l_gif_close(lua_State *L) {
  Gif *self = luaL_checkudata(L, 1, GIF_CLASS_NAME);
  checkvalid();
  jo_gif_end(&self->gif);
  self->valid = 0;

  return 0;
}

static int l_gif_new( lua_State *L ) {
  const char *name = luaL_checkstring(L, 1);
  int width = luaL_checknumber(L, 2);
  int height = luaL_checknumber(L, 3);
  int repeat = luaL_optint(L, 4, 0);
  int delay = luaL_optint(L, 5, 4);
  int palettesize = luaL_optint(L, 6, 32);
  Gif *self = gif_new(L);
  self->gif = jo_gif_start(name, width, height, repeat, palettesize);
  self->delay = delay;
  self->valid = 1;

  return 1;
}

int luaopen_gifcatlib (lua_State *L) {
  luaL_Reg reglib[] = {
    { "new",    l_gif_new    },
    { NULL, NULL }
  };
  luaL_newlib(L, reglib);

  /* Used for the Gif object. */
  luaL_Reg reg[] = {
    { "__gc",     l_gif_gc       },
    { "frame",    l_gif_frame    },
    { "close",    l_gif_close    },
    { NULL, NULL }
  };
  luaL_newmetatable(L, GIF_CLASS_NAME); //TODO: Do we need to error check this?
  luaL_setfuncs(L, reg, 0);
  lua_pushvalue(L, -1);
  lua_setfield(L, -2, "__index");

  lua_setfield(L, -2, "Gif");
  return 1;
}
