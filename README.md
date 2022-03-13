# Gifcat

A simple module for saving gifs from LOVE 0.11.x.

![1466962294](https://cloud.githubusercontent.com/assets/6189453/16363754/6f27d956-3b89-11e6-9345-71c3d822e1c8.gif)

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

## Basic Usage:

The basic steps goes as follows:  
 * Init the library
 * Update the library each frame
 * Create a gif, and feed it a frame each frame
 * `:close()` the gif once you are done with it.
 * Find the gif in LOVE's application data directory

You can also optionally track the progress using gif:onUpdate() (See
documentation) and examples for usage.

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
    print(string.format("Progress: %.2f%% (%d/%d)",gif:progress()*100,curframes,totalframes))
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
    love.graphics.captureScreenshot(function(screenshot) curgif:frame(screenshot) end)

    -- Show a little recording icon in the upper right hand corner. This will
    --   not get shown in the gif because it is displayed after the call to
    --   captureScreenshot()
    love.graphics.setColor(1,0,0)
    love.graphics.circle("fill",love.graphics.getWidth()-10,10,10)
  end

  love.graphics.setColor(1,1,1)
  love.graphics.print("Current FPS: "..tostring(love.timer.getFPS( )), 0, 0)
end
```

## Advanced Usage:

### Renaming gifcatlib.so
If you want to change the name of gifcatlib.so to gifcatlib.dll (if you are
windows), then you will need to update the `GIFLIB` variable at the top of
`gifcat.lua`.

### Placing the dynamic library in a different location.
If you place the library somewhere else than the root of your project, you will
need to change the `GIFLIB` variable at the top of `gifcat.lua`.

### Giving gifcat irregular image sizes.
If you want to give gifcat images that aren't the same size as the gif, it will
automatically recreate the image on an internal canvas that it will use.  
By default this will scale it. You can make it crop the image by changing the
mode to "crop" in `GifWriter:frame`.


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
the terms of the MIT license. See [LICENSE](https://github.com/WetDesertRock/GifCat/blob/master/gifcat.lua#L1-L19) for details.
