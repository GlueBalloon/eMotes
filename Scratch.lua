function ZoomScroller:getDrawingParameters(nativePosition, nativeSize, frameAreaRatios, screenAreaRatios)
    for index, frameRatio in ipairs(frameAreaRatios) do
        -- Calculate the relative position of the mote within the frame area using the new ratio format
        local frameAreaWidth = frameRatio.wR * self.frame.width
        local frameAreaHeight = frameRatio.hR * self.frame.height
        local frameAreaLeft = self.frame.x - self.frame.width / 2 + frameRatio.xR * self.frame.width
        local frameAreaBottom = self.frame.y + self.frame.height / 2 - frameRatio.hR * self.frame.height - frameAreaHeight
        
        -- Check if the mote's native position is within this relative frame area
        if nativePosition.x >= frameAreaLeft and nativePosition.x <= (frameAreaLeft + frameAreaWidth) and
        nativePosition.y >= frameAreaBottom and nativePosition.y <= (frameAreaBottom + frameAreaHeight) then
            -- Translate mote's position relative to the frame area into the screen area
            local screenRatio = screenAreaRatios[index] -- Assuming a corresponding screen area exists
            local screenAreaWidth = screenRatio.wR * WIDTH
            local screenAreaHeight = screenRatio.hR * HEIGHT
            local screenAreaLeft = screenRatio.xR * WIDTH
            local screenAreaBottom = HEIGHT - screenRatio.yR * HEIGHT - screenAreaHeight
            
            local relativePosX = (nativePosition.x - frameAreaLeft) / frameAreaWidth
            local relativePosY = (nativePosition.y - frameAreaBottom) / frameAreaHeight
            
            local adjustedPosX = screenAreaLeft + relativePosX * screenAreaWidth
            local adjustedPosY = screenAreaBottom + relativePosY * screenAreaHeight
            local adjustedSize = nativeSize * (screenAreaWidth / WIDTH) -- Adjust size based on screen width
            
            return {x = adjustedPosX, y = adjustedPosY, size = adjustedSize}
        end
    end
    
    -- Return nil if the mote is not within any visible area
    return nil
end

function ZoomScroller:getDrawingParameters(nativePosition, nativeSize, visibleFrameRatios, visibleScreenAreas)
    for _, screenArea in ipairs(visibleScreenAreas) do
        local screenAreaWidth = screenArea.wR * WIDTH
        local screenAreaHeight = screenArea.hR * HEIGHT
        local screenAreaLeft = screenArea.xR * WIDTH
        local screenAreaBottom = HEIGHT - screenArea.yR * HEIGHT - screenAreaHeight
        
        -- Check if the mote's native position is within this screen area
        if nativePosition.x >= screenAreaLeft and nativePosition.x <= (screenAreaLeft + screenAreaWidth) and
        nativePosition.y >= screenAreaBottom and nativePosition.y <= (screenAreaBottom + screenAreaHeight) then
            -- The mote is within a visible screen area, so return its original coordinates and size
            return {
                x = nativePosition.x,
                y = nativePosition.y,
                size = nativeSize
            }
        end
    end
    
    -- The mote is not within any visible screen area, so return nil
    return nil
end

function ZoomScroller:getDrawingParameters(nativePosition, nativeSize, visibleFrameRatios, visibleScreenAreas)
    -- Calculate the zoom ratio as the ratio of the width of the screen area to the width of the original frame area.
    -- This correctly represents the zoom level based on how much of the original frame's width is visible.
    local zoomRatio = self.frame.width / WIDTH
    
   for index, screenArea in ipairs(visibleScreenAreas) do
        local frameRatio = visibleFrameRatios[index] -- Get the corresponding frame ratio for this screen area.
        
        local screenAreaWidth = screenArea.wR * WIDTH
        local screenAreaHeight = screenArea.hR * HEIGHT
        local screenAreaLeft = screenArea.xR * WIDTH
        local screenAreaBottom = HEIGHT - screenArea.yR * HEIGHT - screenAreaHeight
        
        -- Check if the mote's native position is within this screen area
        if nativePosition.x >= screenAreaLeft and nativePosition.x <= (screenAreaLeft + screenAreaWidth) and
        nativePosition.y >= screenAreaBottom and nativePosition.y <= (screenAreaBottom + screenAreaHeight) then
            
            -- Adjust mote's position and size based on the calculated zoom ratio.
            local adjustedPosX = (nativePosition.x - screenAreaLeft) * zoomRatio + screenAreaLeft
            local adjustedPosY = (nativePosition.y - screenAreaBottom) * zoomRatio + screenAreaBottom
            local adjustedSize = nativeSize * zoomRatio
            
            return {
                x = adjustedPosX,
                y = adjustedPosY,
                size = adjustedSize
            }
        end
    end
    
    -- The mote is not within any visible screen area, so return nil
    return nil
