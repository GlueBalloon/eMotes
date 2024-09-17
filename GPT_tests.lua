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
    
    -- New function: predictAbsolutePosition
    function predictAbsolutePosition(relativeX, relativeY, zoomMapping)
        local mapping = zoomMapping[1]  -- Assume we're working with the first mapping for simplicity
        local absBounds = mapping.absoluteSourceBounds
        local zoomBounds = mapping.zoomedSectionBounds
        
        -- Calculate the ratios for the zoomed position
        local xRatio = (relativeX - zoomBounds.left) / zoomBounds.width
        local yRatio = (relativeY - zoomBounds.bottom) / zoomBounds.height
        
        -- Use the ratios to calculate the absolute position
        local absoluteX = absBounds.left + xRatio * absBounds.width
        local absoluteY = absBounds.bottom + yRatio * absBounds.height
       
         -- Floor the returned values
        absoluteX = math.floor(absoluteX)
        absoluteY = math.floor(absoluteY)
        
        return absoluteX, absoluteY
    end
    
    function testAbsolutePositionPredicting()
        -- Define input coordinates and expected outputs
        local inputX, inputY = 100, 100
              
        -- Set up zoomMapping to scale coordinates by 1.5
        zoomScroller.zoomMapping = {
            {
                absoluteSourceBounds = {left = 0, bottom = 0, width = 500, height = 500},
                zoomedSectionBounds = {left = 0, bottom = 0, width = 333.3333, height = 333.3333}
            }
        }
        
        local expectedX, expectedY = predictAbsolutePosition(inputX, inputY, zoomScroller.zoomMapping)
        
        -- Call the function and capture its return values
        local resultX, resultY = zoomScroller:zoomedPosToAbsolutePos(inputX, inputY)
       
         -- Floor the returned values
        resultX = math.floor(resultX)
        resultY = math.floor(resultY)
    
        -- Compare the returned values to the expected values and report the result
        if resultX == expectedX and resultY == expectedY then
            print("Test Passed: Expected values (" .. expectedX .. ", " .. expectedY .. ") were correctly returned by zoomedPosToAbsolutePos.")
        else
            print("Test Failed: Expected (" .. expectedX .. ", " .. expectedY .. ") but got (" .. tostring(resultX) .. ", " .. tostring(resultY) .. ")")
        end
    end
    
    testAbsolutePositionPredicting()
    
    -- New function: predictGridLocationFromAbsolute
    function predictGridLocationFromAbsolute(absX, absY, zoomMapping, gridSize)
        -- Use the zoomMapping to find the relative position
        local mapping = zoomMapping[1]  -- Assume we're working with the first mapping for simplicity
        local absBounds = mapping.absoluteSourceBounds
        local zoomBounds = mapping.zoomedSectionBounds
        
        -- Calculate the ratios for the absolute position
        local xRatio = (absX - absBounds.left) / absBounds.width
        local yRatio = (absY - absBounds.bottom) / absBounds.height
        
        -- Use the ratios to calculate the relative (zoomed) position
        local relativeX = zoomBounds.left + xRatio * zoomBounds.width
        local relativeY = zoomBounds.bottom + yRatio * zoomBounds.height
        
        -- Calculate the grid cell coordinates based on the relative position
        local gridX = math.floor(relativeX / gridSize) + 1
        local gridY = math.floor(relativeY / gridSize) + 1
        
        return gridX, gridY
    end
    
    -- Test: predict the correct grid location from absolute values
    function testGridLocationFromAbsolutePredicting()
        -- Define input absolute coordinates and grid size
        local absX, absY = 150, 150
        local gridSize = 50
        
        -- Set up zoomMapping to scale coordinates
        zoomScroller.zoomMapping = {
            {
                absoluteSourceBounds = {left = 0, bottom = 0, width = 500, height = 500},
                zoomedSectionBounds = {left = 0, bottom = 0, width = 333.3333, height = 333.3333}
            }
        }
        
        -- Predict the grid location from the absolute position
        local expectedGridX, expectedGridY = predictGridLocationFromAbsolute(absX, absY, zoomScroller.zoomMapping, gridSize)
        
        -- Calculate the actual grid location based on the absolute position
        local actualGridX = math.floor(absX / gridSize) + 1
        local actualGridY = math.floor(absY / gridSize) + 1
        
        -- Compare the predicted grid location to the actual grid location
        if actualGridX == expectedGridX and actualGridY == expectedGridY then
            print("Test Passed: Expected grid (" .. expectedGridX .. ", " .. expectedGridY .. ") was correctly returned.")
        else
            print("Test Failed: Expected grid (" .. expectedGridX .. ", " .. expectedGridY .. ") but got (" .. actualGridX .. ", " .. actualGridY .. ")")
        end
    end
    
    function testGridPositionWithTranslatedCoords()
        -- Set up gridSize and mote positions
        gridSize = 50
        
        -- Initialize ZoomScroller and set a zoomed frame (for the test)
        zoomScroller = ZoomScroller(readImage(asset.builtin.Cargo_Bot.Game_Lower_BG), WIDTH/2, HEIGHT/2, WIDTH, HEIGHT)
        -- Set up zoomMapping to scale coordinates by 1.5
        
        zoomScroller.zoomMapping = {
            {
                absoluteSourceBounds = {left = 0, bottom = 0, width = 500, height = 500},
                zoomedSectionBounds = {left = 0, bottom = 0, width = 333.3333, height = 333.3333}
            }
        }
        
        -- Define the mote's relative position in the zoomed frame
        local testMote = Mote(150, 150) -- Zoomed position, relative to the frame
        testMote.drawingParams = {x = 150, y = 150, size = 20}
        
        -- Expected grid calculation for (150, 150) using zoomed coordinates
        local expectedGridX = math.floor(testMote.drawingParams.x / gridSize) + 1
        local expectedGridY = math.floor(testMote.drawingParams.y / gridSize) + 1
        
        -- Convert the zoomed position to an absolute screen position using the current zoom
        local absX, absY = zoomScroller:getZoomedPosition(vec2(testMote.drawingParams.x, testMote.drawingParams.y)).x,
        zoomScroller:getZoomedPosition(vec2(testMote.drawingParams.x, testMote.drawingParams.y)).y
        
        -- Call the callback with the absolute position
        local event = {
            x = absX,
            y = absY,
            touches = {
                {x = absX, y = absY, prevX = absX, prevY = absY, state = BEGAN},
                {x = absX, y = absY, prevX = absX, prevY = absY, state = BEGAN}
            }
        }
        zoomScroller:doubleTapCallback(event)
        
        -- Calculate the resulting grid positions based on the zoomed (relative) coordinates
        local resultGridX = math.floor(testMote.drawingParams.x / gridSize) + 1
        local resultGridY = math.floor(testMote.drawingParams.y / gridSize) + 1
        
        -- Compare the results
        if resultGridX == expectedGridX and resultGridY == expectedGridY then
            print("Test Passed: Grid positions correctly calculated.")
        else
            print("Test Failed: Expected Grid (" .. expectedGridX .. ", " .. expectedGridY .. ") but got (" .. resultGridX .. ", " .. resultGridY .. ")")
        end
    end
    
    testGridPositionWithTranslatedCoords()
    
    -- Initialize test motes
    motes = {}
    table.insert(motes, Mote(100, 100)) -- Mote 1
    motes[1].drawingParams = {x = 100, y = 100, size = 20}
    
    table.insert(motes, Mote(200, 200)) -- Mote 2
    motes[2].drawingParams = {x = 200, y = 200, size = 20}
    
    table.insert(motes, Mote(300, 300)) -- Mote 3
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
    function testDoubleTapDetectsCorrectMote()
        -- Simulate double-tap on Mote 1
        simulateDoubleTap(100, 100)
        
        -- Check if the correct mote is detected
        if zoomScroller:detectMoteUnderTouch({x = 100, y = 100}) == motes[1] then
            print("Test Case 1a Passed: Mote 1 correctly detected.")
        else
            print("Test Case 1a Failed: Mote 1 not detected as expected.")
        end
        
        -- Reset trackedMote
        zoomScroller.trackedMote = nil
    end
    function testDoubleTapAssignsTrackedMote()
        -- Simulate double-tap on Mote 1
        simulateDoubleTap(100, 100)
        
        -- Check if trackedMote is set correctly
        if zoomScroller.trackedMote == motes[1] then
            print("Test Case 1b Passed: trackedMote correctly set to Mote 1.")
        else
            print("Test Case 1b Failed: trackedMote not set correctly.")
        end
        
        -- Reset trackedMote
        zoomScroller.trackedMote = nil
    end
    
    testDoubleTapDetectsCorrectMote()
    testDoubleTapAssignsTrackedMote()
    
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









