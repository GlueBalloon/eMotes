
    
function ZoomScroller:visibleAreaRatios(frame)
    -- Calculate the visible portion of the frame in screen coordinates
    local fHalfWidth = frame.width / 2
    local fHalfHeight = frame.height / 2
    local visibleLeft = math.max(frame.x - fHalfWidth, 0)
    local visibleRight = math.min(frame.x + fHalfWidth, WIDTH)
    local visibleTop = math.min(frame.y + fHalfHeight, HEIGHT)
    local visibleBottom = math.max(frame.y - fHalfHeight, 0)
    
    -- Calculate the visible area's width and height
    local visibleWidth = visibleRight - visibleLeft
    local visibleHeight = visibleTop - visibleBottom
    
    local ratios = {}
    
    -- Determine if a frame side is on screen
    local visibleEmptyWidth = WIDTH - visibleWidth
    local visibleEmptyHeight = HEIGHT - visibleHeight
    local edgeOnscreenVertical = visibleEmptyWidth > 0
    local edgeOnscreenHorizontal = visibleEmptyHeight > 0
    
    -- If there's a bisection, calculate the ratio for the other part of the screen
    if (edgeOnscreenVertical and not edgeOnscreenHorizontal) or (edgeOnscreenHorizontal and not edgeOnscreenVertical) then
        
        -- Ratio for the visible part of the frame
        local visibleRatio = {
            wR = visibleWidth / frame.width,
            hR = visibleHeight / frame.height,
            xR = (visibleLeft - (frame.x - fHalfWidth)) / frame.width,
            yR = (visibleBottom - (frame.y - fHalfHeight)) / frame.height,
        }
        
        local otherWidth = edgeOnscreenVertical and visibleEmptyWidth or visibleWidth
        local otherHeight = edgeOnscreenHorizontal and visibleEmptyHeight or visibleHeight
        local otherX, otherY
        
        if edgeOnscreenVertical then
            otherX = (visibleRight < WIDTH) and frame.x - fHalfWidth or frame.x - otherWidth + fHalfWidth  -- Opposite side of the visible area
            otherY = visibleBottom  -- Same vertical position as the visible area
        else -- bisectedH
            otherY = (visibleTop < HEIGHT) and frame.y - fHalfHeight or frame.y - otherHeight + fHalfHeight  -- Opposite side of the visible area
            otherX = visibleLeft  -- Same horizontal position as the visible area
        end
        
        -- Adjust otherX and otherY to be relative to the frame's position
        local relativeX = otherX - (frame.x - fHalfWidth)
        local relativeY = otherY - (frame.y - fHalfHeight)
        
        local otherRatio = {
            wR = otherWidth / frame.width,
            hR = otherHeight / frame.height,
            xR = relativeX / frame.width,
            yR = relativeY / frame.height,
        }
        
        ratios = { visibleRatio, otherRatio }

    -- Handle corner visibility: when neither full bisection nor full visibility occurs
    elseif not (visibleWidth == WIDTH or visibleHeight == HEIGHT) then
        -- Calculate positions of the four corners of the frame
        local topLeftF = {x = frame.x - fHalfWidth, y = frame.y + fHalfHeight}
        local topRightF = {x = frame.x + fHalfWidth, y = frame.y + fHalfHeight}
        local bottomLeftF = {x = frame.x - fHalfWidth, y = frame.y - fHalfHeight}
        local bottomRightF = {x = frame.x + fHalfWidth, y = frame.y - fHalfHeight}

        local otherWidth = WIDTH - visibleWidth
        local otherHeight = HEIGHT - visibleHeight
        
        visibleCorner = nil
        
        local topHeightsF, bottomHeightsF, leftWidthsF, rightWidthsF
        if (topLeftF.x >= 0 and topLeftF.x <= WIDTH and topLeftF.y >= 0 and topLeftF.y <= HEIGHT) then--top left
            visibleCorner = "visibleBottomRight"
            topHeightsF, leftWidthsF = visibleHeight, visibleWidth 
            bottomHeightsF, rightWidthsF = otherHeight, otherWidth    
        elseif (topRightF.x >= 0 and topRightF.x <= WIDTH and topRightF.y >= 0 and topRightF.y <= HEIGHT) then --top right 
            visibleCorner = "visibleBottomLeft"
            topHeightsF, rightWidthsF = visibleHeight, visibleWidth  
            bottomHeightsF, leftWidthsF = otherHeight, otherWidth        
        elseif (bottomLeftF.x >= 0 and bottomLeftF.x <= WIDTH and bottomLeftF.y >= 0 and bottomLeftF.y <= HEIGHT) then --bottom left
            visibleCorner = "visibleTopRight"
            topHeightsF, rightWidthsF = otherHeight, otherWidth    
            bottomHeightsF, leftWidthsF = visibleHeight, visibleWidth      
        elseif (bottomRightF.x >= 0 and bottomRightF.x <= WIDTH and bottomRightF.y >= 0 and bottomRightF.y <= HEIGHT) then --bottom right
            visibleCorner = "visibleTopLeft"
            topHeightsF, leftWidthsF = otherHeight, otherWidth 
            bottomHeightsF, rightWidthsF = visibleHeight, visibleWidth        
        else
            visibleCorner = "not found"
            return ratios
        end
            
        -- Opposite corner area ratio (other area)
        local frameBottomLeftRatio = {
            wR = leftWidthsF / frame.width,
            hR = bottomHeightsF / frame.height,
            xR = 0,
            yR = 0 
        }
        local frameBottomRightRatio = {
            wR = rightWidthsF / frame.width,
            hR = bottomHeightsF / frame.height,
            xR = (frame.width - rightWidthsF) / frame.width,
            yR = 0 
        }
        local frameTopRightRatio = {
            wR = rightWidthsF / frame.width,
            hR = topHeightsF / frame.height,
            xR = (frame.width - rightWidthsF) / frame.width,
            yR = (frame.height - topHeightsF) / frame.height
        }
        local frameTopLeftRatio = {
            wR = leftWidthsF / frame.width,
            hR = topHeightsF / frame.height,
            xR = 0,
            yR = (frame.height - topHeightsF) / frame.height
        }
        table.insert(ratios, frameBottomLeftRatio)
        table.insert(ratios, frameBottomRightRatio)
        table.insert(ratios, frameTopRightRatio)
        table.insert(ratios, frameTopLeftRatio)
    else
        --visible area is fully inside screen bounds
        -- Ratio for the visible part of the frame
        local visibleRatio = {
            wR = visibleWidth / frame.width,
            hR = visibleHeight / frame.height,
            xR = (visibleLeft - (frame.x - fHalfWidth)) / frame.width,
            yR = (visibleBottom - (frame.y - fHalfHeight)) / frame.height,
        }
        
        ratios = { visibleRatio }
    end
    ratioTableCount = #ratios
    -- Return the array of ratio tables
    return ratios
