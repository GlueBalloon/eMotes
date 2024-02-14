
    
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

function ZoomScroller:visibleAreasWithRatios(frame)
    local visibleAreas = {}
    local visibleAreaRatios = {}  -- New table for storing visible area ratios
    
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
            
            -- Calculate ratios for each visible area relative to the frame
            local ratio = {
                leftRatio = (visibleArea.left - left) / frame.width,
                rightRatio = (right - visibleArea.right) / frame.width,
                topRatio = (top - visibleArea.top) / frame.height,
                bottomRatio = (visibleArea.bottom - bottom) / frame.height,
            }
            
            -- Only add the area and its ratio if it's partially visible on screen
            if visibleArea.left < visibleArea.right and visibleArea.bottom < visibleArea.top then
                table.insert(visibleAreas, visibleArea)
                table.insert(visibleAreaRatios, ratio)  -- Add the corresponding ratio
            end
        end
    end
    
    -- Return both the visible areas and their ratios
    return visibleAreas, visibleAreaRatios
end

--correct table count, one table is not ratios
function ZoomScroller:visibleAreasWithRatios89(frame)
    local visibleAreas = {}
    local visibleAreaRatios = {}  -- New table for storing visible area ratios
    
    -- Calculate the range of tiles to consider based directly on frame's position and size
    local tilesX = math.ceil(WIDTH / frame.width)
    local tilesY = math.ceil(HEIGHT / frame.height)
    
    for i = -1, tilesX do
        for j = -1, tilesY do
            -- Directly calculate starting points for tiling based on the frame's position
            local startX = frame.x + (i * frame.width) - frame.width / 2
            local startY = frame.y + (j * frame.height) - frame.height / 2
            
            -- Define the visible area bounds
            local left = startX
            local right = startX + frame.width
            local top = startY + frame.height
            local bottom = startY
            
            -- Ensure the visible area is within screen bounds
            if right > 0 and left < WIDTH and bottom < HEIGHT and top > 0 then
                local visibleArea = {
                    left = math.max(left, 0),
                    right = math.min(right, WIDTH),
                    top = math.min(top, HEIGHT),
                    bottom = math.max(bottom, 0),
                }
                
                -- Calculate ratios for the visible area relative to the frame
                local ratio = {
                    leftRatio = (visibleArea.left - left) / frame.width,
                    rightRatio = (right - visibleArea.right) / frame.width,
                    topRatio = (top - visibleArea.top) / frame.height,
                    bottomRatio = (visibleArea.bottom - bottom) / frame.height,
                }
                
                -- Add the visible area and its ratio if it's partially visible
                table.insert(visibleAreas, visibleArea)
                table.insert(visibleAreaRatios, ratio)
            end
        end
    end
    
    return visibleAreas, visibleAreaRatios
end













function ZoomScroller:drawRatioAreas(visibleAreaRatios, aColor, lineWidth)
    pushStyle()  -- Save the current drawing style settings
    noFill()  -- Don't fill the rectangles
    stroke(aColor or color(255, 0, 0, 150))  -- Set the stroke color to semi-transparent red
    strokeWidth(lineWidth or 10)  -- Set the stroke width
    
    for _, ratio in ipairs(visibleAreaRatios) do
        -- Calculate the dimensions and position of each rectangle based on screen size and ratio
        local rectLeft = ratio.leftRatio * WIDTH
        local rectRight = WIDTH - (ratio.rightRatio * WIDTH)
        local rectTop = HEIGHT - (ratio.topRatio * HEIGHT)
        local rectBottom = ratio.bottomRatio * HEIGHT
        local rectWidth = rectRight - rectLeft
        local rectHeight = rectTop - rectBottom
        
        -- Draw the rectangle
        rect(rectLeft, rectBottom, rectWidth, rectHeight)
    end
    
    popStyle()  -- Restore the previous drawing style settings
end




function drawCornersVisibleAreaAndRatio(visibleArea, frame)
    -- Define the corners based on the visibleArea table
    local corners = {
        topLeft = {x = visibleArea.left, y = visibleArea.top},
        topRight = {x = visibleArea.right, y = visibleArea.top},
        bottomLeft = {x = visibleArea.left, y = visibleArea.bottom},
        bottomRight = {x = visibleArea.right, y = visibleArea.bottom}
    }
    
    -- Draw ellipses at the corners using screen positions
    pushStyle()
    fill(255, 0, 0) -- Red for direct screen position
    for _, corner in pairs(corners) do
        ellipse(corner.x, corner.y, 40)
    end
    popStyle()
    
    -- Convert corners to ratios
    local cornerRatios = {
        topLeft = {
            xR = (corners.topLeft.x - (frame.x - frame.width / 2)) / frame.width,
            yR = (corners.topLeft.y - (frame.y - frame.height / 2)) / frame.height
        },
        topRight = {
            xR = (corners.topRight.x - (frame.x - frame.width / 2)) / frame.width,
            yR = (corners.topRight.y - (frame.y - frame.height / 2)) / frame.height
        },
        bottomLeft = {
            xR = (corners.bottomLeft.x - (frame.x - frame.width / 2)) / frame.width,
            yR = (corners.bottomLeft.y - (frame.y - frame.height / 2)) / frame.height
        },
        bottomRight = {
            xR = (corners.bottomRight.x - (frame.x - frame.width / 2)) / frame.width,
            yR = (corners.bottomRight.y - (frame.y - frame.height / 2)) / frame.height
        }
    }
    
    -- Draw ellipses at the corners using ratios converted back to screen positions
    pushStyle()
    fill(0, 255, 0) -- Green for ratio position
    for _, ratio in pairs(cornerRatios) do
        local screenPosX = ratio.xR * frame.width + (frame.x - frame.width / 2)
        local screenPosY = ratio.yR * frame.height + (frame.y - frame.height / 2)
        ellipse(screenPosX, screenPosY, 10)
    end
    popStyle()