end


function ZoomScroller:getDrawingParameters(nativePosition, nativeSize, visibleFrameRatios, visibleScreenAreas)
    local zoomRatio = self.frame.width / WIDTH
    
    -- Determine the center of the zoom area (assuming the entire screen for simplicity)
    local centerX = WIDTH / 2
    local centerY = HEIGHT / 2
    
    for index, screenArea in ipairs(visibleScreenAreas) do
        local frameRatio = visibleFrameRatios[index]
        
        local screenAreaWidth = screenArea.wR * WIDTH
        local screenAreaHeight = screenArea.hR * HEIGHT
        local screenAreaLeft = screenArea.xR * WIDTH
        local screenAreaBottom = HEIGHT - screenArea.yR * HEIGHT - screenAreaHeight
        
        if nativePosition.x >= screenAreaLeft and nativePosition.x <= (screenAreaLeft + screenAreaWidth) and
        nativePosition.y >= screenAreaBottom and nativePosition.y <= (screenAreaBottom + screenAreaHeight) then
            
            -- Calculate the mote's position relative to the center of the zoom area
            local relativePosX = nativePosition.x - centerX
            local relativePosY = nativePosition.y - centerY
        
            -- Apply the zoom ratio to the relative position
            local adjustedPosX = relativePosX * zoomRatio + centerX
            local adjustedPosY = relativePosY * zoomRatio + centerY
            
            -- Adjust the mote's size based on the zoom ratio
            local adjustedSize = nativeSize * zoomRatio
            
            return {
                x = adjustedPosX,
                y = adjustedPosY,
                size = adjustedSize
            }
        end
    end
    
    return nil
end


function ZoomScroller:getDrawingParameters(nativePosition, nativeSize, visibleFrameRatios, visibleScreenAreas)
    for _, screenArea in ipairs(visibleScreenAreas) do
        local screenAreaWidth = screenArea.wR * WIDTH
        local screenAreaHeight = screenArea.hR * HEIGHT
        local screenAreaLeft = screenArea.xR * WIDTH
        local screenAreaBottom = HEIGHT - screenArea.yR * HEIGHT - screenAreaHeight
        
        -- Check if the mote's native position is within this screen area
        if nativePosition.x >= screenAreaLeft and nativePosition.x <= (screenAreaLeft + screenAreaWidth) and
        nativePosition.y >= screenAreaBottom and nativePosition.y <= (screenAreaBottom + screenAreaHeight) then
            -- The mote is within a visible screen area, so return its original coordinates and size
            return {
                x = nativePosition.x,
                y = nativePosition.y,
                size = nativeSize
            }
        end
    end
    
    -- The mote is not within any visible screen area, so return nil
    return nil
end
-- Assuming ElapsedTime is accessible within this scope and that lastDrawTime is a persistent variable defined outside of this function
local lastDrawTime = 0
local drawInterval = 0.1  -- seconds between draws

function ZoomScroller:getDrawingParameters(nativePosition, nativeSize, visibleFrameRatios, visibleScreenAreas)
    local shouldDraw = false
    if ElapsedTime - lastDrawTime > drawInterval then
        shouldDraw = true
        lastDrawTime = ElapsedTime  -- Update last draw time here
    end
    
    for index, screenArea in ipairs(visibleScreenAreas) do
        local frameRatio = visibleFrameRatios[index]
        
        local screenAreaWidth = screenArea.wR * WIDTH
        local screenAreaHeight = screenArea.hR * HEIGHT
        local screenAreaLeft = screenArea.xR * WIDTH
        local screenAreaBottom = HEIGHT - screenArea.yR * HEIGHT - screenAreaHeight
        
        -- If it's time to draw, calculate and draw the bounds and centers
        if shouldDraw then
            -- Drawing bounds and centers
            strokeWidth(8)
            -- Draw the bounds of the screen area
            stroke(255, 0, 0) -- Red for screen area bounds
            noFill()
            rect(screenAreaLeft, screenAreaBottom, screenAreaWidth, screenAreaHeight)
            
            -- Draw the bounds of the frame area
            stroke(0, 255, 0) -- Green for frame area bounds
            local frameLeft = frameRatio.xR * WIDTH
            local frameBottom = (1 - frameRatio.yR - frameRatio.hR) * HEIGHT
            local frameWidth = frameRatio.wR * WIDTH
            local frameHeight = frameRatio.hR * HEIGHT
            rect(frameLeft, frameBottom, frameWidth, frameHeight)
            
            strokeWidth(0)
            -- Draw ellipses at the center points
            fill(255, 226, 0) -- Yellow for the center of the screen area
            ellipse(screenAreaLeft + screenAreaWidth / 2, screenAreaBottom + screenAreaHeight / 2, 10)
            fill(0, 255, 217) -- Blue for the center of the frame area
            ellipse(frameLeft + frameWidth / 2, frameBottom + frameHeight / 2, 10)
        end
        
        -- Checking if the mote's native position is within this screen area
        if nativePosition.x >= screenAreaLeft and nativePosition.x <= (screenAreaLeft + screenAreaWidth) and
        nativePosition.y >= screenAreaBottom and nativePosition.y <= (screenAreaBottom + screenAreaHeight) then
            -- The mote is within a visible screen area, so return its original coordinates and size
            return {
                x = nativePosition.x,
                y = nativePosition.y,
                size = nativeSize
            }
        end
    end
    
    -- The mote is not within any visible screen area, so return nil
    return nil
