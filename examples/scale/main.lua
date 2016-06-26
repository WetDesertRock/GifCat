local things = {}
local center = {love.graphics.getWidth()/2,love.graphics.getHeight()/2}
local timer = 0
local recording = false

local gifcat = require("gifcat")
local curgif = nil
local gifs = {}

function love.load()
  local count = 300
  for i=1,count do
    local x = math.cos(math.pi*2*i/count)
    local y = math.sin(math.pi*2*i/count)
    table.insert(things,{x=x,y=y, radius=100,i=i})
  end

  gifcat.init()
end

function love.update(dt)
  timer = timer + dt
  gifcat.update(dt)
end

function love.quit()
  gifcat.close()
end
function love.threaderror(thread, errorstr)
  print("Thread error!\n"..errorstr)
end

function love.keypressed(key, touch, isrepeat)
  if isrepeat then
    return
  end

  if key == "escape" then
    love.event.quit()
  elseif key == "f9" then
    -- By specifying a specific size (even if it is smaller), gifcat will scale
    --   it down to size.
    curgif = gifcat.newGif(os.time()..".gif",400,300)
    curgif:onUpdate(function(gif,curframes,totalframes)
      print(string.format("Progress: %f (%d/%d)",gif:progress()*10,curframes,totalframes))
    end)
    curgif:onFinish(function(gif,totalframes)
      print(totalframes.." frames written")
    end)
    table.insert(gifs,curgif)
  end
end
function love.keyreleased(key)
  if key == "f9" then
    curgif:close()
    curgif = nil
  end
end

function love.draw()
  love.graphics.setPointSize(2)
  local lx,ly = nil,nil
  for i=1,#things do
    local point = things[i]
    local radius = point.radius + math.sin(timer+i)*100
    local x,y = point.x*radius, point.y*radius
    love.graphics.points(x+center[1],y+center[2])

    lx,ly = x,y
  end

  if curgif then
    curgif:frame(love.graphics.newScreenshot())

    love.graphics.setColor(255,0,0)
    love.graphics.circle("fill",love.graphics.getWidth()-10,10,10)
  end

  love.graphics.setColor(255,255,255)
  love.graphics.print("Current FPS: "..tostring(love.timer.getFPS( )), 0, 0)
end
