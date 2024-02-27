function ZoomScroller:followTrackedMote()
    if self.trackedMote then
        -- Step 1: Calculate the mote's position relative to the frame's current view
        -- This determines where the mote appears within the frame.
        local relativePosX = (self.trackedMote.position.x - self.frame.x) + WIDTH / 2
        local relativePosY = (self.trackedMote.position.y - self.frame.y) + HEIGHT / 2
        
        -- Step 2: Adjust the frame's position to center on the mote's relative position
        -- Since we want the mote's relative position to be at the center of the screen,
        -- we need to adjust the frame's center to match the screen's center.
        -- We reverse the calculation: set the frame's center to the mote's absolute position.
        -- This effectively centers the view on the mote.
        self.frame.x = self.trackedMote.position.x - (WIDTH / 2 - relativePosX)
        self.frame.y = self.trackedMote.position.y - (HEIGHT / 2 - relativePosY)
    end
end
function ZoomScroller:followTrackedMote()
    if self.trackedMote and self.getDrawingParameters then
        -- Use the existing method to calculate the mote's position and size in the current view
        local drawingParams = self:getDrawingParameters(self.trackedMote.position, self.trackedMote.size)
        
        if drawingParams then
            -- Calculate the center of the screen
            local screenCenterX, screenCenterY = WIDTH / 2, HEIGHT / 2
            
            -- Find the offset needed to move the drawingParams.x,y to the screen center
            local offsetX = screenCenterX - drawingParams.x
            local offsetY = screenCenterY - drawingParams.y
            
            local targetFrameX = self.frame.x + offsetX
            local targetFrameY = self.frame.y + offsetY
            
            if (math.abs(offsetX) + math.abs(offsetY)) < 2 then
                -- Adjust the frame's position by this offset
                -- This moves the frame so that the mote's position is now at the screen's center
                self.frame.x = targetFrameX
                self.frame.y = targetFrameY
                if trackingTween then
                    tween.stop(trackingTween)
                end
            else
                -- Use tween to animate the frame's position smoothly
                trackingTween = tween(0.5, self.frame, {x = targetFrameX, y = targetFrameY}, tween.easing.cubicInOut)
            end
        end
    end
end

function ZoomScroller:followTrackedMote()
    if self.trackedMote and self.getDrawingParameters then
        local drawingParams = self:getDrawingParameters(self.trackedMote.position, self.trackedMote.size)
        
        if drawingParams then
            local screenCenterX, screenCenterY = WIDTH / 2, HEIGHT / 2
            local offsetX = screenCenterX - drawingParams.x
            local offsetY = screenCenterY - drawingParams.y
            
            local targetFrameX = self.frame.x + offsetX
            local targetFrameY = self.frame.y + offsetY
            
            -- Calculate total offset distance
            local totalOffset = math.abs(offsetX) + math.abs(offsetY)
            
            -- Only proceed with tweening if the total offset is significant to avoid flickering
            if totalOffset > 15 and not self.isTweening then  -- Adjust the threshold as necessary
                -- Ensure any ongoing tween is stopped before starting a new one
                if self.trackingTween then
                    tween.stop(self.trackingTween)
                end
                
                self.isTweening = true  -- Flag to prevent multiple tweens from being set up simultaneously
                self.trackingTween = tween(1, self.frame, {x = targetFrameX, y = targetFrameY}, tween.easing.cubicInOut, function()
                    self.isTweening = false  -- Reset flag once tween completes
                end)
            elseif totalOffset <= 15 then
                if self.trackingTween then
                    tween.stop(self.trackingTween)
                    self.isTweening = false
                end
                -- For very small distances, adjust directly without tweening
                self.frame.x = targetFrameX
                self.frame.y = targetFrameY
            end
        end
    end
end

