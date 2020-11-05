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

function love.keypressed(key, touch, isrepeat)

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
  for i=1,20 do
    local width = 1.3 + 0.5*math.sin(love.timer.getTime()*13 + (i/20*math.pi*2))
    local a = (i/20) * (math.pi*2) + love.timer.getTime()
    local a2 = ((i+10)/20) * (math.pi*2) - love.timer.getTime()*2

    local r1 = 50 + math.cos(love.timer.getTime()*0.7 + i)*10
    local r2 = 50 + math.sin(love.timer.getTime()*4 + i)*10

    local p1x,p1y = math.sin(a)*r1+50,math.cos(a)*r1+50
    local p2x,p2y = math.sin(a2)*r2+50,math.cos(a2)*r2+50

    local b = 235 + 20*math.cos(love.timer.getTime()*11 + (i/20*math.pi*2))
    love.graphics.setColor(255,255,b,160)

    love.graphics.setLineWidth(width)
    love.graphics.line(p1x,p1y, p2x,p2y)
  end


  -- On to the gif specific stuff
  if curgif then
    -- Save a frame to our gif.
    love.graphics.captureScreenshot(function(screenshot) curgif:frame(screenshot) end)

    -- Show a little recording icon in the upper right hand corner. This will
    --   not get shown in the gif because it is displayed after the call to
    --   captureScreenshot()
    love.graphics.setColor(255,0,0)
    love.graphics.circle("fill",love.graphics.getWidth()-10,10,10)
  end

  -- Lets see how our FPS responds
  love.graphics.setColor(255,255,255)
  love.graphics.print("Current FPS: "..tostring(love.timer.getFPS( )), 0, 0)
end
