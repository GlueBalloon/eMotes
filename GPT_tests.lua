function testprint(str)
print(str)
end

-- Test Script for ZoomScroller:doubleTapCallback

-- Assume ZoomScroller and Mote classes are already defined and available
function doubleTapCallbackTest()
    -- Test Script for ZoomScroller:doubleTapCallback
    
    -- Assume ZoomScroller and Mote classes are already defined and available
    
    -- Initialize ZoomScroller
    zoomScroller = ZoomScroller(readImage(asset.builtin.Cargo_Bot.Game_Lower_BG), WIDTH/2, HEIGHT/2, WIDTH, HEIGHT)
    
    -- Make callback generic so it's easy to replace
    local callback = function(event)
        zoomScroller:doubleTapCallback(event)
    end
    
    function predictAbsoluteFramePosition(onscreenZoomedX, onscreenZoomedY, zoomMapping)
        local mapping = zoomMapping[1]  -- Assume we're working with the first mapping for simplicity
        local absolutePositionInFrameBounds = mapping.absoluteSourceBounds  -- The frame bounds, where "absolute" refers to the larger world frame
        local positionInOnscreenZoomBounds = mapping.zoomedSectionBounds  -- The bounds of what is shown on screen after zooming
            
        -- Calculate the ratios for the zoomed position (i.e., position in the zoomed onscreen view)
        local xRatio = (onscreenZoomedX - positionInOnscreenZoomBounds.left) / positionInOnscreenZoomBounds.width
        local yRatio = (onscreenZoomedY - positionInOnscreenZoomBounds.bottom) / positionInOnscreenZoomBounds.height
            
        -- Use the ratios to calculate the absolute position in the world frame
        local absoluteFrameX = absolutePositionInFrameBounds.left + xRatio * absolutePositionInFrameBounds.width
        local absoluteFrameY = absolutePositionInFrameBounds.bottom + yRatio * absolutePositionInFrameBounds.height
            
        -- Floor the returned values
        absoluteFrameX = math.floor(absoluteFrameX)
        absoluteFrameY = math.floor(absoluteFrameY)
            
        return absoluteFrameX, absoluteFrameY
    end
        
    function testPredictAbsoluteFramePosition()
        -- Define input coordinates in the onscreen zoomed frame
        local onscreenZoomedX, onscreenZoomedY = 100, 100
            
        -- Set up zoomMapping to scale coordinates by 1.5
        zoomScroller.zoomMapping = {
            {
                absoluteSourceBounds = {left = 0, bottom = 0, width = 500, height = 500},  -- World frame
                zoomedSectionBounds = {left = 0, bottom = 0, width = 333.3333, height = 333.3333}  -- Onscreen zoomed frame
            }
        }
            
        -- Predict the absolute frame position based on the input coordinates
        local expectedFrameX, expectedFrameY = predictAbsoluteFramePosition(onscreenZoomedX, onscreenZoomedY, zoomScroller.zoomMapping)
            
        -- Call the function to convert the onscreen zoomed coordinates to absolute frame coordinates
        local resultFrameX, resultFrameY = zoomScroller:zoomedPosToAbsolutePos(onscreenZoomedX, onscreenZoomedY)
            
        -- Floor the returned values
        resultFrameX = math.floor(resultFrameX)
        resultFrameY = math.floor(resultFrameY)
            
        -- Compare the returned values to the expected values and report the result
        if resultFrameX == expectedFrameX and resultFrameY == expectedFrameY then
            print("Test Passed: Expected values (" .. expectedFrameX .. ", " .. expectedFrameY .. ") were correctly returned.")
        else
            print("Test Failed: Expected (" .. expectedFrameX .. ", " .. expectedFrameY .. ") but got (" .. tostring(resultFrameX) .. ", " .. tostring(resultFrameY) .. ")")
        end
    end
        
    testPredictAbsoluteFramePosition()
        
    -- New function: predictGridLocationFromZoomedScreen
    function predictGridLocationFromScreenLocation(onscreenZoomedX, onscreenZoomedY, zoomMapping, gridSize)

        local absoluteFrameX, absoluteFrameY = predictAbsoluteFramePosition(onscreenZoomedX, onscreenZoomedY, zoomMapping)
        
        -- Calculate the grid cell coordinates based on the absolute frame position
        local gridX = math.floor(absoluteFrameX / gridSize) + 1
        local gridY = math.floor(absoluteFrameY / gridSize) + 1
            
        return gridX, gridY
    end
            
    function testGridLocationFromScreenLocationPredicting()
        -- Define input zoomed screen coordinates and grid size
        local onscreenZoomedX, onscreenZoomedY = 150, 150
        local gridSize = 50
            
        -- Set up zoomMapping to scale coordinates
        zoomScroller.zoomMapping = {
            {
                absoluteSourceBounds = {left = 0, bottom = 0, width = 500, height = 500},  -- Absolute (frame) bounds
                zoomedSectionBounds = {left = 0, bottom = 0, width = 333.3333, height = 333.3333}  -- Onscreen zoom bounds
            }
        }
            
        -- Predict the grid location from the zoomed screen position
        local expectedGridX, expectedGridY = predictGridLocationFromScreenLocation(onscreenZoomedX, onscreenZoomedY, zoomScroller.zoomMapping, gridSize)
            
        -- Calculate the actual grid location based on the absolute position
        -- Translate the zoomed screen coordinates into absolute frame coordinates first
        local absX, absY = zoomScroller:zoomedPosToAbsolutePos(onscreenZoomedX, onscreenZoomedY)
            
        -- Calculate the actual grid location based on the absolute frame position
        local actualGridX = math.floor(absX / gridSize) + 1
        local actualGridY = math.floor(absY / gridSize) + 1
            
        -- Compare the predicted grid location to the actual grid location
        if actualGridX == expectedGridX and actualGridY == expectedGridY then
            print("Test Passed: Expected grid (" .. expectedGridX .. ", " .. expectedGridY .. ") was correctly returned.")
        else
            print("Test Failed: Expected grid (" .. expectedGridX .. ", " .. expectedGridY .. ") but got (" .. actualGridX .. ", " .. actualGridY .. ")")
        end
    end
            
    testGridLocationFromScreenLocationPredicting()
            
    -- Function to place a mote in the correct grid based on its position in the frame
    function putMoteInGrid(mote, gridSize, grid)
        -- Calculate the grid cell coordinates based on the absolute position
        local gridX = math.floor(mote.position.x / gridSize) + 1
        local gridY = math.floor(mote.position.y / gridSize) + 1
        
        -- Ensure the grid has the appropriate structure
        grid[gridX] = grid[gridX] or {}
        grid[gridX][gridY] = grid[gridX][gridY] or {}
        
        -- Place the mote in the grid cell
        table.insert(grid[gridX][gridY], mote)
    end
    
    -- Test function to check if the mote is placed correctly in the grid
    function testPutMoteInGrid()
        -- Create a test grid
        local testGrid = {}
        
        -- Initialize a test mote
        local testMote = Mote(150, 150)  -- Example position
        
        -- Define grid size
        local gridSize = 50
        
        -- Use putMoteInGrid to place the mote in the grid
        putMoteInGrid(testMote, gridSize, testGrid)
        
        -- Calculate the expected grid cell based on the testMote's position
        local expectedGridX = math.floor(testMote.position.x / gridSize) + 1
        local expectedGridY = math.floor(testMote.position.y / gridSize) + 1
        
        -- Check if the mote is in the correct grid cell
        if testGrid[expectedGridX] and testGrid[expectedGridX][expectedGridY] and testGrid[expectedGridX][expectedGridY][1] == testMote then
            print("Test Passed: Mote correctly placed in grid.")
        else
            print("Test Failed: Mote not placed correctly in grid.")
        end
    end
        
    testPutMoteInGrid()
          
    -- Setup function to initialize motes and place them in the grid
    function setupMotesAndGrid()
        
        -- Set up the zoomMapping for the screen
        zoomScroller.zoomMapping = {
            {
                absoluteSourceBounds = {left = 0, bottom = 0, width = 500, height = 500},
                zoomedSectionBounds = {left = 0, bottom = 0, width = 333.3333, height = 333.3333}
            }
        }
        
        local motes = {}
        
        -- Create and place three motes with absolute positions
        table.insert(motes, Mote(100, 100)) -- Mote 1
        motes[1].drawingParams = zoomScroller:getDrawingParameters(motes[1].position, motes[1].size)
       
        table.insert(motes, Mote(200, 200)) -- Mote 2
        motes[2].drawingParams = zoomScroller:getDrawingParameters(motes[2].position, motes[2].size)
        
        table.insert(motes, Mote(300, 300)) -- Mote 3
        motes[3].drawingParams = zoomScroller:getDrawingParameters(motes[3].position, motes[3].size)
             
        -- Populate the grid
        currentGrid = {}
        gridSize = 50
        for _, mote in ipairs(motes) do
            putMoteInGrid(mote, gridSize, currentGrid)
        end
        
        return motes
    end
    local motes = setupMotesAndGrid()
    
    -- Function to simulate a double-tap event at a zoomed screen position
    local function simulateDoubleTap(screenX, screenY)
        local event = {
            x = screenX,
            y = screenY,
            touches = {
                {x = screenX, y = screenY, prevX = screenX, prevY = screenY, state = BEGAN},
                {x = screenX, y = screenY, prevX = screenX, prevY = screenY, state = BEGAN}
            }
        }
        callback(event)
    end
        
    -- Test Case: Double-tap to detect Mote 1
    function testDoubleTapDetectsCorrectMote()
        -- Convert mote's absolute position to zoomed screen coordinates using the zoom mapping
        local zoomMapping = zoomScroller.zoomMapping[1]  -- Use the first zoom mapping
        local absFrameBounds = zoomMapping.absoluteSourceBounds
        local screenZoomBounds = zoomMapping.zoomedSectionBounds
        
        -- Calculate the screen zoomed coordinates based on the absolute position
        local xRatio = (motes[1].position.x - absFrameBounds.left) / absFrameBounds.width
        local yRatio = (motes[1].position.y - absFrameBounds.bottom) / absFrameBounds.height
        local screenX = screenZoomBounds.left + xRatio * screenZoomBounds.width
        local screenY = screenZoomBounds.bottom + yRatio * screenZoomBounds.height
        
        -- Simulate double-tap on the converted screen coordinates
        simulateDoubleTap(screenX, screenY)
        
        -- Detect if the correct mote is selected based on the touch coordinates
        local detectedMote = zoomScroller:detectMoteUnderTouch(vec2(screenX, screenY))
        
        -- Check if the correct mote was detected
        if detectedMote == motes[1] then
            print("Test Case Passed: Mote 1 correctly detected.")
        else
            print("Test Case Failed: Mote 1 not detected as expected.")
        end
        
        -- Reset trackedMote for the next test
        zoomScroller.trackedMote = nil
        
        -- Simulate double-tap on Mote 1
        simulateDoubleTap(screenX, screenY)
        
        -- Check if trackedMote is set correctly
        if zoomScroller.trackedMote == motes[1] then
            print("Test Case Passed: trackedMote correctly set to Mote 1.")
        else
            print("Test Case Failed: trackedMote not set correctly.")
        end
    end
        
    testDoubleTapDetectsCorrectMote()
        
if true then return end
        
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
        
    -- Test Case 4: Double-tap overlapping multiple motes
    -- Adding overlapping mote
    table.insert(motes, Mote(100, 100))
    motes[4].drawingParams = {x = 100, y = 100, size = 20}
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
        
        
        
        
        
        
        
        
        
        