function ZoomScroller:followTrackedMote()
    if self.trackedMote then
        local zoomedPos = self:getZoomedPosition(self.trackedMote.position)
        
            local screenCenterX, screenCenterY = WIDTH / 2, HEIGHT / 2
            local offsetX = screenCenterX - zoomedPos.x
            local offsetY = screenCenterY - zoomedPos.y
            
            local targetFrameX = self.frame.x + offsetX
            local targetFrameY = self.frame.y + offsetY
            
            -- Calculate total offset distance
            local totalOffset = math.abs(offsetX) + math.abs(offsetY)
            
            -- Adjust the movement threshold and lerp factor as needed
            local movementThreshold = 80
            local lerpFactor = 0.1  -- How quickly the frame catches up to the mote, 0 to 1
            
            if totalOffset > movementThreshold then
                -- For larger movements, use tween for a smooth transition
                if not self.isTweening then
                    if self.trackingTween then
                        tween.stop(self.trackingTween)
                    end
                    
                    self.isTweening = true
                    self.trackingTween = tween(0.5, self.frame, {x = targetFrameX, y = targetFrameY}, tween.easing.cubicInOut, function()
                        self.isTweening = false
                    end)
                end
            else
                -- For smaller, continuous adjustments, use linear interpolation instead of tweening
                self.frame.x = self.frame.x + (targetFrameX - self.frame.x) * lerpFactor
                self.frame.y = self.frame.y + (targetFrameY - self.frame.y) * lerpFactor
            end
        end
end

function ZoomScroller:followTrackedMote()
    if self.trackedMote then
        local zoomedPos = self:getZoomedPosition(self.trackedMote.position)
        
        -- Check if the tracked mote has changed since the last update
        local hasMoteChanged = self.lastTrackedMote ~= self.trackedMote
        self.lastTrackedMote = self.trackedMote  -- Update the reference to the currently tracked mote
        
        local screenCenterX, screenCenterY = WIDTH / 2, HEIGHT / 2
        local offsetX = screenCenterX - zoomedPos.x
        local offsetY = screenCenterY - zoomedPos.y
        
        local targetFrameX = self.frame.x + offsetX
        local targetFrameY = self.frame.y + offsetY
        
        -- Calculate total offset distance
        local totalOffset = math.abs(offsetX) + math.abs(offsetY)
        
        -- Adjust the movement threshold and lerp factor as needed
        local movementThreshold = 80
        local lerpFactor = 0.1  -- How quickly the frame catches up to the mote, 0 to 1
        
        if hasMoteChanged and totalOffset > movementThreshold then
            -- For larger movements due to a change in the tracked mote, use tween for a smooth transition
            if not self.isTweening then
                if self.trackingTween then
                    tween.stop(self.trackingTween)
                end
                
                self.isTweening = true
                self.trackingTween = tween(0.5, self.frame, {x = targetFrameX, y = targetFrameY}, tween.easing.cubicInOut, function()
                    self.isTweening = false
                end)
            end
        else
            -- For smaller, continuous adjustments or when the mote hasn't changed, use linear interpolation
            self.frame.x = self.frame.x + (targetFrameX - self.frame.x) * lerpFactor
            self.frame.y = self.frame.y + (targetFrameY - self.frame.y) * lerpFactor
        end
    end
end


function ZoomScroller:followTrackedMote()
    if self.trackedMote then
        local zoomedPos = self:getZoomedPosition(self.trackedMote.position)
    
        -- Use the mote's absolute position directly for wrap detection
        local currentAbsolutePos = self.trackedMote.position
        
        -- Check if the tracked mote has changed since the last update or if there's been a significant jump
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
        
        -- Calculate total offset distance
        local totalOffset = math.abs(offsetX) + math.abs(offsetY)
        
        -- Adjust the movement threshold and lerp factor as needed
        local movementThreshold = 80
        local lerpFactor = 0.1  -- How quickly the frame catches up to the mote, 0 to 1
        
        if hasMoteChanged and totalOffset > movementThreshold then
            -- For larger movements due to a change in the tracked mote 
            if not self.isTweening then
                if self.trackingTween then
                    tween.stop(self.trackingTween)
                end
                
                self.isTweening = true
                self.trackingTween = tween(0.5, self.frame, {x = targetFrameX, y = targetFrameY}, tween.easing.cubicInOut, function()
                    self.isTweening = false
                end)
            end
        elseif hasJumped then 
            print("hasJumped")
            -- don't use lerp on a sudden jump (screen-wrapping)
            self.frame.x = targetFrameX 
            self.frame.y = targetFrameY 
        else
            -- For smaller, continuous adjustments or when there hasn't been a significant change, use linear interpolation
            self.frame.x = self.frame.x + (targetFrameX - self.frame.x) * lerpFactor
            self.frame.y = self.frame.y + (targetFrameY - self.frame.y) * lerpFactor
        end
    end
end