end

local lastDrawTime = 0
local drawInterval = 0.1  -- seconds between draws

function ZoomScroller:getDrawingParameters(nativePosition, nativeSize, visibleFrameRatios, visibleScreenAreas)
    local shouldDraw = false
    if ElapsedTime - lastDrawTime > drawInterval then
        shouldDraw = true
        lastDrawTime = ElapsedTime  -- Update last draw time here
    end
    
    for index, screenArea in ipairs(visibleScreenAreas) do
        local frameRatio = visibleFrameRatios[index]
        
        local screenAreaWidth = screenArea.wR * WIDTH
        local screenAreaHeight = screenArea.hR * HEIGHT
        local screenAreaLeft = screenArea.xR * WIDTH
        local screenAreaBottom = HEIGHT - screenArea.yR * HEIGHT - screenAreaHeight
        
        local frameLeft = frameRatio.xR * WIDTH
        local frameBottom = (1 - frameRatio.yR - frameRatio.hR) * HEIGHT
        local frameWidth = frameRatio.wR * WIDTH
        local frameHeight = frameRatio.hR * HEIGHT
        
        -- If it's time to draw, calculate and draw the bounds, centers, and line between centers
        if shouldDraw then
            strokeWidth(8)
            -- Draw the bounds of the screen area
            stroke(255, 0, 0) -- Red for screen area bounds
            noFill()
            rect(screenAreaLeft, screenAreaBottom, screenAreaWidth, screenAreaHeight)
            
            -- Draw the bounds of the frame area
            stroke(0, 255, 0) -- Green for frame area bounds
            rect(frameLeft, frameBottom, frameWidth, frameHeight)
            
            
            strokeWidth(0)
            -- Draw ellipses at the center points
            fill(255, 226, 0) -- Yellow for the center of the screen area
            local screenAreaCenterX = screenAreaLeft + screenAreaWidth / 2
            local screenAreaCenterY = screenAreaBottom + screenAreaHeight / 2
            ellipse(screenAreaCenterX, screenAreaCenterY, 10)
            
            fill(0, 255, 217) -- Blue for the center of the frame area
            local frameCenterX = frameLeft + frameWidth / 2
            local frameCenterY = frameBottom + frameHeight / 2
            ellipse(frameCenterX, frameCenterY, 10)
            
            -- Draw a line between the centers
            stroke(255, 141) -- White for the line
            strokeWidth(12)
            line(screenAreaCenterX, screenAreaCenterY, frameCenterX, frameCenterY)
        end
        
        -- Checking if the mote's native position is within this screen area
        if nativePosition.x >= screenAreaLeft and nativePosition.x <= (screenAreaLeft + screenAreaWidth) and
        nativePosition.y >= screenAreaBottom and nativePosition.y <= (screenAreaBottom + screenAreaHeight) then
            return {
                x = nativePosition.x,
                y = nativePosition.y,
                size = nativeSize
            }
        end
    end
    
    return nil
end



local lastDrawTime = 0
local drawInterval = 0.1  -- seconds between draws

