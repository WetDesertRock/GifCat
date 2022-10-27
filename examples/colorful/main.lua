local gifcat = require("gifcat")
local curgif = nil
local frameCount = 0

function love.load()
  love.window.setMode( 200, 200 )

  -- Init gifcat, this is important as it launches the threads and sets
  --   everything up.
  gifcat.init()
  curgif = gifcat.newGif(os.time()..".gif",200,200, 30, 1, 255)
  
  curgif:onUpdate(function(gif,curframes,totalframes)
    print(string.format("Progress: %.2f%% (%d/%d)",gif:progress()*100,curframes,totalframes))
  end)
  curgif:onFinish(function(gif,totalframes)
    print(totalframes.." frames written")
  end)
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

function love.draw()
  local hOff =love.timer.getTime() * 0.6
  local yHOff = math.cos(love.timer.getTime() * 0.45)

  for _x=0,14 do
    for _y=0,14 do
      local x = love.graphics.getWidth() / 14 * _x
      local y = love.graphics.getHeight() / 14 * _y
      local xpercent = x / love.graphics.getWidth()
      local ypercent = y / love.graphics.getHeight()
      local h = ((xpercent*ypercent) * 0.6 + hOff) % 1
      local s = ypercent * 0.4 + 0.4
      local l = xpercent * 0.3 + 0.5

      love.graphics.setColor(HSL(h,s,l,0.7))
      love.graphics.circle("fill", x, y, 10)
    end
  end

  if frameCount < 120 then
    love.graphics.captureScreenshot(function(screenshot) curgif:frame(screenshot) end)
  elseif frameCount == 120 then
    curgif:close()
  end
  frameCount = frameCount + 1
end

-- Taken from https://love2d.org/wiki/HSL_color
function HSL(h, s, l, a)
  if s<=0 then return l,l,l,a end
  h, s, l = h*6, s, l
  local c = (1-math.abs(2*l-1))*s
  local x = (1-math.abs(h%2-1))*c
  local m,r,g,b = (l-.5*c), 0,0,0
  if h < 1     then r,g,b = c,x,0
  elseif h < 2 then r,g,b = x,c,0
  elseif h < 3 then r,g,b = 0,c,x
  elseif h < 4 then r,g,b = 0,x,c
  elseif h < 5 then r,g,b = x,0,c
  else              r,g,b = c,0,x
  end return r+m, g+m, b+m, a
end