# Gifcat

A simple module for saving gifs from LOVE 0.10.x.


## Installation
Build the library by running:
```bash
$ python build.py
```

Move gifcatlib.so and gifcat.lua to the base of your project. Then, just
require the lua file:

```lua
gifcat = require("gifcat")
```

##Basic Usage:

You will need to call gifcat.init() inside love.load(). Call

```lua
local gifcat = require("gifcat")
local curgif = nil

function love.load()
  love.window.setMode( 100, 100 )

  -- Init gifcat, this is important as it launches the threads and sets
  --   everything up.
  gifcat.init()
end

function love.update(dt)
  -- This isn't necessary, however it is recommended.
  gifcat.update(dt)
end

-- Important, otherwise it will hang when trying to quit.
function love.quit()
  gifcat.close()
end

-- Important to make sure it doesn't fail silently.
function love.threaderror(thread, errorstr)
  print("Thread error!\n"..errorstr)
end

function love.keypressed(key, isrepeat)
  if isrepeat then
    return
  end

  curgif = gifcat.newGif(os.time()..".gif",100,100)

  -- Optional method to just print out the progress of the gif
  curgif:onUpdate(function(gif,curframes,totalframes)
    print(string.format("Progress: %.2f%% (%d/%d)",gif:progress()*10,curframes,totalframes))
  end)
  curgif:onFinish(function(gif,totalframes)
    print(totalframes.." frames written")
  end)
end

function love.keyreleased(key)
  -- Stop writing to the gif. This finalizes the file and closes it.
  curgif:close()

  -- Set to nil so our program knows we aren't writing a gif.
  curgif = nil
end

function love.draw()
  -- Display our game here.
  love.graphics.print("GIFCAT",50,50,love.timer.getTime()*3)

  if curgif then
    -- Save a frame to our gif.
    curgif:frame(love.graphics.newScreenshot())

    -- Show a little recording icon in the upper right hand corner. This will
    --   not get shown in the gif because it is displayed after the call to
    --   newScreenshot()
    love.graphics.setColor(255,0,0)
    love.graphics.circle("fill",love.graphics.getWidth()-10,10,10)
  end

  love.graphics.setColor(255,255,255)
  love.graphics.print("Current FPS: "..tostring(love.timer.getFPS( )), 0, 0)
end
```

##Advanced Usage:

###Placing the dynamic library in a different location.
If you place the library somewhere else than the root of your project, you will
need to change the `GIFLIB` variable at the top of `gifcat.lua`.

###Giving gifcat irregular image sizes.
If you want to give gifcat images that aren't the same size as the gif, it will
automatically recreate the image on an internal canvas that it will use.
By default this will leave it unmodified and just cut off excess area. You can
make it scale by changing the mode to "scale" in `GifWriter:frame`.


## Function Reference

### gifcat.init()
Inits the library. This will start the thread and get everything initialized.

### gifcat.close()
This will close all open gifs as well as shut down the threads in preperation for
quitting.

### gifcat.update(dt)
Update all active gif objects. This is where they check and update their progress
indications.

### gifcat.active()
Will return true if there are any gifs being written.

### gifcat.newGif(fpath, width, height, [fps, [isrepeat, [palettesize]]])
Creates a new GifWriter. This is how you start writing a new gif. `fps` will
default to the current fps (as returned by `love.timer.getFPS()`). `isrepeat`
will default to true (setting it so the gif will repeat), `palettesize` will
default to 32.

### GifWriter:frame(image, [dt, [mode]])
Write a frame to the gif, `image` can be either an ImageData, Image, or Canvas.
Use `dt` to set a custom delay for this specific frame. Overrides the default fps
value. `mode` is how GifWriter will deal with an incorrectly sized `image`. Set
to `scale` to force it to scale the image.

### GifWriter:close()
Will close the gif and allow it to finish writing.

### GifWriter:onUpdate(fn)
Sets a callback `fn` to be called when a new frame is written. This function is
chainable.

### GifWriter:onFinish(fn)
Sets a callback `fn` to be called when the gif was written completely and closed
properly. This function is chainable.

### GifWriter:setFPS(fps)
Will set the `fps` for the subsequent frames being written. If `fps` is nil it
will set the `fps` to the current fps as returned by `love.timer.getFPS()`.

### GifWriter:progress()
Returns the current progress of the gif as a number between 0 and 1.

### GifWriter:initCanvas()
Forces the GifWriter to create a canvas for its internal use.


## License

This library is free software; you can redistribute it and/or modify it under
the terms of the MIT license. See [LICENSE](LICENSE) for details.