end








-- Test function to evaluate the correctness of visibleAreas function
function testVisibleAreas()
    -- Define a mock frame and screen size for tests
    local frame = {x = 0, y = 0, width = 0, height = 0}
    local expectedResults = {1, 2, 4} -- Expected number of visible areas for different conditions
    
    -- Test 1: Frame zoomed in (larger than screen)
    frame.width, frame.height = 2 * WIDTH, 2 * HEIGHT
    local areas = ZoomScroller:visibleAreas(frame)
    assert(#areas == expectedResults[1], "Test 1 Failed: Expected 1 visible area, got " .. #areas)
    
    -- Test 2: One border on screen
    frame.width, frame.height = WIDTH / 2, HEIGHT * 2
    areas = ZoomScroller:visibleAreas(frame)
    assert(#areas == expectedResults[2], "Test 2 Failed: Expected 2 visible areas, got " .. #areas)
    
    -- Test 3: A corner on screen
    frame.width, frame.height = 2 * WIDTH, 2 * HEIGHT
    frame.x, frame.y = WIDTH / 4, HEIGHT / 4 -- Adjust frame position to simulate a corner on screen
    areas = ZoomScroller:visibleAreas(frame)
    assert(#areas == expectedResults[3], "Test 3 Failed: Expected 4 visible areas, got " .. #areas)
    
    print("All tests passed.")
end






function drawFrameFromCoordinates(frameAreas, aColor)
    pushStyle()
    noFill()
    local strokeColor = aColor or color(0, 255, 0)
    stroke(strokeColor)
    strokeWidth(20)
    
    for _, area in ipairs(frameAreas) do
        -- Draw a rectangle for each visible area
        rect(area.left, area.bottom, area.right - area.left, area.top - area.bottom)
    end
    
    popStyle()
end


function ZoomScroller:getDrawingParameters1(nativePosition, nativeSize, visibleAreas)
    -- Directly adapt from Mote:draw logic to calculate drawing parameters
    for _, area in ipairs(visibleAreas) do
        -- Check if the mote's native position is within this visible area
        if nativePosition.x >= area.left and nativePosition.x <= area.right and
        nativePosition.y >= area.bottom and nativePosition.y <= area.top then
            -- Calculate the effective startX and startY like in Mote:draw
            local effectiveStartX = (self.frame.x - self.frame.width / 2)
            local effectiveStartY = (self.frame.y - self.frame.height / 2)
            
            -- Adjust mote's position based on the frame's current state
            local adjustedPosX = effectiveStartX + (nativePosition.x * (self.frame.width / WIDTH))
            local adjustedPosY = effectiveStartY + (nativePosition.y * (self.frame.height / HEIGHT))
            
            -- Determine the adjusted size, similarly to how it's done in Mote:draw
            local adjustedSize = nativeSize * (self.frame.width / WIDTH)
            
            -- No explicit "scale" used; directly return adjusted position and size
            return {x = adjustedPosX, y = adjustedPosY, size = adjustedSize}
        end
    end
    
    -- Return nil if the mote is not within any visible area
    return nil
end

function ZoomScroller:getDrawingParameters(nativePosition, nativeSize, visibleAreaRatios)
    for _, ratio in ipairs(visibleAreaRatios) do
        -- Calculate the screen area based on ratios
        local areaLeft = ratio.xR * WIDTH
        local areaTop = (1 - ratio.yR) * HEIGHT
        local areaWidth = ratio.wR * WIDTH
        local areaHeight = ratio.hR * HEIGHT
        
        -- Calculate the bottom and right edges of the area
        local areaRight = areaLeft + areaWidth
        local areaBottom = areaTop - areaHeight
        
        -- Check if the mote's native position is within this screen area
        if nativePosition.x >= areaLeft and nativePosition.x <= areaRight and
        nativePosition.y <= areaTop and nativePosition.y >= areaBottom then
            -- Calculate the mote's position and size relative to the visible area
            local adjustedPosX = (nativePosition.x - areaLeft) / ratio.wR + (self.frame.x - self.frame.width / 2)
            local adjustedPosY = (nativePosition.y - areaBottom) / ratio.hR + (self.frame.y - self.frame.height / 2)
            local adjustedSize = nativeSize * (self.frame.width / WIDTH) -- Assuming uniform scaling for simplicity
            
            return {x = adjustedPosX, y = adjustedPosY, size = adjustedSize}
        end
    end
    
    -- Return nil if the mote is not within any visible area
    return nil
end



