function ZoomScroller:followTrackedMote()
    if self.trackedMote then
        local zoomedPos = self:getZoomedPosition(self.trackedMote.position)
        
        -- Use the mote's absolute position directly for wrap detection
        local currentAbsolutePos = self.trackedMote.position
        
        -- Check if the tracked mote has changed since the last update or if there's been a significant jump
        local hasMoteChanged = self.lastTrackedMote ~= self.trackedMote
        local hasJumped = false
        if self.lastAbsolutePos and currentAbsolutePos then
            local jumpX = math.abs(currentAbsolutePos.x - self.lastAbsolutePos.x)
            local jumpY = math.abs(currentAbsolutePos.y - self.lastAbsolutePos.y)
            hasJumped = jumpX > WIDTH * 0.9 or jumpY > HEIGHT * 0.9
        end
        
        --*also track last relative position?
        
        self.lastTrackedMote = self.trackedMote
        self.lastAbsolutePos = currentAbsolutePos
        
        -- Calculate the center of the screen
        local screenCenterX, screenCenterY = WIDTH / 2, HEIGHT / 2
        
        -- Calculate the offsets needed to move the tracked mote to the screen center
        local offsetX = screenCenterX - zoomedPos.x
        local offsetY = screenCenterY - zoomedPos.y
        
        -- Determine the target position for the frame
        local targetFrameX = self.frame.x + offsetX
        local targetFrameY = self.frame.y + offsetY
        
        -- Calculate the total offset distance to decide on the adjustment method
        local totalOffset = math.abs(offsetX) + math.abs(offsetY)
        
        -- Set thresholds for movement and lerp factor for smooth adjustments
        local movementThreshold = 80
        local lerpFactor = 0.1
        
        if hasMoteChanged and totalOffset > movementThreshold then
            -- Large movement due to mote change: apply smooth transition using tween
            if not self.isTweening then
                if self.trackingTween then
                    tween.stop(self.trackingTween)
                end
                
                self.isTweening = true
                self.trackingTween = tween(0.5, self.frame, {x = targetFrameX, y = targetFrameY}, tween.easing.cubicInOut, function()
                    self.isTweening = false
                end)
            end
        elseif hasJumped then
            -- Handle screen wrapping by adjusting directly without interpolation
            --*use tracked relative position to include offset here?
            self.frame.x = targetFrameX 
            self.frame.y = targetFrameY 
        else
            -- Small, continuous adjustments: use linear interpolation
            self.frame.x = self.frame.x + (targetFrameX - self.frame.x) * lerpFactor
            self.frame.y = self.frame.y + (targetFrameY - self.frame.y) * lerpFactor
        end
    end
end



function ZoomScroller:followTrackedMote()
    if self.trackedMote then
        local zoomedPos = self:getZoomedPosition(self.trackedMote.position)
        
        -- Use the mote's absolute position directly for wrap detection
        local currentAbsolutePos = self.trackedMote.position
        
        -- Check if the tracked mote has changed since the last update or if there's been a significant jump
        local hasMoteChanged = self.lastTrackedMote ~= self.trackedMote
        local hasJumped = false
        if self.lastAbsolutePos and currentAbsolutePos then
            local jumpX = math.abs(currentAbsolutePos.x - self.lastAbsolutePos.x)
            local jumpY = math.abs(currentAbsolutePos.y - self.lastAbsolutePos.y)
            hasJumped = jumpX > WIDTH * 0.9 or jumpY > HEIGHT * 0.9
        end
        
        -- Track last relative position
        self.lastRelativePos = self.lastRelativePos or zoomedPos
        
        self.lastTrackedMote = self.trackedMote
        self.lastAbsolutePos = currentAbsolutePos
        
        -- Calculate the center of the screen
        local screenCenterX, screenCenterY = WIDTH / 2, HEIGHT / 2
        
        -- Calculate the offsets needed to move the tracked mote to the screen center
        local offsetX = screenCenterX - zoomedPos.x
        local offsetY = screenCenterY - zoomedPos.y
        
        -- Determine the target position for the frame
        local targetFrameX = self.frame.x + offsetX
        local targetFrameY = self.frame.y + offsetY
        
        -- Calculate the total offset distance to decide on the adjustment method
        local totalOffset = math.abs(offsetX) + math.abs(offsetY)
        
        -- Set thresholds for movement and lerp factor for smooth adjustments
        local movementThreshold = 80
        local lerpFactor = 0.1
        
        if hasMoteChanged and totalOffset > movementThreshold then
            -- Large movement due to mote change: apply smooth transition using tween
            if not self.isTweening then
                if self.trackingTween then
                    tween.stop(self.trackingTween)
                end
                
                self.isTweening = true
                self.trackingTween = tween(0.5, self.frame, {x = targetFrameX, y = targetFrameY}, tween.easing.cubicInOut, function()
                    self.isTweening = false
                end)
            end
        elseif hasJumped then
            -- Use tracked relative position to include offset here
            local relativeOffsetX = zoomedPos.x - self.lastRelativePos.x
            local relativeOffsetY = zoomedPos.y - self.lastRelativePos.y
            self.frame.x = self.frame.x + relativeOffsetX
            self.frame.y = self.frame.y + relativeOffsetY
        else
            -- Small, continuous adjustments: use linear interpolation
            self.frame.x = self.frame.x + (targetFrameX - self.frame.x) * lerpFactor
            self.frame.y = self.frame.y + (targetFrameY - self.frame.y) * lerpFactor
        end
        
        -- Update the last relative position after all calculations
        self.lastRelativePos = zoomedPos
    end
