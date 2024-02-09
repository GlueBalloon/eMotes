

function drawVisibleFrameArea(frame)
    -- Assuming ZoomScroller:visibleAreas(frame) has been defined elsewhere
    local visibleAreas = ZoomScroller:visibleArea(frame)
    
    -- Check if there are visible areas to draw
    if visibleAreas then
        pushStyle()
        noFill()
        stroke(0, 255, 0) -- Green color for the visible area outline
        strokeWidth(10)
        
        -- Draw the rectangle around the visible part of the frame
        rect(visibleAreas.left, visibleAreas.bottom, 
        visibleAreas.right - visibleAreas.left, visibleAreas.top - visibleAreas.bottom)
        
        popStyle()
    end
end
--[[

function ZoomScroller:visibleArea(frame)
    -- Screen dimensions for comparison
    local screenWidth = WIDTH
    local screenHeight = HEIGHT
    
    -- Calculate the frame's actual bounds
    local frameLeft = frame.x - frame.width / 2
    local frameRight = frame.x + frame.width / 2
    local frameTop = frame.y + frame.height / 2
    local frameBottom = frame.y - frame.height / 2
    
    -- Determine the visible parts of the frame based on its overlap with the screen
    local visibleAreas = {
        left = math.max(frameLeft, 0),
        right = math.min(frameRight, screenWidth),
        top = math.min(frameTop, screenHeight),
        bottom = math.max(frameBottom, 0),
    }
    
    -- Check if the frame is entirely off-screen (no visible areas)
    if visibleAreas.left >= visibleAreas.right or visibleAreas.bottom >= visibleAreas.top then
        return nil -- Indicates no visible area
    end
    
    return visibleAreas
end
]]


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
    
    return visibleAreas
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

