
    
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
    
    -- Ratio for the visible part of the frame
    local visibleRatio = {
        wR = visibleWidth / frame.width,
        hR = visibleHeight / frame.height,
        xR = (visibleLeft - (frame.x - fHalfWidth)) / frame.width,
        yR = (visibleBottom - (frame.y - fHalfHeight)) / frame.height,
    }
    
    -- Initialize the ratios table with the visible area ratio
    local ratios = { visibleRatio }
    
    -- Determine if a frame side is on screen
    local visibleEmptyWidth = WIDTH - visibleWidth
    local visibleEmptyHeight = HEIGHT - visibleHeight
    local edgeOnscreenVertical = visibleEmptyWidth > 0
    local edgeOnscreenHorizontal = visibleEmptyHeight > 0
    
    -- If there's a bisection, calculate the ratio for the other part of the screen
    if (edgeOnscreenVertical and not edgeOnscreenHorizontal) or (edgeOnscreenHorizontal and not edgeOnscreenVertical) then
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
        table.insert(ratios, otherRatio)
    end
    
    -- Handle corner visibility: when neither full bisection nor full visibility occurs
    if not (visibleWidth == WIDTH or visibleHeight == HEIGHT) then
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
            topHeightsF, rightWidthsF = otherHeight, otherWidth
            bottomHeightsF, leftWidthsF = visibleHeight, visibleWidth        
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
        -- Additional areas created by the corner being visible
        -- These areas are the sides that get exposed when a corner is visible
        --[[
        local sideVerticalRatio = {
            wR = (visibleCorner == "topLeft" or visibleCorner == "bottomLeft") and rightWidths / frame.width or leftWidths / frame.width,
            hR = (HEIGHT - visibleHeight - bottomHeights) / frame.height,  -- The vertical gap
            xR = (visibleCorner == "topRight" or visibleCorner == "bottomRight") and 0 or (1 - ((visibleCorner == "topLeft" or visibleCorner == "bottomLeft") and rightWidths / frame.width or leftWidths / frame.width)),
            yR = (visibleCorner == "bottomLeft" or visibleCorner == "bottomRight") and (bottomHeights / frame.height) or (visibleHeight / frame.height),
        }
        table.insert(ratios, sideVerticalRatio)
        
        local sideHorizontalRatio = {
            wR = (WIDTH - visibleWidth - otherWidth) / frame.width,  -- The horizontal gap
            hR = (visibleCorner == "bottomLeft" or visibleCorner == "bottomRight") and topHeights / frame.height or bottomHeights / frame.height,
            xR = (visibleCorner == "topRight" or visibleCorner == "bottomRight") and (visibleWidth / frame.width) or (otherWidth / frame.width),
            yR = (visibleCorner == "topLeft" or visibleCorner == "topRight") and 0 or (1 - ((visibleCorner == "bottomLeft" or visibleCorner == "bottomRight") and topHeights / frame.height or bottomHeights / frame.height)),
        }
        table.insert(ratios, sideHorizontalRatio)
        ]]
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

function drawRatioTableToScreen(ratioTable, aColor)
    pushStyle() -- Save the current drawing style settings
    noFill() -- No fill for the rectangle
    stroke(aColor or color(255, 0, 0) ) -- Red stroke color for visibility
    strokeWidth(25) -- Set the stroke width
    
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

function ZoomScroller:drawRatioAreas(visibleAreaRatios, aColor)
    pushStyle()  -- Save the current drawing style settings
    noFill()  -- Don't fill the rectangles
    stroke(aColor or color(255, 0, 0, 150))  -- Set the stroke color to semi-transparent red
    strokeWidth(10)  -- Set the stroke width
    
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



