-- Test Script for ZoomScroller:doubleTapCallback

-- Assume ZoomScroller and Mote classes are already defined and available
function doubleTapCallbackTest()
-- Initialize ZoomScroller
zoomScroller = ZoomScroller:new(readImage(asset.builtin.Cargo_Bot.Game_Lower_BG), WIDTH/2, HEIGHT/2, WIDTH, HEIGHT)

-- Create a GestureHandler instance if needed
gestureHandler = GestureHandler:new()

-- Initialize test motes
motes = {}
table.insert(motes, Mote:new(100, 100)) -- Mote 1
motes[1].drawingParams = {x = 100, y = 100, size = 20}

table.insert(motes, Mote:new(200, 200)) -- Mote 2
motes[2].drawingParams = {x = 200, y = 200, size = 20}

table.insert(motes, Mote:new(300, 300)) -- Mote 3
motes[3].drawingParams = {x = 300, y = 300, size = 20}

-- Populate currentGrid accordingly
currentGrid = {}
gridSize = 50
for _, mote in ipairs(motes) do
    local gridX = math.floor(mote.position.x / gridSize) + 1
    local gridY = math.floor(mote.position.y / gridSize) + 1
    currentGrid[gridX] = currentGrid[gridX] or {}
    currentGrid[gridX][gridY] = currentGrid[gridX][gridY] or {}
    table.insert(currentGrid[gridX][gridY], mote)
end

-- Function to simulate a double-tap event
local function simulateDoubleTap(x, y)
    local event = {
        x = x,
        y = y,
        touches = {
            {x = x, y = y, prevX = x, prevY = y, state = BEGAN},
            {x = x, y = y, prevX = x, prevY = y, state = BEGAN}
        }
    }
    zoomScroller:doubleTapCallback(event)
end

-- Test Case 1: Double-tap on Mote 1
simulateDoubleTap(100, 100)
if zoomScroller.trackedMote == motes[1] then
    print("Test Case 1 Passed: Mote 1 correctly tracked.")
else
    print("Test Case 1 Failed: Mote 1 not tracked as expected.")
end

-- Reset trackedMote
zoomScroller.trackedMote = nil

-- Test Case 2: Double-tap on Mote 2
simulateDoubleTap(200, 200)
if zoomScroller.trackedMote == motes[2] then
    print("Test Case 2 Passed: Mote 2 correctly tracked.")
else
    print("Test Case 2 Failed: Mote 2 not tracked as expected.")
end

-- Reset trackedMote
zoomScroller.trackedMote = nil

-- Test Case 3: Double-tap on empty space
simulateDoubleTap(400, 400)
if zoomScroller.trackedMote == nil then
    print("Test Case 3 Passed: No mote tracked when tapping empty space.")
else
    print("Test Case 3 Failed: Unexpected mote tracked.")
end

-- Test Case 4: Double-tap overlapping multiple motes (assuming overlap)
-- Adding overlapping mote
table.insert(motes, Mote:new(100, 100))
motes[4].drawingParams = {x = 100, y = 100, size = 20}
currentGrid[math.floor(100 / gridSize) + 1][math.floor(100 / gridSize) + 1] = currentGrid[math.floor(100 / gridSize) + 1][math.floor(100 / gridSize) + 1] or {}
table.insert(currentGrid[math.floor(100 / gridSize) + 1][math.floor(100 / gridSize) + 1], motes[4])

simulateDoubleTap(100, 100)
if zoomScroller.trackedMote == motes[1] or zoomScroller.trackedMote == motes[4] then
    print("Test Case 4 Passed: One of the overlapping motes correctly tracked.")
else
    print("Test Case 4 Failed: Overlapping motes not tracked as expected.")
end

-- Cleanup: Remove the overlapping mote
table.remove(motes, 4)
currentGrid[math.floor(100 / gridSize) + 1][math.floor(100 / gridSize) + 1] = {motes[1]}

end