end

function ZoomScroller:followTrackedMote()
    if self.trackedMote then
        local zoomedPos = self:getZoomedPosition(self.trackedMote.position)
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
        local movementThreshold = 80
        local lerpFactor = 0.1
        
        if hasMoteChanged and totalOffset > movementThreshold then
            if not self.isTweening then
                if self.trackingTween then tween.stop(self.trackingTween) end
                self.isTweening = true
                self.trackingTween = tween(0.5, self.frame, {x = targetFrameX, y = targetFrameY}, tween.easing.cubicInOut, function() self.isTweening = false end)
            end
        elseif hasJumped then
            -- When a jump occurs, directly set the frame's position to maintain the offset
            print("hasJumped")
            self.frame.x = targetFrameX -- Apply the calculated offset
            self.frame.y = targetFrameY -- Apply the calculated offset
        else
            -- Linear interpolation for smooth following
            self.frame.x = self.frame.x + (targetFrameX - self.frame.x) * lerpFactor
            self.frame.y = self.frame.y + (targetFrameY - self.frame.y) * lerpFactor
        end
    end
end

function ZoomScroller:followTrackedMote()
    if self.trackedMote then
        local zoomedPos = self:getZoomedPosition(self.trackedMote.position)
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
        local movementThreshold = 80
        local lerpFactor = 0.1
        
        if hasMoteChanged and totalOffset > movementThreshold then
            if not self.isTweening then
                if self.trackingTween then tween.stop(self.trackingTween) end
                self.isTweening = true
                self.trackingTween = tween(0.5, self.frame, {x = targetFrameX, y = targetFrameY}, tween.easing.cubicInOut, function() self.isTweening = false end)
            end
        elseif hasJumped then
            -- When a jump occurs, directly set the frame's position to maintain the offset
            self.frame.x = self.trackedMote.position.x + offsetX -- Apply the calculated offset
            self.frame.y = self.trackedMote.position.y + offsetY -- Apply the calculated offset
            self.frame.x = targetFrameX -- Apply the calculated offset
            self.frame.y = targetFrameY -- Apply the calculated offset


            local screenCenterX, screenCenterY = WIDTH / 2, HEIGHT / 2
            local zoomedCenter = self:getZoomedPosition(vec2(screenCenterX, screenCenterY))
            local zoomedPos = self:getZoomedPosition(self.trackedMote.position)
            local offsetX = zoomedCenter.x - zoomedPos.x
            local offsetY = zoomedCenter.y - zoomedPos.y
            print("hasJumped: ", zoomedCenter, zoomedPos, self.trackedMote.position)
            --[[
            self.frame.x = targetFrameX + offsetX-- Apply the calculated offset
            self.frame.y = targetFrameY + offsetY-- Apply the calculated offset
            ]]
        else
            -- Linear interpolation for smooth following
            self.frame.x = self.frame.x + (targetFrameX - self.frame.x) * lerpFactor
            self.frame.y = self.frame.y + (targetFrameY - self.frame.y) * lerpFactor
        end
    end
end


function ZoomScroller:followTrackedMote()
    if self.trackedMote then
        local zoomedPos = self:getZoomedPosition(self.trackedMote.position)
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
        local lerpFactor = 0.8
        
        if hasMoteChanged and totalOffset > movementThreshold then
            if not self.isTweening then
                if self.trackingTween then tween.stop(self.trackingTween) end
                self.isTweening = true
                self.trackingTween = tween(0.5, self.frame, {x = targetFrameX, y = targetFrameY}, tween.easing.cubicInOut, function() self.isTweening = false end)
            end
        elseif hasJumped or totalOffset < 2 then
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