function ZoomScroller:getDrawingParameters(nativePosition, nativeSize, visibleFrameRatios, visibleScreenAreas)
    local shouldDraw = false
    if ElapsedTime - lastDrawTime > drawInterval then
        shouldDraw = true
        lastDrawTime = ElapsedTime
    end
    
    for index, screenArea in ipairs(visibleScreenAreas) do
        local frameRatio = visibleFrameRatios[index]
        
        local screenAreaWidth = screenArea.wR * WIDTH
        local screenAreaHeight = screenArea.hR * HEIGHT
        local screenAreaLeft = screenArea.xR * WIDTH
        local screenAreaBottom = HEIGHT - screenArea.yR * HEIGHT - screenAreaHeight
        
        local frameLeft = frameRatio.xR * WIDTH
        local frameBottom = (1 - frameRatio.yR - frameRatio.hR) * HEIGHT
        local frameWidth = frameRatio.wR * WIDTH
        local frameHeight = frameRatio.hR * HEIGHT
        
        -- Calculate the displacement vector
        local displacementX = (frameLeft + frameWidth / 2) - (screenAreaLeft + screenAreaWidth / 2)
        local displacementY = (frameBottom + frameHeight / 2) - (screenAreaBottom + screenAreaHeight / 2)
        
        -- Apply the displacement to the mote's position
        local adjustedPosX = nativePosition.x + displacementX
        local adjustedPosY = nativePosition.y + displacementY
        
        -- Draw bounds, centers, and line between centers if it's time
        if shouldDraw then
            strokeWidth(6)
            -- Draw the bounds of the screen area
            stroke(255, 0, 0) -- Red for screen area bounds
            noFill()
     --       rect(screenAreaLeft, screenAreaBottom, screenAreaWidth, screenAreaHeight)
            
            -- Draw the bounds of the frame area
            stroke(0, 255, 0) -- Green for frame area bounds
            rect(frameLeft, frameBottom, frameWidth, frameHeight)
            
            
            strokeWidth(0)
            -- Draw ellipses at the center points
            fill(255, 226, 0, 145) -- Yellow for the center of the screen area
            local screenAreaCenterX = screenAreaLeft + screenAreaWidth / 2
            local screenAreaCenterY = screenAreaBottom + screenAreaHeight / 2
            ellipse(screenAreaCenterX, screenAreaCenterY, 25)
            
            fill(0, 255, 217, 143) -- Blue for the center of the frame area
            local frameCenterX = frameLeft + frameWidth / 2
            local frameCenterY = frameBottom + frameHeight / 2
            ellipse(frameCenterX, frameCenterY, 25)
            
            -- Draw a line between the centers
            stroke(255, 141) -- White for the line
            strokeWidth(12)
            line(screenAreaCenterX, screenAreaCenterY, frameCenterX, frameCenterY)
        end
        
        -- Check if the mote's native position is within this screen area before adjustment
        -- This check is crucial as it determines if the mote should be considered for displacement
        if nativePosition.x >= screenAreaLeft and nativePosition.x <= (screenAreaLeft + screenAreaWidth) and
        nativePosition.y >= screenAreaBottom and nativePosition.y <= (screenAreaBottom + screenAreaHeight) then
            -- Return the adjusted position of the mote
            return {
                x = adjustedPosX,  -- Mote's new X position after displacement
                y = adjustedPosY,  -- Mote's new Y position after displacement
                size = nativeSize  -- Size remains unchanged
            }
        end
    end
    
    return nil  -- If the mote doesn't fall within any visible screen area
end

function ZoomScroller:getDrawingParameters(nativePosition, nativeSize, visibleFrameRatios, visibleScreenAreas)
    for index, screenArea in ipairs(visibleScreenAreas) do
        local screenAreaWidth = screenArea.wR * WIDTH
        local screenAreaHeight = screenArea.hR * HEIGHT
        local screenAreaLeft = screenArea.xR * WIDTH
        local screenAreaBottom = HEIGHT - screenArea.yR * HEIGHT - screenAreaHeight
        -- Check if the mote's native position is within this screen area before adjustment
        -- This check is crucial as it determines if the mote should be considered for displacement
        if nativePosition.x >= screenAreaLeft and nativePosition.x <= (screenAreaLeft + screenAreaWidth) and
        nativePosition.y >= screenAreaBottom and nativePosition.y <= (screenAreaBottom + screenAreaHeight) then
        
            local frameRatio = visibleFrameRatios[index]
        
            local frameAreaWidth = frameRatio.wR * WIDTH
            local frameAreaHeight = frameRatio.hR * HEIGHT
            local zoomRatioWidth = frameAreaWidth / (screenArea.wR * WIDTH)
            local zoomRatioHeight = frameAreaHeight / (screenArea.hR * HEIGHT)
            
            -- Apply the displacement to the mote's position
            local adjustedPosX = (nativePosition.x - (screenArea.xR * WIDTH)) * zoomRatioWidth + (frameRatio.xR * WIDTH)
            local adjustedPosY = (nativePosition.y - (HEIGHT - screenArea.yR * HEIGHT - screenArea.hR * HEIGHT)) * zoomRatioHeight + ((1 - frameRatio.yR - frameRatio.hR) * HEIGHT)
            
            local adjustedSize = nativeSize * (zoomRatioWidth + zoomRatioHeight) / 2  -- Average of width and height zoom ratio for uniform scaling

            -- The mote is within the visible frame area, return the adjusted position and size
            return {
                x = adjustedPosX,
                y = adjustedPosY,
                size = adjustedSize
            }
        end
    end
    
    -- Return nil if the mote isn't within any visible frame area
    return nil
end
function calculateScreenAreaBounds(screenArea)
    return {
        width = screenArea.wR * WIDTH,
        height = screenArea.hR * HEIGHT,
        left = screenArea.xR * WIDTH,
        bottom = HEIGHT - screenArea.yR * HEIGHT - (screenArea.hR * HEIGHT)
    }
