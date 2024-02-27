
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