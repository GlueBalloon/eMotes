

ZoomScroller = class()

function ZoomScroller:init(anImage, x, y, width, height)
    -- Constructor for the ZoomableFrame class
    self.frame = {x = x or WIDTH / 2, y = y or HEIGHT / 2, width = width or WIDTH, height = height or HEIGHT, lastMidpoint = nil, initialDistance = nil}
    self.image = anImage
    self.trackedMote = nil
end

function ZoomScroller:repositionBoundsIfOffscreen()
    -- Reposition frame if offscreen
    local bounds = self.frame
    
    -- Width and height for easier reference
    local halfWidth = bounds.width / 2
    local halfHeight = bounds.height / 2
    
    -- Check if bounds are offscreen and reposition to immediately adjacent position
    local swapOccurred = false
    -- Right edge offscreen
    if bounds.x - halfWidth > WIDTH then
        bounds.x = bounds.x - bounds.width
        swapOccurred = true
    end
    -- Left edge offscreen
    if bounds.x + halfWidth < 0 then
        bounds.x = bounds.x + bounds.width
        swapOccurred = true
    end
    -- Bottom edge offscreen
    if bounds.y - halfHeight > HEIGHT then
        bounds.y = bounds.y - bounds.height
        swapOccurred = true
    end
    -- Top edge offscreen
    if bounds.y + halfHeight < 0 then
        bounds.y = bounds.y + bounds.height
        swapOccurred = true
    end
    if swapOccurred then
        print("swapOccurred")
    end
end

function ZoomScroller:zoomCallback(event)
    self:repositionBoundsIfOffscreen()
    
    local touch1 = event.touches[1]
    local touch2 = event.touches[2]
    
    local initialDistance = math.sqrt((touch1.prevX - touch2.prevX)^2 + (touch1.prevY - touch2.prevY)^2)
    local currentDistance = math.sqrt((touch1.x - touch2.x)^2 + (touch1.y - touch2.y)^2)
    local distanceChange = currentDistance - initialDistance
    
    -- Determine the center of the zoom operation
    local zoomCenter
    if self.trackedMote then
        -- Center the zoom on the tracked mote
        zoomCenter = vec2(self.trackedMote.drawingParams.x, self.trackedMote.drawingParams.y)
    else
        -- Use the midpoint of the pinch gesture
        zoomCenter = vec2((touch1.x + touch2.x) / 2, (touch1.y + touch2.y) / 2)
    end
    
    if touch1.state == BEGAN or touch2.state == BEGAN then
        self.isZooming = true
        self.frame.lastMidpoint = zoomCenter
        self.frame.initialDistance = initialDistance
    else
        local midpointChange = zoomCenter - self.frame.lastMidpoint
        
        if distanceChange ~= 0 and self.frame.initialDistance then
            local scaleChange = currentDistance / self.frame.initialDistance
            self.frame.initialDistance = currentDistance
            
            local newWidth = self.frame.width * scaleChange
            local newHeight = self.frame.height * scaleChange
            
            if newWidth < WIDTH or newHeight < HEIGHT then
                -- Prevent the frame from becoming smaller than the viewport
                return
            end
            
            local offsetX = (self.frame.width - newWidth) * ((zoomCenter.x - self.frame.x) / self.frame.width)
            local offsetY = (self.frame.height - newHeight) * ((zoomCenter.y - self.frame.y) / self.frame.height)
            
            self.frame.x = self.frame.x + offsetX
            self.frame.y = self.frame.y + offsetY
            self.frame.width = newWidth
            self.frame.height = newHeight
        end
        
        if midpointChange.x ~= 0 or midpointChange.y ~= 0 then
            self.frame.x = self.frame.x + midpointChange.x
            self.frame.y = self.frame.y + midpointChange.y
        end
        
        self.frame.lastMidpoint = zoomCenter
    end
end

function ZoomScroller:dragCallback(event)
    if self.isZooming or self.trackedMote then return end
    print("is dragging")
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


function ZoomScroller:doubleTapCallback(event)
    -- Determine the center for the zoom operation
    local zoomCenter
    if self.trackedMote then
        zoomCenter = vec2(self.trackedMote.drawingParams.x, self.trackedMote.drawingParams.y)
    else
        zoomCenter = event.touch.pos
    end
    
    -- Determine the target width and height based on zoom state
    local targetWidth, targetHeight
    local isZoomedIn = self.frame.width > WIDTH or self.frame.height > HEIGHT
    
    if isZoomedIn then
        -- Zoom out
        targetWidth = WIDTH
        targetHeight = HEIGHT
    else
        -- Zoom in
        local scaleChange = 10 -- Adjusting the scale factor for zooming in
        targetWidth = self.frame.width * scaleChange
        targetHeight = self.frame.height * scaleChange
    end
    
    -- Calculate the offset to keep the zoom center consistent
    local offsetX = (self.frame.width - targetWidth) * ((zoomCenter.x - self.frame.x) / self.frame.width)
    local offsetY = (self.frame.height - targetHeight) * ((zoomCenter.y - self.frame.y) / self.frame.height)
    
    -- Tween duration and easing function
    local tweenDuration = 0.25 -- Duration in seconds
    local tweenEasing = tween.easing.cubicInOut
    
    -- Perform the tween
    tween(tweenDuration, self.frame, {
        x = self.frame.x + offsetX,
        y = self.frame.y + offsetY,
        width = targetWidth,
        height = targetHeight
    }, tweenEasing, function()
        -- Callback function after tween is complete
        -- Ensure the frame remains within bounds after zooming
        self:repositionBoundsIfOffscreen()
        
        -- Optionally, update any necessary state or mapping after the zoom operation
        self:updateMapping(self.frame)
    end)
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