end
function ZoomScroller:getDrawingParameters(nativePosition, nativeSize, visibleFrameRatios, visibleScreenAreas)
    for index, screenArea in ipairs(visibleScreenAreas) do
        local screenBounds = calculateScreenAreaBounds(screenArea)
        
        -- Check if the mote's native position is within this screen area before adjustment
        if nativePosition.x >= screenBounds.left and nativePosition.x <= (screenBounds.left + screenBounds.width) and
        nativePosition.y >= screenBounds.bottom and nativePosition.y <= (screenBounds.bottom + screenBounds.height) then
            
            local frameRatio = visibleFrameRatios[index]
            local frameBounds = calculateScreenAreaBounds(frameRatio)  -- Re-use the same function for frame bounds
            
            local zoomRatioWidth = frameBounds.width / screenBounds.width
            local zoomRatioHeight = frameBounds.height / screenBounds.height
            
            -- Apply the displacement to the mote's position
            local adjustedPosX = (nativePosition.x - screenBounds.left) * zoomRatioWidth + frameBounds.left
            local adjustedPosY = (nativePosition.y - screenBounds.bottom) * zoomRatioHeight + frameBounds.bottom
            
            local adjustedSize = nativeSize * (zoomRatioWidth + zoomRatioHeight) / 2  -- Average of width and height zoom ratio for uniform scaling
            
            -- The mote is within the visible frame area, return the adjusted position and size
            return {
                x = adjustedPosX,
                y = adjustedPosY,
                size = adjustedSize
            }
        end
    end
    
    -- Return nil if the mote isn't within any visible frame area
    return nil
end

function ZoomScroller:getDrawingParameters(nativePosition, nativeSize, visibleFrameRatios, visibleScreenAreas)
    local allBounds = self:calculateAllBounds(visibleFrameRatios, visibleScreenAreas)
    for index, bounds in ipairs(allBounds) do
        local screenBounds = bounds.screenBounds
        local frameBounds = bounds.frameBounds
        
        -- Check if the mote's native position is within the screen area before adjustment
        if nativePosition.x >= screenBounds.left and nativePosition.x <= (screenBounds.left + screenBounds.width) and
        nativePosition.y >= screenBounds.bottom and nativePosition.y <= (screenBounds.bottom + screenBounds.height) then
            
            local zoomRatioWidth = frameBounds.width / screenBounds.width
            local zoomRatioHeight = frameBounds.height / screenBounds.height
            
            -- Apply the displacement to the mote's position
            local displacementX = frameBounds.left - screenBounds.left
            local displacementY = frameBounds.bottom - screenBounds.bottom
            local adjustedPosX = (nativePosition.x - screenBounds.left) * zoomRatioWidth + screenBounds.left + displacementX
            local adjustedPosY = (nativePosition.y - screenBounds.bottom) * zoomRatioHeight + screenBounds.bottom + displacementY
            
            local adjustedSize = nativeSize * (zoomRatioWidth + zoomRatioHeight) / 2  -- Average of width and height zoom ratio for uniform scaling
            
            -- The mote is within the visible frame area, return the adjusted position and size
            return {
                x = adjustedPosX,
                y = adjustedPosY,
                size = adjustedSize
            }
        end
    end
    
    -- Return nil if the mote isn't within any visible frame area
    return nil
end


function ZoomScroller:getDrawingParameters(nativePosition, nativeSize, visibleFrameRatios, visibleScreenAreas)
    local allBounds = self:calculateAllBounds(visibleFrameRatios, visibleScreenAreas)
    
    for index, bounds in ipairs(allBounds) do
        local screenBounds = bounds.screenBounds
        local frameBounds = bounds.frameBounds
        
        -- Check if the mote's native position is within the screen area before adjustment
        if nativePosition.x >= screenBounds.left and nativePosition.x <= (screenBounds.left + screenBounds.width) and
        nativePosition.y >= screenBounds.bottom and nativePosition.y <= (screenBounds.bottom + screenBounds.height) then
            
            local zoomRatioWidth = frameBounds.width / screenBounds.width
            local zoomRatioHeight = frameBounds.height / screenBounds.height
            
            -- Apply the displacement to the mote's position
            local displacementX = frameBounds.left - screenBounds.left
            local displacementY = frameBounds.bottom - screenBounds.bottom
            local adjustedPosX = (nativePosition.x - screenBounds.left) * zoomRatioWidth + screenBounds.left + displacementX
            local adjustedPosY = (nativePosition.y - screenBounds.bottom) * zoomRatioHeight + screenBounds.bottom + displacementY
            
            local adjustedSize = nativeSize * (zoomRatioWidth + zoomRatioHeight) / 2  -- Average of width and height zoom ratio for uniform scaling
            
            -- The mote is within the visible frame area, return the adjusted position and size
            return {
                x = adjustedPosX,
                y = adjustedPosY,
                size = adjustedSize
            }
        end
    end
    
    -- Return nil if the mote isn't within any visible frame area
    return nil
