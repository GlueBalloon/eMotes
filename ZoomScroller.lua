

ZoomScroller = class()

function ZoomScroller:init(anImage, x, y, width, height)
    -- Constructor for the ZoomableFrame class
    self.frame = {x = x or WIDTH / 2, y = y or HEIGHT / 2, width = width or WIDTH, height = height or HEIGHT, lastMidpoint = nil, initialDistance = nil}
    self.image = anImage
end

function ZoomScroller:repositionBoundsIfOffscreen()
    -- Reposition frame if offscreen
    local bounds = self.frame
    
    -- Width and height for easier reference
    local halfWidth = bounds.width / 2
    local halfHeight = bounds.height / 2
    
    -- Check if bounds are offscreen and reposition to immediately adjacent position
    -- Right edge offscreen
    if bounds.x - halfWidth > WIDTH then
        bounds.x = bounds.x - bounds.width
    end
    -- Left edge offscreen
    if bounds.x + halfWidth < 0 then
        bounds.x = bounds.x + bounds.width
    end
    -- Bottom edge offscreen
    if bounds.y - halfHeight > HEIGHT then
        bounds.y = bounds.y - bounds.height
    end
    -- Top edge offscreen
    if bounds.y + halfHeight < 0 then
        bounds.y = bounds.y + bounds.height
    end
end

function ZoomScroller:zoomCallback(event)
    self:repositionBoundsIfOffscreen()
    
    local touch1 = event.touches[1]
    local touch2 = event.touches[2]
    
    local initialDistance = math.sqrt((touch1.prevX - touch2.prevX)^2 + (touch1.prevY - touch2.prevY)^2)
    local currentDistance = math.sqrt((touch1.x - touch2.x)^2 + (touch1.y - touch2.y)^2)
    local distanceChange = currentDistance - initialDistance
    
    local currentMidpoint = vec2((touch1.x + touch2.x) / 2, (touch1.y + touch2.y) / 2)
    
    if touch1.state == BEGAN or touch2.state == BEGAN then
        self.isZooming = true
        self.frame.lastMidpoint = currentMidpoint
        self.frame.initialDistance = initialDistance
    else
        local midpointChange = currentMidpoint - self.frame.lastMidpoint
        
        if distanceChange ~= 0 and self.frame.initialDistance then
            local scaleChange = currentDistance / self.frame.initialDistance
            self.frame.initialDistance = currentDistance
            
            local newWidth = self.frame.width * scaleChange
            local newHeight = self.frame.height * scaleChange
            
            if newWidth < WIDTH or newHeight < HEIGHT then
                return
            end
            
            local offsetX = (self.frame.width - newWidth) * ((currentMidpoint.x - self.frame.x) / self.frame.width)
            local offsetY = (self.frame.height - newHeight) * ((currentMidpoint.y - self.frame.y) / self.frame.height)
            
            self.frame.x = self.frame.x + offsetX
            self.frame.y = self.frame.y + offsetY
            self.frame.width = newWidth
            self.frame.height = newHeight
        end
        
        if midpointChange.x ~= 0 or midpointChange.y ~= 0 then
            self.frame.x = self.frame.x + midpointChange.x
            self.frame.y = self.frame.y + midpointChange.y
        end
        
        self.frame.lastMidpoint = currentMidpoint
    end
end

function ZoomScroller:dragCallback(event)
    if self.isZooming then return end
    self:repositionBoundsIfOffscreen()
    
    local touch = event.touch -- Assuming single-finger touch
    
    if touch.state == BEGAN then
        self.isDragging = true
        self.frame.lastTouchPoint = vec2(touch.x, touch.y)
    elseif self.isDragging and touch.state == MOVING and self.frame.lastTouchPoint then
        local touchChange = vec2(touch.x, touch.y) - self.frame.lastTouchPoint
        
        -- Adjust the frame's position based on the drag
        self.frame.x = self.frame.x + touchChange.x
        self.frame.y = self.frame.y + touchChange.y
        
        -- Update the last touch point for the next event
        self.frame.lastTouchPoint = vec2(touch.x, touch.y)
    elseif touch.state == ENDED or touch.state == CANCELLED then
        -- Reset last touch point on release or cancellation of touch
        self.frame.lastTouchPoint = nil
    end
end

function ZoomScroller:drawTiledImageInBounds(anImageOrNot)
    pushStyle()
    spriteMode(CENTER)
    local anImage = anImageOrNot or self.image
    local bounds = self.frame
    local tilesX = math.ceil(WIDTH / bounds.width) + 1
    local tilesY = math.ceil(HEIGHT / bounds.height) + 1
    
    local startX = bounds.x % bounds.width
    if startX > 0 then startX = startX - bounds.width end
    
    local startY = bounds.y % bounds.height
    if startY > 0 then startY = startY - bounds.height end
    
    for i = -1, tilesX do
        for j = -1, tilesY do
            local x = startX + (i * bounds.width)
            local y = startY + (j * bounds.height)
            sprite(anImage, x, y, bounds.width, bounds.height)
        end
    end
    popStyle()