function ZoomScroller:getDrawingParameters(nativePosition, nativeSize)
    if not self.zoomMapping then return nil end
    for index, mapping in ipairs(self.zoomMapping) do
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

function ZoomScroller:updateMapping(frame)
    -- Generate the mapping tables based on the current frame
    local mapping = self:frameToViewMapping(frame)
    -- Persist this mapping for use in other operations like tapping
    self.zoomMapping = mapping
end

function ZoomScroller:zoomedPosToAbsolutePos(x, y)
    for _, mapping in ipairs(self.zoomMapping) do
        local zsBounds = mapping.zoomedSectionBounds  -- Zoomed/Screen section bounds
        if x >= zsBounds.left and x <= zsBounds.left + zsBounds.width and
        y >= zsBounds.bottom and y <= zsBounds.bottom + zsBounds.height then
            -- Calculate the position within the zoomed section as a ratio
            local xRatio = (x - zsBounds.left) / zsBounds.width
            local yRatio = (y - zsBounds.bottom) / zsBounds.height
            
            -- Apply the ratio to the absoluteSourceBounds to find the absolute position
            local asBounds = mapping.absoluteSourceBounds  -- Absolute source bounds
            local absoluteX = asBounds.left + xRatio * asBounds.width
            local absoluteY = asBounds.bottom + yRatio * asBounds.height
            
            return absoluteX, absoluteY
        end
    end
    
    -- If (x, y) does not fall within any zoomedSectionBounds, return nil to indicate no mapping found
    return nil, nil
end

function ZoomScroller:getZoomedPosition(original)
    -- Calculate ratios based on original screen dimensions
    local ratioX = original.x / WIDTH
    local ratioY = original.y / HEIGHT
    
    -- Apply these ratios to the frame's current state
    -- Note: This assumes the frame's x and y represent the center of the zoomed area
    local zoomedX = self.frame.x + (ratioX - 0.5) * self.frame.width
    local zoomedY = self.frame.y + (ratioY - 0.5) * self.frame.height
    
    return vec2(zoomedX, zoomedY)
end

function ZoomScroller:followTrackedMote()
    if self.trackedMote then
        
        local zoomedPos
        if self.trackedMote.drawingParams then
            zoomedPos = vec2(self.trackedMote.drawingParams.x, self.trackedMote.drawingParams.y)
        else
            zoomedPos = self:getZoomedPosition(self.trackedMote.position)
        end
        
        local currentAbsolutePos = self.trackedMote.position
        local hasMoteChanged = self.lastTrackedMote ~= self.trackedMote
        local hasJumped = false
        if self.lastAbsolutePos and currentAbsolutePos then
            local jumpX = math.abs(currentAbsolutePos.x - self.lastAbsolutePos.x)
            local jumpY = math.abs(currentAbsolutePos.y - self.lastAbsolutePos.y)
            hasJumped = jumpX > WIDTH * 0.9 or jumpY > HEIGHT * 0.9
        end
        
        self.lastTrackedMote = self.trackedMote
        self.lastAbsolutePos = currentAbsolutePos
        
        local screenCenterX, screenCenterY = WIDTH / 2, HEIGHT / 2
        local offsetX = screenCenterX - zoomedPos.x
        local offsetY = screenCenterY - zoomedPos.y
        
        local targetFrameX = self.frame.x + offsetX
        local targetFrameY = self.frame.y + offsetY
        
        local totalOffset = math.abs(offsetX) + math.abs(offsetY)
        local movementThreshold = 3
        local lerpFactor = 0.2  -- Adjusted for smoother transitions
        
        if hasMoteChanged and totalOffset > movementThreshold then
            -- Replace the tween with manual calculation for smoother transition
            -- This section will manually calculate movement towards the target frame position
            -- ensuring smooth transitions especially across boundaries
            self:manualMoveToTarget(targetFrameX, targetFrameY, lerpFactor)
        elseif hasJumped or (totalOffset < 2 and not self.isTweening) then
            -- When a jump occurs, directly set the frame's position to maintain the offset
            self.frame.x = targetFrameX -- Apply the calculated offset
            self.frame.y = targetFrameY -- Apply the calculated offset
        else
            -- Linear interpolation for smooth following
            self.frame.x = self.frame.x + (targetFrameX - self.frame.x) * lerpFactor
            self.frame.y = self.frame.y + (targetFrameY - self.frame.y) * lerpFactor
        end
    end
end

function ZoomScroller:manualMoveToTarget(targetX, targetY, lerpFactor)
    self.frame.x = self.frame.x + (targetX - self.frame.x) * lerpFactor
    self.frame.y = self.frame.y + (targetY - self.frame.y) * lerpFactor
end
