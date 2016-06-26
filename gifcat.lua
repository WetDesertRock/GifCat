-- Copyright (c) 2016 WetDesertRock
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.


-- Where can we find the gif.so file?
local GIFLIB = "gifcatlib"

-- Where is this file?
local FILE = (...)

if love.arg then -- Are we in the main thread?

  --Todo:
  -- Ring buffer so you can save the last x number of seconds
  -- Canvas watching? (ie: only calling :update and :close)
  -- ThreadPool
  local _ = {}

  _.init = function()
    _.thread = love.thread.newThread(FILE:gsub("%.","/")..".lua")
    _.channel = love.thread.getChannel("gif_imagedata")
    _.thread:start()
    _.gifs = {}
  end

  _.close = function()
    _.channel:push({"quit"})
    _.thread:wait()
  end

  _.update = function(dt)
    for i=#_.gifs,1,-1 do
      local gif = _.gifs[i]
      gif:update(dt)
      if gif.done then
        table.remove(_.gifs,i)
      end
    end
  end

  _.active = function(gif)
    return #_.gifs > 0
  end

  --More or less private, the GIF takes care of this itself
  _.add = function(gif)
    table.insert(_.gifs,gif)
  end

  local GifWriter = {}
  GifWriter.__index = GifWriter

  function GifWriter.new(fpath, width, height, fps, isrepeat, palettesize)
    local self = setmetatable({}, GifWriter)
    self.fpath = fpath
    self.recvchannel = love.thread.getChannel("gif_recv_"..self.fpath)
    self:setFPS(fps)
    self.width,self.height = width or love.graphics.getWidth(),height or love.graphics.getHeight()
    self.canvas = nil -- Defer the creation of this until we are absolutly sure we need it.
    self.framecount = 0
    self.writtenframes = 0

    self.updatecallback = nil
    self.finishcallback = nil

    _.channel:push({"newgif",self.fpath,self.width,self.height,isrepeat,self.delay,palettesize})
    _.add(self)

    return self
  end

  function GifWriter:update(dt)
    local msg = self.recvchannel:pop( )
    while msg do
      if msg == "framewritten" then
        self.writtenframes = self.writtenframes + 1
        if self.updatecallback then
          self.updatecallback(self, self.writtenframes, self.framecount)
        end
      elseif msg == "finished" then
        self.done = true
        if self.finishcallback then
          self.finishcallback(self, self.framecount)
        end
      end

      msg = self.recvchannel:pop( )
    end
  end

  function GifWriter:setFPS(fps)
    self.delay = 100/(fps or love.timer.getFPS())
    return self
  end

  function GifWriter:progress()
    return self.writtenframes/self.framecount
  end

  function GifWriter:initCanvas()
    if not self.canvas then
      self.canvas = love.graphics.newCanvas(self.width,self.height)
    end
    return self
  end

  function GifWriter:frame(image,dt,mode)
    self.framecount = self.framecount+1

    -- Deal with imagedata (convert it to an image)
    if image:type() == "ImageData" then
      image = love.graphics.newImage(image)
    end

    -- Deal with out of size canvases
    local mode = mode or "scale"
    local finalcanvas = nil

    -- if image:type() is an Image than we need to draw it to the canvas anyways for its imagedata
    if (image:getWidth() ~= self.width or image:getHeight() ~= self.height) or image:type() == "Image" then
      if not self.canvas then
        self:initCanvas()
      end
      self.canvas:renderTo(function()
        love.graphics.clear()

        local sx,sy = 1,1
        if mode == "scale" then
          sx,sy = self.width/image:getWidth(),self.height/image:getHeight()
        end
        love.graphics.draw(image,0,0,0,sx,sy)
        finalcanvas = self.canvas
      end)
    else
      finalcanvas = image
    end

    -- Find out our delay
    local delay = self.delay
    if dt then
      delay = dt*100
    end

    -- Finally send the data
    _.channel:push({"frame",self.fpath,finalcanvas:newImageData(),math.floor(delay+0.5)})
  end

  function GifWriter:onUpdate(fn)
    self.updatecallback = fn
    return self
  end

  function GifWriter:onFinish(fn)
    self.finishcallback = fn
    return self
  end

  function GifWriter:close()
    _.channel:push({"close",self.fpath})
    return self
  end

  function _.newGif(...)
    return GifWriter.new(...)
  end
  -- _.GifWriter = GifWriter

  return _

else
  local gif = require(GIFLIB)
  require("love.image")
  require("love.filesystem")
  local channel = love.thread.getChannel("gif_imagedata")

  local gifs = {}

  while true do
    local data = channel:demand()
    if type(data) == "table" then
      if data[1] == "newgif" then
        -- Create the file then close it. Just to make sure the app data directory exists
        local file = love.filesystem.newFile(data[2], 'w')
        file:close()
        local fpath = love.filesystem.getSaveDirectory( ).."/"..data[2]
        --                      fname  width   height  repeat  delay  palette size
        gifs[data[2]] = gif.new(fpath,data[3],data[4],data[5],data[6],data[7])
      elseif data[1] == "frame" then -- Add frame
        gifs[data[2]]:frame(data[3]:getString(),data[4])
        love.thread.getChannel("gif_recv_"..data[2]):push("framewritten")
      elseif data[1] == "close" then -- Close file
        gifs[data[2]]:close()
        love.thread.getChannel("gif_recv_"..data[2]):push("finished")
        gifs[data[2]] = nil
      elseif data[1] == "quit" then
        for _,gif in pairs(gifs) do
          gif:close()
        end
        return
      end
    end
  end
end
