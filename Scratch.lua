

function ZoomScroller:tapCallback(event)
    -- Convert the zoomed position to an absolute position
    local absX, absY = self:zoomedPosToAbsolutePos(event.x, event.y)
    if not absX or not absY then return end -- Early exit if conversion failed
    
    -- Calculate the grid cell coordinates
    local gridX = math.floor(absX / gridSize) + 1
    local gridY = math.floor(absY / gridSize) + 1
    
    -- Access the motes in the identified grid cell
    local motesInCell = currentGrid[gridX] and currentGrid[gridX][gridY]
    local moteTapped = nil
    if motesInCell then
        for _, mote in ipairs(motesInCell) do
            -- Check if the mote's drawingParams place it under the tap
            local dp = mote.drawingParams
            
            if dp then
                local left = dp.x - dp.size / 2
                local right = dp.x + dp.size / 2
                local bottom = dp.y - dp.size / 2
                local top = dp.y + dp.size / 2
                
                if event.x >= left and event.x <= right and event.y >= bottom and event.y <= top then
                    print("Tapped on mote:", mote.emoji or "no emoji", "at:", dp.x, dp.y)
                    moteTapped = mote
                    break
                end
            end
        end
    end
    if moteTapped then
        local lineLength = moteTapped.drawingParams.size * 0.1
        local lineWidth = 2
        local duration = 0.25
        
        -- Define the update function to be called each frame
        local function updateFunc(progress)
            self:drawSurpriseLines(moteTapped, lineLength, lineWidth, progress)
        end   
        -- Start the tween with per-frame updates
        tweenWithUpdates(duration, updateFunc, completeFunc)
    end
    self.trackedMote = nil
end

-- General function to create a tween that calls an update function every frame
function tweenWithUpdates(duration, updateFunc, completeFunc)
    local elapsedTime = 0
    local function loop()
        if elapsedTime < duration then
            elapsedTime = elapsedTime + 1/60 -- Assuming 60 FPS
            updateFunc(elapsedTime / duration) -- Call the update function with progress
            tween.delay(1/60, loop)
        else
            if completeFunc then completeFunc() end -- Call the completion function if provided
        end
    end
    loop() -- Start the loop
end

-- Enhanced initialization for line colors and lengths
function ZoomScroller:initializeLineAttributes(numLines, baseLineLength)
    self.lineAttributes = {}
    for i = 1, numLines do
        -- Random color for each line
        local color = {
            math.random(0, 255),
            math.random(0, 255),
            math.random(0, 255)
        }
        -- Random length for each line, between baseLineLength and twice the baseLineLength
        local length = baseLineLength + math.random() * baseLineLength * 1.5
        
        self.lineAttributes[i] = {color = color, length = length}
    end
end

function ZoomScroller:drawSurpriseLines(mote, baseLineLength, lineWidth, progress)
    if not self.lineAttributes then
        self:initializeLineAttributes(15, baseLineLength) -- Initialize if not yet initialized
    end
    
    pushStyle()
    local dp = mote.drawingParams
    local numLines = 15
    local angleStep = (math.pi * 2) / numLines
    local startOffset = 2 -- Start 2 pixels away from the circumference
    local endOffset = 17 -- End 17 pixels away from the circumference
    local offset = startOffset + (endOffset - startOffset) * progress
    local alpha = 255 * (1 - progress) -- Fade out the lines
    
    local startPointRadius = (dp.size / 2) + offset
    
    for i = 1, numLines do
        local angle = i * angleStep
        local attribute = self.lineAttributes[i]
        local startX = dp.x + startPointRadius * math.cos(angle)
        local startY = dp.y + startPointRadius * math.sin(angle)
        local endX = startX + attribute.length * math.cos(angle)
        local endY = startY + attribute.length * math.sin(angle)
        
      --  stroke(attribute.color[1], attribute.color[2], attribute.color[3], alpha)
        stroke(255, 215, 0, alpha) -- Gold color with fading
        strokeWidth(lineWidth)
        line(startX, startY, endX, endY)
    end
    
    if progress >= 1 then
        self.lineAttributes = nil -- Reset attributes at the end of the animation
    end
    
    popStyle()
end

-- Simplified initialization for line lengths only
function ZoomScroller:initializeLineAttributes(numLines, baseLineLength)
    self.lineAttributes = {}
    for i = 1, numLines do
        -- Random length for each line, between baseLineLength and 1.5 times the baseLineLength
        local length = baseLineLength + math.random() * baseLineLength * 1.5
        self.lineAttributes[i] = {length = length}
    end
end

function ZoomScroller:drawSurpriseLines(mote, baseLineLength, lineWidth, progress)
    if not self.lineAttributes then
        self:initializeLineAttributes(15, baseLineLength) -- Initialize if not yet initialized
    end
    
    pushStyle()
    local dp = mote.drawingParams
    local numLines = 15
    local angleStep = (math.pi * 2) / numLines
    local startOffset = 2
    local endOffset = 17
    local offset = startOffset + (endOffset - startOffset) * progress
    local alpha = 255 * (1 - progress) -- Fade out the lines
    
    local startPointRadius = (dp.size / 2) + offset
    
    for i = 1, numLines do
        local angle = i * angleStep
        local attribute = self.lineAttributes[i]
        local startX = dp.x + startPointRadius * math.cos(angle)
        local startY = dp.y + startPointRadius * math.sin(angle)
        local endX = startX + attribute.length * math.cos(angle)
        local endY = startY + attribute.length * math.sin(angle)
        
        stroke(255, 215, 0, alpha) -- Gold color with fading
        strokeWidth(lineWidth)
        line(startX, startY, endX, endY)
    end
    
    if progress >= 1 then
        self.lineAttributes = nil -- Reset attributes at the end of the animation
    end
    
    popStyle()
end