end




function drawRatioTablesToScreen(ratioTables, aColor)
    pushStyle()
    noFill()
    stroke(aColor or color(255, 0, 0)) -- Red color for visibility
    strokeWidth(40)
    
    for _, ratio in ipairs(ratioTables) do
        -- Calculate the rectangle's position and size based on the screen dimensions and the ratio table
        local rectX = WIDTH * ratio.xR
        local rectY = HEIGHT * ratio.yR
        local rectWidth = WIDTH * ratio.wR
        local rectHeight = HEIGHT * ratio.hR
        
        -- Draw the rectangle
        rect(rectX, rectY, rectWidth, rectHeight)
    end
    
    popStyle()
end



function ZoomScroller:visibleAreaRatio(frame)
    -- Calculate the visible portion of the frame in screen coordinates
    local visibleLeft = math.max(frame.x - frame.width / 2, 0)
    local visibleRight = math.min(frame.x + frame.width / 2, WIDTH)
    local visibleTop = math.min(frame.y + frame.height / 2, HEIGHT)
    local visibleBottom = math.max(frame.y - frame.height / 2, 0)
    
    -- Calculate the visible area's width and height
    local visibleWidth = visibleRight - visibleLeft
    local visibleHeight = visibleTop - visibleBottom
    
    -- Determine the ratio of the visible area to the frame's total area
    local ratio = {
        wR = visibleWidth / frame.width,
        hR = visibleHeight / frame.height,
        xR = (visibleLeft - (frame.x - frame.width / 2)) / frame.width,
        yR = (visibleBottom - (frame.y - frame.height / 2)) / frame.height,
    }
    
    -- Return the ratio table for the visible area
    return ratio
end

function drawRatioTableToScreen(ratioTable, aColor, lineWidth)
    pushStyle() -- Save the current drawing style settings
    noFill() -- No fill for the rectangle
    stroke(aColor or color(255, 0, 0) ) -- Red stroke color for visibility
    strokeWidth(lineWidth or 25) -- Set the stroke width
    
    -- Calculate the rectangle's position and size based on the screen dimensions and the ratio table
    local rectX = WIDTH * ratioTable.xR
    local rectY = HEIGHT * ratioTable.yR
    local rectWidth = WIDTH * ratioTable.wR
    local rectHeight = HEIGHT * ratioTable.hR
    
    -- Draw the rectangle
    rect(rectX, rectY, rectWidth, rectHeight)
    
    popStyle() -- Restore the previous drawing style settings
end


    
function ZoomScroller:visibleAreas(frame)
    local visibleAreas = {}
    -- Assume the frame can be fully contained within the screen for simplification.
    local tilesX = math.ceil(WIDTH / frame.width) + 1
    local tilesY = math.ceil(HEIGHT / frame.height) + 1
    
    for i = -1, tilesX do
        for j = -1, tilesY do
            -- Calculate the starting points for tiling
            local startX = frame.x % frame.width + (i * frame.width)
            local startY = frame.y % frame.height + (j * frame.height)
            
            if startX > frame.width then startX = startX - frame.width end
            if startY > frame.height then startY = startY - frame.height end
            
            -- Adjust for the frame being centered
            local left = startX - frame.width / 2
            local right = startX + frame.width / 2
            local top = startY + frame.height / 2
            local bottom = startY - frame.height / 2
            
            -- Limit the areas to the screen bounds
            local visibleArea = {
                left = math.max(left, 0),
                right = math.min(right, WIDTH),
                top = math.min(top, HEIGHT),
                bottom = math.max(bottom, 0),
            }
            
            -- Only add the area if it's partially visible on screen
            if visibleArea.left < visibleArea.right and visibleArea.bottom < visibleArea.top then
                table.insert(visibleAreas, visibleArea)
            end
        end
    end
    greenFrames = #visibleAreas
    return visibleAreas
end
















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





