end

function ZoomScroller:getDrawingParameters2(nativePosition, nativeSize, allBounds)
    for index, bounds in ipairs(allBounds) do
        local screenBounds = bounds.screenBounds
        local frameBounds = bounds.frameBounds
        
        -- Check if the mote's native position is within the screen area before adjustment
        if nativePosition.x >= screenBounds.left and nativePosition.x <= (screenBounds.left + screenBounds.width) and
        nativePosition.y >= screenBounds.bottom and nativePosition.y <= (screenBounds.bottom + screenBounds.height) then
            
            local zoomRatioWidth = frameBounds.width / screenBounds.width
            local zoomRatioHeight = frameBounds.height / screenBounds.height
            
            -- Apply the displacement to the mote's position
            local displacementX = frameBounds.left - screenBounds.left
            local displacementY = frameBounds.bottom - screenBounds.bottom
            local adjustedPosX = (nativePosition.x - screenBounds.left) * zoomRatioWidth + screenBounds.left + displacementX
            local adjustedPosY = (nativePosition.y - screenBounds.bottom) * zoomRatioHeight + screenBounds.bottom + displacementY
            
            local adjustedSize = nativeSize * (zoomRatioWidth + zoomRatioHeight) / 2  -- Average of width and height zoom ratio for uniform scaling
            
            -- The mote is within the visible frame area, return the adjusted position and size
            return {
                x = adjustedPosX,
                y = adjustedPosY,
                size = adjustedSize
            }
        end
    end
    
    -- Return nil if the mote isn't within any visible frame area
    return nil
end


function ZoomScroller:calculateAllBounds(visibleFrameRatios, visibleScreenAreas)
    local allBounds = {}
    
    for index, screenArea in ipairs(visibleScreenAreas) do
        -- Calculate bounds for the screen area
        local screenBounds = {
            width = screenArea.wR * WIDTH,
            height = screenArea.hR * HEIGHT,
            left = screenArea.xR * WIDTH,
            bottom = HEIGHT - screenArea.yR * HEIGHT - (screenArea.hR * HEIGHT)
        }
        
        -- Calculate bounds for the corresponding frame area
        local frameRatio = visibleFrameRatios[index]
        local frameBounds = {
            width = frameRatio.wR * WIDTH,
            height = frameRatio.hR * HEIGHT,
            left = frameRatio.xR * WIDTH,
            bottom = HEIGHT - frameRatio.yR * HEIGHT - (frameRatio.hR * HEIGHT)
        }
        
        -- Store both sets of bounds in a subtable within the allBounds table
        table.insert(allBounds, {
            screenRatios = visibleScreenAreas,
            screenBounds = screenBounds,
            frameRatios = visibleFrameRatios,
            frameBounds = frameBounds
        })
    end
    
    return allBounds
end

function ZoomScroller:visibleWrappedOnscreenAndFrameRatios2(frame)
    local tilesX, tilesY = math.ceil(WIDTH / frame.width), math.ceil(HEIGHT / frame.height)
    
    local correctedFrameRatios = {}  -- Previously visibleOnscreenRatios, now correctly representing zoomed/scaled frame portions
    local correctedScreenRatios = {}  -- Previously frameRatios, now correctly representing absolute screen positions
    
    for i = -1, tilesX do
        for j = -1, tilesY do
            local startX = frame.x + (i * frame.width) - frame.width / 2
            local startY = frame.y + (j * frame.height) - frame.height / 2
            
            local left, right, top, bottom = startX, startX + frame.width, startY + frame.height, startY
            
            local visibleArea = {
                left = math.max(left, 0),
                right = math.min(right, WIDTH),
                top = math.min(top, HEIGHT),
                bottom = math.max(bottom, 0),
            }
            
            if right > 0 and left < WIDTH and bottom < HEIGHT and top > 0 then
                -- Corrected to reflect zoomed/scaled frame portions on screen
                local correctedFrameRatio = {
                    xR = (visibleArea.left - startX) / frame.width,
                    wR = (visibleArea.right - visibleArea.left) / frame.width,
                    yR = (startY + frame.height - visibleArea.top) / frame.height,
                    hR = (visibleArea.top - visibleArea.bottom) / frame.height,
                }
                
                -- Corrected to reflect absolute screen positions
                local correctedScreenRatio = {
                    xR = (visibleArea.left) / WIDTH,
                    wR = (visibleArea.right - visibleArea.left) / WIDTH,
                    yR = (HEIGHT - visibleArea.top) / HEIGHT,
                    hR = (visibleArea.top - visibleArea.bottom) / HEIGHT,
                }
                
                table.insert(correctedFrameRatios, correctedFrameRatio)
                table.insert(correctedScreenRatios, correctedScreenRatio)
            end
        end
    end
    
    -- Return the corrected sets of ratios
    return correctedScreenRatios, correctedFrameRatios
