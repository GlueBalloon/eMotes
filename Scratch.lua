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