end
--[[
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

]]

--for debugging:
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

function ZoomScroller:frameToViewMapping(frame)
    local tilesX, tilesY = math.ceil(WIDTH / frame.width), math.ceil(HEIGHT / frame.height)
    local allMappings = {}
    
    for i = -1, tilesX do
        for j = -1, tilesY do
            local startX = frame.x + (i * frame.width) - frame.width / 2
            local startY = frame.y + (j * frame.height) - frame.height / 2
            
            local visibleAreaLeft = math.max(startX, 0)
            local visibleAreaRight = math.min(startX + frame.width, WIDTH)
            local visibleAreaTop = math.min(startY + frame.height, HEIGHT)
            local visibleAreaBottom = math.max(startY, 0)
            
            if visibleAreaRight > visibleAreaLeft and visibleAreaTop > visibleAreaBottom then
                local absoluteSourceRatios = {
                    xR = (visibleAreaLeft) / WIDTH,
                    wR = (visibleAreaRight - visibleAreaLeft) / WIDTH,
                    yR = (HEIGHT - visibleAreaTop) / HEIGHT,
                    hR = (visibleAreaTop - visibleAreaBottom) / HEIGHT,
                }
                
                local zoomedSectionRatios = {
                    xR = (visibleAreaLeft - startX) / frame.width,
                    wR = (visibleAreaRight - visibleAreaLeft) / frame.width,
                    yR = (startY + frame.height - visibleAreaTop) / frame.height,
                    hR = (visibleAreaTop - visibleAreaBottom) / frame.height,
                }
                
                local zoomedSectionBounds = {
                    width = absoluteSourceRatios.wR * WIDTH,
                    height = absoluteSourceRatios.hR * HEIGHT,
                    left = absoluteSourceRatios.xR * WIDTH,
                    bottom = HEIGHT - absoluteSourceRatios.yR * HEIGHT - (absoluteSourceRatios.hR * HEIGHT),
                }
                
                local absoluteSourceBounds = {
                    width = zoomedSectionRatios.wR * WIDTH,
                    height = zoomedSectionRatios.hR * HEIGHT,
                    left = zoomedSectionRatios.xR * WIDTH,
                    bottom = HEIGHT - zoomedSectionRatios.yR * HEIGHT - (zoomedSectionRatios.hR * HEIGHT),
                }
                
                table.insert(allMappings, {
                    absoluteSourceRatios = absoluteSourceRatios,
                    zoomedSectionRatios = zoomedSectionRatios,
                    absoluteSourceBounds = absoluteSourceBounds,
                    zoomedSectionBounds = zoomedSectionBounds,
                })
            end
        end
    end
    
    return allMappings
end

function ZoomScroller:getDrawingParameters3(nativePosition, nativeSize, allMappings)
    for index, mapping in ipairs(allMappings) do
        local absoluteSourceBounds = mapping.absoluteSourceBounds
        local zoomedSectionBounds = mapping.zoomedSectionBounds
        
        -- Check if the mote's native position is within the absolute source area before adjustment
        if nativePosition.x >= absoluteSourceBounds.left and nativePosition.x <= (absoluteSourceBounds.left + absoluteSourceBounds.width) and
        nativePosition.y >= absoluteSourceBounds.bottom and nativePosition.y <= (absoluteSourceBounds.bottom + absoluteSourceBounds.height) then
            
            local zoomRatioWidth = zoomedSectionBounds.width / absoluteSourceBounds.width
            local zoomRatioHeight = zoomedSectionBounds.height / absoluteSourceBounds.height
            
            -- Apply the displacement to the mote's position
            local displacementX = zoomedSectionBounds.left - absoluteSourceBounds.left
            local displacementY = zoomedSectionBounds.bottom - absoluteSourceBounds.bottom
            local adjustedPosX = (nativePosition.x - absoluteSourceBounds.left) * zoomRatioWidth + absoluteSourceBounds.left + displacementX
            local adjustedPosY = (nativePosition.y - absoluteSourceBounds.bottom) * zoomRatioHeight + absoluteSourceBounds.bottom + displacementY
            
            local adjustedSize = nativeSize * zoomRatioWidth  -- for uniform scaling
            
            -- The mote is within the visible zoomed section, return the adjusted position and size
            return {
                x = adjustedPosX,
                y = adjustedPosY,
                size = adjustedSize
            }
        end
    end
    
    -- Return nil if the mote isn't within any visible zoomed section
    return nil
end