end
function ZoomScroller:frameToAllBounds(frame)
    
    -- Calculate the number of tiles needed to cover the screen based on the frame's dimensions.
    -- This takes into account the full width and height of the screen relative to the frame size.
    local tilesX, tilesY = math.ceil(WIDTH / frame.width), math.ceil(HEIGHT / frame.height)
    
    -- Initialize tables to store the calculated ratios:
    -- visibleOnscreenRatios for storing the visible areas on the screen as ratios,
    -- and frameRatios for storing the corresponding areas of the frame as ratios.
    local visibleScreenAreas = {}
    local visibleFrameRatios = {}
    
    -- Iterate through the calculated range of tiles.
    -- The loops start from -1 to ensure coverage around the edges of the screen.
    for i = -1, tilesX do
        for j = -1, tilesY do
            -- Calculate the starting position of each tile based on the current tile indices.
            -- This considers the frame's position and subtracts half the frame's dimension to center the tile.
            local startX = frame.x + (i * frame.width) - frame.width / 2
            local startY = frame.y + (j * frame.height) - frame.height / 2
            
            -- Define the bounds of the visible area for the current tile.
            local left, right, top, bottom = startX, startX + frame.width, startY + frame.height, startY
            
            -- Ensure the visible area is within the boundaries of the screen.
            -- This step clips the area to the screen, ensuring no part extends beyond the screen's edges.
            local visibleArea = {
                left = math.max(left, 0),
                right = math.min(right, WIDTH),
                top = math.min(top, HEIGHT),
                bottom = math.max(bottom, 0),
            }
            
            -- Check if the area is indeed visible on the screen.
            if right > 0 and left < WIDTH and bottom < HEIGHT and top > 0 then
                -- Calculate the screen ratio for the visible area.
                -- This transforms the area's bounds into ratios relative to the screen dimensions,
                -- facilitating the mapping of content within this area to actual screen coordinates.
                local screenRatio = {
                    xR = (visibleArea.left) / WIDTH,
                    wR = (visibleArea.right - visibleArea.left) / WIDTH,
                    yR = (HEIGHT - visibleArea.top) / HEIGHT,
                    hR = (visibleArea.top - visibleArea.bottom) / HEIGHT,
                }
                
                -- Calculate the frame ratio for the visible area.
                -- Similar to screenRatio, but this ratio is relative to the frame's dimensions,
                -- which is useful for mapping content within the frame to this specific area.
                local frameRatio = {
                    xR = (visibleArea.left - startX) / frame.width,
                    wR = (visibleArea.right - visibleArea.left) / frame.width,
                    yR = (startY + frame.height - visibleArea.top) / frame.height,
                    hR = (visibleArea.top - visibleArea.bottom) / frame.height,
                }
                
                -- Store the calculated ratios for later use.
                table.insert(visibleScreenAreas, screenRatio)
                table.insert(visibleFrameRatios, frameRatio)
            end
        end
    end
    
    --kludge to swap terms
    local valet = visibleScreenAreas
    visibleScreenAreas = visibleFrameRatios
    visibleFrameRatios = valet
    --end kludge
    
    local allBounds = {}
    
    for index, screenArea in ipairs(visibleScreenAreas) do
        -- Calculate bounds for the screen area
        local screenBounds = {
            width = screenArea.wR * WIDTH,
            height = screenArea.hR * HEIGHT,
            left = screenArea.xR * WIDTH,
            bottom = HEIGHT - screenArea.yR * HEIGHT - (screenArea.hR * HEIGHT)
        }
        
        -- Calculate bounds for the corresponding frame area
        local frameRatio = visibleFrameRatios[index]
        local frameBounds = {
            width = frameRatio.wR * WIDTH,
            height = frameRatio.hR * HEIGHT,
            left = frameRatio.xR * WIDTH,
            bottom = HEIGHT - frameRatio.yR * HEIGHT - (frameRatio.hR * HEIGHT)
        }
        
        -- Store both sets of bounds in a subtable within the allBounds table
        table.insert(allBounds, {
            screenRatios = visibleScreenAreas,
            screenBounds = screenBounds,
            frameRatios = visibleFrameRatios,
            frameBounds = frameBounds
        })
    end
    return allBounds
end

