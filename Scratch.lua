

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

function drawVisibleFrameAreas(frame)
    local visibleAreas = ZoomScroller:visibleAreas(frame) -- Get the visible areas
    pushStyle()
    noFill()
    stroke(0, 255, 0) -- Green color
    strokeWidth(10)
    
    for _, area in ipairs(visibleAreas) do
        -- Draw a rectangle for each visible area
        rect(area.left, area.bottom, area.right - area.left, area.top - area.bottom)
    end
    
    popStyle()
end