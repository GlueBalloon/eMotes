PRINTALITTLETIME = 1.02

function printALittle(aString)
    if ElapsedTime < PRINTALITTLETIME then
        print(aString)
    end
end

function testNeighborDetection()
    -- Create test motes
    local testMotes = {
        Mote(100, 100),  -- Mote 1
        Mote(105, 100),  -- Mote 2, close to Mote 1
        Mote(300, 300),  -- Mote 3, far from Mote 1 and 2
    }
    
    -- Clear the grid
    grid = {}
    
    -- Update grid with test motes
    for _, mote in ipairs(testMotes) do
        updateGrid(mote)
        --       print("Updated grid for mote at " .. tostring(mote.position))
    end
    
    -- Check grid contents (Debugging)
    for x, col in pairs(grid) do
        for y, cell in pairs(col) do
            --            print("Grid cell [" .. x .. "," .. y .. "] has " .. #cell .. " motes.")
        end
    end
    
    -- Run neighbor detection for each mote
    for _, mote in ipairs(testMotes) do
        local neighbors = checkForNeighbors(mote, grid)
        
        -- Print results for debugging
        print("Mote at " .. tostring(mote.position) .. " has " .. #neighbors .. " neighbors.")
        for _, neighbor in ipairs(neighbors) do
            print(" - Neighbor at " .. tostring(neighbor.position))
        end
    end
end
    
function testWrappedNeighbors()
    -- Setup
    local currentGrid = {}
    local testMotes = {}
    local screenSize = vec2(WIDTH, HEIGHT)
    local testGridSize = 50 -- Assuming this is the grid size used in your main code
    
    -- Create motes near the edges of the screen
    table.insert(testMotes, Mote(1, 1)) -- Top-left corner
    table.insert(testMotes, Mote(screenSize.x - 1, 1)) -- Top-right corner
    table.insert(testMotes, Mote(1, screenSize.y - 1)) -- Bottom-left corner
    table.insert(testMotes, Mote(screenSize.x - 1, screenSize.y - 1)) -- Bottom-right corner
    
    -- Insert a mote near the center for control
    table.insert(testMotes, Mote(screenSize.x / 2, screenSize.y / 2))
    
    -- Run checkForNeighbors on each mote
    for _, mote in ipairs(testMotes) do
        updateGrid(mote) -- Update grid for each mote
        mote.neighbors = checkForNeighbors(mote, currentGrid) -- Check neighbors
    end
    
    -- Check results
    for i, mote in ipairs(testMotes) do
        print("Mote " .. i .. " has " .. #mote.neighbors .. " neighbors.")
    end
end









-- Sensor by jmv38
-- a class to interpret touch events
-- usage:
--[[
-- in setup():
screen = {x=0,y=0,w=WIDTH,h=HEIGHT} 
sensor = Sensor {parent=screen} -- tell the object you want to be listening to touches, here the screen
sensor:onTap( function(event) print("tap") end )
-- in touched(t):
if sensor:touched(t) then return true end

-- available:
sensor:onDrag(callback)
sensor:onTap(callback)
sensor:onLongPress(callback)
sensor:onSwipe(callback)
--]]

Sensor = class()

function Sensor:init(t)
    self.enabled = true     -- listen to touches
    self.extra = t.extra or self.extra or 0   -- enlarge sensitive zone for small dots or fat fingers
    self.touches = {}
    self:setParent(t)
    self.events = {}
    self.doNotInterceptTouches = false
end

function Sensor:setParent(t)
    -- a parent must have x,y,w,h coordinates (CORNER) to use the sensor
    local p = t.parent or self.parent
    if p.x and p.y and p.w and p.h then
        self.parent = p
    else
        error("Sensor parent must have x,y,w,h coordinates")
    end
    -- the coordinates may be in different modes, use the appropriate function
    self.xywhMode = t.xywhMode or self.xywhMode or CORNER
    if self.xywhMode == CENTER then self.xywh = self.xywhCENTER
    elseif self.xywhMode == CORNER then self.xywh = self.xywhCORNER
    elseif self.xywhMode == RADIUS then self.xywh = self.xywhRADIUS
    end
end

local abs = math.abs

-- all gestures register themselves with this function
function Sensor:register(eventName, update, callback)
    table.insert(self.events, {name=eventName, callback=callback, update=update})
end

-- gestures defined below. Note the that, because gestures are managed individually, the
-- code is much more clear than when everything is mixed up. And only the needed computations are done.

-- zoom gesture
function Sensor:onZoom(callback)
    self:register("onZoom", self.zoomUpdate, callback)
end
function Sensor.zoomUpdate(event,self,t)
    event.touches = event.touches or {} -- init table
    local touches = event.touches
    local t1 = touches[1]
    local t2 = touches[2]
    if t.state == BEGAN then -- a new finger has come
        if #touches >= 2 then
            -- this is a 3rd finger, dont use it
        else
            -- register this touch and reset
            table.insert(touches,t)
        end
    elseif t.state == MOVING then 
        -- this is a zoom, if we have exactly 2 touches and t is one of them
        if t1 and t2 and ( t1.id == t.id or t2.id == t.id ) then 
            local tm,ts -- m moving, s static
            if t1.id == t.id 
            then touches[1]=t ; tm = t ; ts = t2
            else touches[2]=t ; tm = t ; ts = t1
            end
            local dw,dh
            if tm.x>ts.x 
            then dw = tm.deltaX
            else dw = - tm.deltaX
            end
            if tm.y>ts.y
            then dh = tm.deltaY
            else dh = - tm.deltaY
            end
            event.dw = dw
            event.dh = dh
            event:callback()
        end
    else
        if t1 and t1.id == t.id then table.remove(touches,1) end
        if t2 and t2.id == t.id then table.remove(touches,2) end
    end
end

-- drag gesture
function Sensor:onDrag(callback)
    self:register("onDrag", self.dragUpdate, callback)
end
function Sensor.dragUpdate(event,self,t)
    if self.touches[t.id] then
        event.touch = t
        event:callback()
    end
end

-- drop gesture
function Sensor:onDrop(callback)
    self:register("onDrop", self.dropUpdate, callback)
end
local droppedObject, droppedTime
function Sensor.dropUpdate(event,self,t)
    if self:inbox(t) and t.state == ENDED then
        if droppedTime ~= ElapsedTime then
            droppedTime = ElapsedTime
            droppedObject = self.parent
            self.doNotInterceptOnce = true
        else
            event.object = droppedObject
            event:callback()
        end
    end
end

-- touched gesture (this is like COUDEA touched function)
function Sensor:onTouched(callback)
    self:register("onTouched", self.touchedUpdate, callback)
end
function Sensor.touchedUpdate(event,self,t)
    if self:inbox(t) then 
        event.touch = t
        event:callback()
    end
end

-- touch gesture
function Sensor:onTouch(callback)
    self:register("onTouch", self.touchUpdate, callback)
end
function Sensor.touchUpdate(event,self,t)
    self.touching = self.touching or {} -- track touches, not only BEGAN
    -- current touch
    if self:inbox(t) then 
        if t.state == BEGAN or t.state == MOVING then 
            self.touching[t.id] = true -- this is touching
        else
            self.touching[t.id] = nil -- this is not
        end
    else
        self.touching[t.id] = nil 
    end
    -- final state
    local state1 = false -- one touch is enough to be touched
    for i,t in pairs(self.touching) do state1= true ; break end
    --if state has changed, send callback
    if state1 ~= event.state then
        event.state = state1
        event.touch = t
        event:callback()
    end
end

-- tap gesture
function Sensor:onTap(callback)
    self:register("onTap", self.tapUpdate, callback)
end
function Sensor.tapUpdate(event,self,t)
    if self.touches[t.id] then -- the touch must have started on me
        if t.state == BEGAN then
            event.totalMove = 0
            event.t0 = ElapsedTime
        elseif t.state == MOVING then
            -- integrate finger movement
            event.totalMove = event.totalMove + abs(t.deltaX) + abs(t.deltaY)
        elseif t.state == ENDED 
        and event.totalMove < 10  -- the finger should not have moved too much ...
        and (ElapsedTime-event.t0) < 0.5 then -- and delay should not be too long
            event:callback()
        end
    end
end

-- long press gesture
function Sensor:onLongPress(callback)
    self:register("onLongPress", self.longPressUpdate, callback)
end
function Sensor.longPressUpdate(event,self,t)
    local tmin = 1
    if self.touches[t.id] then -- the touch must have started on me
        if t.state == BEGAN then
            event.totalMove = 0
            event.cancel = false
            event.id = t.id
            event.tween = tween.delay(tmin,function()
                event.tween = nil
                if event.totalMove > 10 or event.id ~= t.id then  event.cancel = true end
                if event.cancel then return end
                event:callback()
            end)
        elseif t.state == MOVING and event.id == t.id then
            -- integrate finger movement
            event.totalMove = event.totalMove + abs(t.deltaX) + abs(t.deltaY)
        elseif (t.state == ENDED or t.state == CANCELLED) and event.id == t.id then
            event.cancel = true
            if event.tween then tween.stop(event.tween) end
        end
    end
end

-- swipe gesture
function Sensor:onSwipe(callback)
    self:register("onSwipe", self.swipeUpdate, callback)
end
function Sensor.swipeUpdate(event,self,t)
    if self.touches[t.id] then -- the touch must have started on me
        if t.state == BEGAN then
            event.dx = 0
            event.dy = 0
            event.t0 = ElapsedTime
        elseif t.state == MOVING then
            -- track net finger movement
            event.dx = event.dx + t.deltaX
            event.dy = event.dy + t.deltaY
        elseif t.state == ENDED 
        and (ElapsedTime-event.t0) < 1 then -- delay should not be too long
            -- and the finger should have moved enough:
            local minMove = 70
            if abs(event.dx) < minMove  then event.dx = 0 end
            if abs(event.dy) < minMove  then event.dy = 0 end
            if event.dx ~= 0 or event.dy ~= 0 then
                event:callback() -- use event.dx and .dy to know the swipe direction
            end
        end
    end
end

function Sensor:touched(t)
    if not self.enabled then return end
    if t.state == BEGAN and self:inbox(t) then
        self.touches[t.id] = true
    end
    for i,event in ipairs(self.events) do 
        event:update(self,t) -- only registered events are computed
    end
    local intercepted = self.touches[t.id]
    if self.doNotInterceptOnce then
        intercepted = false
        self.doNotInterceptOnce = false
    end
    if t.state == ENDED or t.state == CANCELLED then
        self.touches[t.id] = nil
    end
    -- return true when touched (or concerned)
    if self.doNotInterceptTouches then intercepted = false end
    return intercepted 
end

-- functions to get x, y, w, h in different coordinates systems
function Sensor:xywhCORNER()
    local p = self.parent
    local wr, hr = p.w/2.0, p.h/2.0
    local xr, yr = p.x + wr, p.y + hr
    return xr,yr,wr,hr
end
function Sensor:xywhCENTER()
    local p = self.parent
    return p.x, p.y, p.w/2, p.h/2
end
function Sensor:xywhRADIUS()
    local p = self.parent
    return p.x, p.y, p.w, p.h
end

-- check if the box is touched
function Sensor:inbox(t)
    local x,y,w,h = self:xywh()
    return abs(t.x-x)<(w+self.extra) and abs(t.y-y)<(h+self.extra)
end

