function ZoomScroller:visibleWrappedOnscreenAndFrameRatios(frame)
    -- Calculate the number of tiles needed to cover the screen based on the frame's dimensions.
    -- This takes into account the full width and height of the screen relative to the frame size.
    local tilesX, tilesY = math.ceil(WIDTH / frame.width), math.ceil(HEIGHT / frame.height)
    
    -- Initialize tables to store the calculated ratios:
    -- visibleOnscreenRatios for storing the visible areas on the screen as ratios,
    -- and frameRatios for storing the corresponding areas of the frame as ratios.
    local visibleOnscreenRatios = {}
    local frameRatios = {}

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
                table.insert(visibleOnscreenRatios, screenRatio)
                table.insert(frameRatios, frameRatio)
            end
        end
    end
    
    -- Return both sets of ratios for further processing or drawing.
    return visibleOnscreenRatios, frameRatios
end


function ZoomScroller:drawRatioAreas(ratioAreas, aColor, lineWidth)
    pushStyle()  -- Save the current drawing style settings
    noFill()  -- Don't fill the rectangles
    stroke(aColor or color(255, 0, 0, 150))  -- Set the stroke color to semi-transparent red
    strokeWidth(lineWidth or 10)  -- Set the stroke width
    
    for _, ratio in ipairs(ratioAreas) do
        -- Calculate the dimensions and position of each rectangle based on screen size and ratio
        -- Note: Adjusting calculation to use xR, yR, wR, hR
        local rectLeft = ratio.xR * WIDTH
        local rectWidth = ratio.wR * WIDTH
        local rectHeight = ratio.hR * HEIGHT
        local rectTop = (1 - ratio.yR) * HEIGHT  -- Adjust for yR being from top to bottom
        local rectBottom = rectTop - rectHeight
        
        -- Draw the rectangle
        rect(rectLeft, rectBottom, rectWidth, rectHeight)
    end
    
    popStyle()  -- Restore the previous drawing style settings
end