function ZoomScroller:frameToAllBoundsCorrected(frame)
    local tilesX, tilesY = math.ceil(WIDTH / frame.width), math.ceil(HEIGHT / frame.height)
    
    local correctedFrameRatios = {}  -- Correctly representing zoomed/scaled frame portions on screen
    local correctedScreenAreas = {}  -- Correctly representing absolute screen positions
    
    for i = -1, tilesX do
        for j = -1, tilesY do
            local startX = frame.x + (i * frame.width) - frame.width / 2
            local startY = frame.y + (j * frame.height) - frame.height / 2
            
            local visibleArea = {
                left = math.max(startX, 0),
                right = math.min(startX + frame.width, WIDTH),
                top = math.min(startY + frame.height, HEIGHT),
                bottom = math.max(startY, 0),
            }
            
            if visibleArea.right > visibleArea.left and visibleArea.top > visibleArea.bottom then
                local frameRatio = {
                    xR = (visibleArea.left) / WIDTH,
                    wR = (visibleArea.right - visibleArea.left) / WIDTH,
                    yR = (HEIGHT - visibleArea.top) / HEIGHT,
                    hR = (visibleArea.top - visibleArea.bottom) / HEIGHT,
                }
                
                local screenRatio = {
                    xR = (visibleArea.left - startX) / frame.width,
                    wR = (visibleArea.right - visibleArea.left) / frame.width,
                    yR = (startY + frame.height - visibleArea.top) / frame.height,
                    hR = (visibleArea.top - visibleArea.bottom) / frame.height,
                }
                
                table.insert(correctedFrameRatios, frameRatio)
                table.insert(correctedScreenAreas, screenRatio)
            end
        end
    end
    
    local allBounds = {}
    
    for index, screenRatio in ipairs(correctedScreenAreas) do
        local frameRatio = correctedFrameRatios[index]
        local frameBounds = {
            width = frameRatio.wR * WIDTH,
            height = frameRatio.hR * HEIGHT,
            left = frameRatio.xR * WIDTH,
            bottom = HEIGHT - frameRatio.yR * HEIGHT - (frameRatio.hR * HEIGHT),
        }
        
        local screenBounds = {
            width = screenRatio.wR * WIDTH,
            height = screenRatio.hR * HEIGHT,
            left = screenRatio.xR * WIDTH,
            bottom = HEIGHT - screenRatio.yR * HEIGHT - (screenRatio.hR * HEIGHT),
        }
        
        table.insert(allBounds, {
            screenRatios = correctedScreenAreas,
            frameRatios = correctedFrameRatios,
            screenBounds = screenBounds,
            frameBounds = frameBounds,
        })
    end
    
    return allBounds
end

function ZoomScroller:frameToAllBounds(frame)
    local tilesX, tilesY = math.ceil(WIDTH / frame.width), math.ceil(HEIGHT / frame.height)
    local allBounds = {}
    
    for i = -1, tilesX do
        for j = -1, tilesY do
            local startX = frame.x + (i * frame.width) - frame.width / 2
            local startY = frame.y + (j * frame.height) - frame.height / 2
            
            local visibleAreaLeft = math.max(startX, 0)
            local visibleAreaRight = math.min(startX + frame.width, WIDTH)
            local visibleAreaTop = math.min(startY + frame.height, HEIGHT)
            local visibleAreaBottom = math.max(startY, 0)
            
            -- Ensure the area is within the screen's visible boundaries
            if visibleAreaRight > visibleAreaLeft and visibleAreaTop > visibleAreaBottom then
                -- These are now correctly defining the screen's absolute areas
                local screenRatio = {
                    xR = (visibleAreaLeft) / WIDTH,
                    wR = (visibleAreaRight - visibleAreaLeft) / WIDTH,
                    yR = (HEIGHT - visibleAreaTop) / HEIGHT,
                    hR = (visibleAreaTop - visibleAreaBottom) / HEIGHT,
                }
                
                -- And these define the frame's visible portions
                local frameRatio = {
                    xR = (visibleAreaLeft - startX) / frame.width,
                    wR = (visibleAreaRight - visibleAreaLeft) / frame.width,
                    yR = (startY + frame.height - visibleAreaTop) / frame.height,
                    hR = (visibleAreaTop - visibleAreaBottom) / frame.height,
                }
                
                local frameBounds = {
                    width = screenRatio.wR * WIDTH,
                    height = screenRatio.hR * HEIGHT,
                    left = screenRatio.xR * WIDTH,
                    bottom = HEIGHT - screenRatio.yR * HEIGHT - (screenRatio.hR * HEIGHT),
                }
                
                local screenBounds = {
                    width = frameRatio.wR * WIDTH,
                    height = frameRatio.hR * HEIGHT,
                    left = frameRatio.xR * WIDTH,
                    bottom = HEIGHT - frameRatio.yR * HEIGHT - (frameRatio.hR * HEIGHT),
                }
                
                table.insert(allBounds, {
                    screenRatios = screenRatio,
                    frameRatios = frameRatio,
                    screenBounds = screenBounds,
                    frameBounds = frameBounds,
                })
            end
        end
    end
    
    return allBounds
end