function ZoomScroller:visibleAreaTablesToXYWH(visibleAreas)
    local xywhAreas = {}
    
    for _, area in ipairs(visibleAreas) do
        local x = area.left
        -- Convert top to y by subtracting height from top (Codea's y increases upwards)
        local y = area.bottom
        local width = area.right - area.left
        local height = area.top - area.bottom
        
        table.insert(xywhAreas, {x = x, y = y, width = width, height = height})
    end
    
    return xywhAreas
end

function ZoomScroller:visibleAreasXYWH(frame)
    -- First, calculate the visible areas using the original method
    local visibleAreas = self:visibleAreas(frame)
    
    -- Now, convert those areas to the xywh format
    local xywhAreas = self:visibleAreaTablesToXYWH(visibleAreas)
    
    return xywhAreas
end


function ZoomScroller:drawAreasXYWH(visibleAreas, aColor)
    pushStyle() -- Save current drawing style settings
    noFill() -- Don't fill the rectangles
    stroke(aColor or color(255, 0, 188)) -- Set stroke color to red for visibility
    strokeWidth(20) -- Set the stroke width
    
    for _, area in ipairs(visibleAreas) do
        -- Draw each rectangle using the provided x, y, width, and height
        rect(area.x, area.y, area.width, area.height)
    end
    
    popStyle() -- Restore previous drawing style settings
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




-- Function to draw a mini frame at a fixed position and size on the screen
function drawMiniFrame(frame)
    pushStyle()
    noFill()
    stroke(255, 0, 0) -- Red color for visibility
    strokeWidth(2)
    
    -- Calculate the fixed-size representation for frame corners
    local topLeftX, topLeftY = xyFrameToFixedRepresentation(frame, frame.x - frame.width / 2, frame.y + frame.height / 2)
    local topRightX, topRightY = xyFrameToFixedRepresentation(frame, frame.x + frame.width / 2, frame.y + frame.height / 2)
    local bottomLeftX, bottomLeftY = xyFrameToFixedRepresentation(frame, frame.x - frame.width / 2, frame.y - frame.height / 2)
    local bottomRightX, bottomRightY = xyFrameToFixedRepresentation(frame, frame.x + frame.width / 2, frame.y - frame.height / 2)
    
    -- Draw lines between the calculated corners to represent the mini frame
    line(topLeftX, topLeftY, topRightX, topRightY)
    line(topRightX, topRightY, bottomRightX, bottomRightY)
    line(bottomRightX, bottomRightY, bottomLeftX, bottomLeftY)
    line(bottomLeftX, bottomLeftY, topLeftX, topLeftY)
    
    popStyle()
    
    return vec2(topLeftX, topLeftY), vec2(topRightX, topRightY),
    vec2(bottomLeftX, bottomLeftY), vec2(bottomRightX, bottomRightY)
end

function drawFrameAreas(frameAreas, aColor)
    pushStyle()
    noFill()
    local strokeColor = aColor or color(0, 255, 0)
    stroke(strokeColor)
    strokeWidth(10)
    
    for _, area in ipairs(frameAreas) do
        -- Draw a rectangle for each visible area
        rect(area.left, area.bottom, area.right - area.left, area.top - area.bottom)
    end
    
    popStyle()
end

function ZoomScroller:calculateRedFrameVisibleAreas(frame)
    -- First, get the areas of the frame that are visible on screen
    local greenVisibleAreas = self:visibleAreas(frame)
    local redVisibleAreas = {}
    
    -- Calculate the scale factor based on the frame's current size compared to the normal screen size
    local scaleFactor = WIDTH / frame.width
    
    for _, area in ipairs(greenVisibleAreas) do
        -- Translate each greenVisibleArea back into normal-sized screen coordinates
        -- Here, we assume the visible area needs to be scaled down by the inverse of the scaleFactor
        local redArea = {
            left = (area.left - (WIDTH / 2)) * scaleFactor + (WIDTH / 2),
            right = (area.right - (WIDTH / 2)) * scaleFactor + (WIDTH / 2),
            top = (area.top - (HEIGHT / 2)) * scaleFactor + (HEIGHT / 2),
            bottom = (area.bottom - (HEIGHT / 2)) * scaleFactor + (HEIGHT / 2),
        }
        
        table.insert(redVisibleAreas, redArea)
    end
    
    return redVisibleAreas
end

function ZoomScroller:placeShapesAlongTop(frame)
    local redVisibleAreas = self:calculateRedFrameVisibleAreas(frame)
    redFrames = #redVisibleAreas
    pushStyle()
    noFill()
    strokeWidth(12)
    stroke(196, 255, 0) -- Use red stroke to draw the rectangles
    
    local yOffset = HEIGHT - 20 -- Y-offset from the top of the screen
    local xOffset = 10 -- Starting X-offset from the left of the screen
    local spacing = 10 -- Spacing between each shape
    
    for _, area in ipairs(redVisibleAreas) do
        local width = area.right - area.left
        local height = area.top - area.bottom
        
        -- Draw each shape with its top edge aligned to yOffset
        rect(xOffset, yOffset - height, width, height)
        
        -- Update xOffset for the next shape
        xOffset = xOffset + width + spacing
    end
    
    popStyle()
end

function ZoomScroller:getDrawingParameters(nativePosition, nativeSize, visibleAreas)
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

function ZoomScroller:xyFrameToScreen(x, y, frame)
    local scaleFactor = WIDTH / frame.width
    local effectiveStartX = (frame.x - frame.width / 2) * scaleFactor
    local effectiveStartY = (frame.y - frame.height / 2) * scaleFactor
    local posX = effectiveStartX + (x * scaleFactor)
    local posY = effectiveStartY + (y * scaleFactor)
    return posX, posY
end

function ZoomScroller:xyScreenToFrame(x, y, frame)
    local scaleFactor = frame.width / WIDTH
    local effectiveStartX = frame.x - frame.width / 2
    local effectiveStartY = frame.y - frame.height / 2
    local posX = ((x - effectiveStartX) / scaleFactor)
    local posY = ((y - effectiveStartY) / scaleFactor)
    return posX, posY
end


printedAlready = 0
-- Function to always translate frame coordinates to a fixed-size representation at the center of the screen
function xyFrameToFixedRepresentation(frame, frameX, frameY, printDebug)
    -- Define the fixed center position for the mini frame
    local miniCenterX = WIDTH / 2
    local miniCenterY = HEIGHT / 2
    -- Define the fixed size for the mini frame
    local miniWidth = WIDTH / 4
    local miniHeight = HEIGHT / 4
    
    -- Calculate the offset from the frame's center to the given point
    local offsetX = frameX - frame.x
    local offsetY = frameY - frame.y
    
    -- Scale the offset to fit the mini frame's size
    local scaledOffsetX = offsetX * (miniWidth / frame.width)
    local scaledOffsetY = offsetY * (miniHeight / frame.height)
    
    if printDebug and printedAlready < 4 then
        print("-----inside xyFrameToFixedRepresentation")
        print("FrameX, FrameY: ", frameX, frameY)
        print("OffsetX, OffsetY: ", offsetX, offsetY)
        print("MiniFrame Position: ", miniCenterX + scaledOffsetX, miniCenterY + scaledOffsetY)
        print("-----yeah")
        printedAlready = printedAlready + 1
    end
    
    -- Apply the scaled offset to the mini frame's center position
    return miniCenterX + scaledOffsetX, miniCenterY + scaledOffsetY
end



function drawEllipsesAtRawAreaPoints(frame)
    -- Draw the mini frame and get its corner points
    local topLeft, topRight, bottomLeft, bottomRight = drawMiniFrame(frame)
    
    -- Get raw tiling areas defined by the frame
    local rawAreas = zoomScroller:defineRawTilingAreas(frame)
    
    -- Draw ellipses at the interior points of these areas within the mini frame
    pushStyle()
    fill(255, 85, 0) -- Green color for ellipses
    noStroke()
    
    for _, area in ipairs(rawAreas) do
        -- Translate the raw area start points to the mini frame's fixed-size representation
        local x, y = xyFrameToFixedRepresentation(frame, area.startX, area.startY)
        
        -- Draw an ellipse at each translated point
        ellipse(x, y, 10, 10) -- Small ellipses for visualization
    end
    
    popStyle()
end

printedDebugRawCornerAlready = 0
function ZoomScroller:drawVisibleCornersOfRawAreas(rawAreas, frame, printDebug)
    pushStyle()
    fill(236, 216, 67)
    for _, area in ipairs(rawAreas) do
        -- Adjust the raw area for the frame being centered and limit to screen bounds
        local left = area.startX - frame.width / 2
        local right = area.startX + frame.width / 2
        local top = area.startY + frame.height / 2
        local bottom = area.startY - frame.height / 2
        
        local visibleCorner = {
            x = nil,
            y = nil
        }
        
        -- Determine which corner(s) are partially visible and set their coordinates
        if left >= 0 and left < WIDTH and top <= HEIGHT and top > 0 then
            visibleCorner.x, visibleCorner.y = left, top -- Top left corner
        elseif right <= WIDTH and right > 0 and top <= HEIGHT and top > 0 then
            visibleCorner.x, visibleCorner.y = right, top -- Top right corner
        elseif left >= 0 and left < WIDTH and bottom >= 0 and bottom < HEIGHT then
            visibleCorner.x, visibleCorner.y = left, bottom -- Bottom left corner
        elseif right <= WIDTH and right > 0 and bottom >= 0 and bottom < HEIGHT then
            visibleCorner.x, visibleCorner.y = right, bottom -- Bottom right corner
        end
        if visibleCorner.x and visibleCorner.y and visibleCorner.x > WIDTH/4 then
            if printDebug and printedDebugRawCornerAlready < 4 then
                print("-----inside drawVisibleCornersOfRawAreas")
                print("left, right: ", left, right)
                print("-----yeah")
                printedDebugRawCornerAlready = printedDebugRawCornerAlready + 1
            end
        end
        -- If a visible corner was found, draw it
        if visibleCorner.x and visibleCorner.y then
            ellipse(visibleCorner.x, visibleCorner.y, 45) -- Draw a small ellipse at the visible corner
        end
    end
    
    popStyle()
end




function ZoomScroller:visibleAreas2(frame)
    local rawAreas = {}
    local visibleAreas = {}
    
    -- Step 1: Define Areas to be Drawn
    local tilesX = math.ceil(WIDTH / frame.width) + 1
    local tilesY = math.ceil(HEIGHT / frame.height) + 1
    for i = -1, tilesX do
        for j = -1, tilesY do
            local startX = frame.x % frame.width + (i * frame.width)
            local startY = frame.y % frame.height + (j * frame.height)
            
            if startX > frame.width then startX = startX - frame.width end
            if startY > frame.height then startY = startY - frame.height end
            
            -- Calculate the "raw" area without adjusting for screen bounds yet
            local area = {startX = startX, startY = startY}
            table.insert(rawAreas, area)
        end
    end
    
    -- Step 2: Adjust for Screen Coordinates
    for _, area in ipairs(rawAreas) do
        -- Adjust the raw area for the frame being centered and limit to screen bounds
        local left = area.startX - frame.width / 2
        local right = area.startX + frame.width / 2
        local top = area.startY + frame.height / 2
        local bottom = area.startY - frame.height / 2
        
        local adjustedArea = {
            left = math.max(left, 0),
            right = math.min(right, WIDTH),
            top = math.min(top, HEIGHT),
            bottom = math.max(bottom, 0),
        }
        
        -- Only add the area if it's partially visible on screen
        if adjustedArea.left < adjustedArea.right and adjustedArea.bottom < adjustedArea.top then
            table.insert(visibleAreas, adjustedArea)
        end
    end
    
    return visibleAreas
end

function ZoomScroller:defineRawTilingAreas(frame)
    local rawAreas = {}
    local tilesX = math.ceil(WIDTH / frame.width) + 1
    local tilesY = math.ceil(HEIGHT / frame.height) + 1
    for i = -1, tilesX do
        for j = -1, tilesY do
            local startX = frame.x % frame.width + (i * frame.width)
            local startY = frame.y % frame.height + (j * frame.height)
            
            if startX > frame.width then startX = startX - frame.width end
            if startY > frame.height then startY = startY - frame.height end
            
            -- Calculate the "raw" area without adjusting for screen bounds yet
            local area = {startX = startX, startY = startY}
            table.insert(rawAreas, area)
        end
    end
    return rawAreas
end

function ZoomScroller:adjustRawAreasForScreen(rawAreas, frame)
    local visibleAreas = {}
    for _, area in ipairs(rawAreas) do
        -- Adjust the raw area for the frame being centered and limit to screen bounds
        local left = area.startX - frame.width / 2
        local right = area.startX + frame.width / 2
        local top = area.startY + frame.height / 2
        local bottom = area.startY - frame.height / 2
        
        local adjustedArea = {
            left = math.max(left, 0),
            right = math.min(right, WIDTH),
            top = math.min(top, HEIGHT),
            bottom = math.max(bottom, 0),
        }
        
        -- Only add the area if it's partially visible on screen
        if adjustedArea.left < adjustedArea.right and adjustedArea.bottom < adjustedArea.top then
            table.insert(visibleAreas, adjustedArea)
        end
    end
    return visibleAreas
end

printDebugVisible3 = 0
function ZoomScroller:visibleAreas3(frame, printDebug)
    local rawAreas = ZoomScroller:defineRawTilingAreas(frame)
    local visibleAreas = ZoomScroller:adjustRawAreasForScreen(rawAreas, frame)
    for i, area in ipairs(rawAreas) do
        if printDebug and printDebugVisible3 < 4 then
            print("-----inside visibleAreas3")
            print("area.startX, area.startY: ", area.startX, area.startY)
            print("visibleAreas[i].left, visibleAreas[i].top: ", visibleAreas[i].left, visibleAreas[i].top)
            print("-----yeah")
            printDebugVisible3 = printDebugVisible3 + 1
        end
    end
    return visibleAreas
end

printedDebugCornerAlready = 0
function ZoomScroller:drawVisibleCornersOnMiniFrame(rawAreas, frame, printDebug)

    
    pushStyle()
    fill(229, 0, 255) -- Red color for visibility
    
    for _, area in ipairs(rawAreas) do
        -- Calculate the corner positions based on raw area start points and the frame's dimensions
        local corners = {
            topLeft = {x = area.startX, y = area.startY + frame.height},
            topRight = {x = area.startX + frame.width, y = area.startY + frame.height},
            bottomLeft = {x = area.startX, y = area.startY},
            bottomRight = {x = area.startX + frame.width, y = area.startY}
        }
         
        -- Iterate through each corner and draw it on the miniFrame if it's within the actual frame's bounds
        for _, corner in pairs(corners) do
            if printDebug and printedDebugCornerAlready < 4 and corner.x > WIDTH/4 then
                print("-----inside drawVisibleCornersOnMiniFrame")
                print("topLeft, topRight: ", topLeft, topRight)
                print("-----yeah")
                printedDebugCornerAlready = printedDebugCornerAlready + 1
            end
            if corner.x >= 0 and corner.x <= WIDTH and corner.y >= 0 and corner.y <= HEIGHT then
                local miniX, miniY = xyFrameToFixedRepresentation(frame, corner.x, corner.y, true)
                ellipse(miniX, miniY, 40) -- Draw a small ellipse at the corner position on the miniFrame
            end
        end
    end
    
    popStyle()
end

