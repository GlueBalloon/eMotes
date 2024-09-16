

function draw()
    pushStyle()
    background(40, 40, 50)
    spriteMode(CENTER)
    
    tint(148, 162, 223)
    sprite(bgImage, WIDTH/2, HEIGHT/2, WIDTH, HEIGHT)
    noTint()

    -- Update frame count
    frameCount = frameCount + 1
    if ElapsedTime - lastTime >= 1 then
        fps = frameCount / (ElapsedTime - lastTime)
        frameCount = 0
        lastTime = ElapsedTime
    end
    
    motesDrawn = 0
    motesNotDrawn = 0
    local shouldMove = not (isPaused and isPaused.forRecording)
    -- Clear the nextGrid for the next frame
    nextGrid = {}
    
    if shouldMove then
        updateWindDirection()
    end
    
    local frame = zoomScroller.frame

    if zoomActive then
        zoomScroller:updateMapping(frame)
    end
    
    for i, mote in ipairs(motes) do
        if shouldMove then
            updateGrid(mote, nextGrid)
            checkForNeighbors(mote, currentGrid)  -- Pass currentGrid for neighbor checking
            mote:update()
        end
        if zoomActive then
            mote.drawingParams = zoomScroller:getDrawingParameters(mote.position, mote.size)
            if mote.drawingParams then
                if zoomScroller.trackedMote == mote then
                    highlightTrackedMote(mote)
                end
                mote:drawFromParams()
                motesDrawn = motesDrawn + 1
            else
                motesNotDrawn = motesNotDrawn + 1
            end
        else 
            mote:draw()
        end
    end
    
    -- Update the frame to follow the tracked mote, if it exists
    if zoomActive and zoomScroller.trackedMote and shouldMove then
        zoomScroller:followTrackedMote()
    end
    
    popStyle()
    
    currentGrid, nextGrid = nextGrid, currentGrid
end

---- Define emoji categories with sounds as tables

-- Function to pick a random category
local function pickRandomCategory()
    local keys = {}
    for key, _ in pairs(categories) do
        table.insert(keys, key)
    end
    local category = keys[math.random(#keys)]
    return category
end

-- Function to pick a random emoji and sound from the selected category
local function pickEmojiAndSound(category)
    if category == "SpecialCases" then
        local customKeys = {}
        for key, _ in pairs(categories[category].customSounds) do
            table.insert(customKeys, key)
        end
        local emoji = customKeys[math.random(#customKeys)]
        local soundOptions = categories[category].customSounds[emoji]
        local sound = soundOptions[math.random(#soundOptions)]
        return emoji, sound
    else
        print(category)
        local emojis = categories[category].emojis
        local emoji = emojis[math.random(#emojis)]
        local soundOptions = categories[category].sounds
        local sound = soundOptions[math.random(#soundOptions)]
        return emoji, sound
    end
end

function ZoomScroller:tapCallback(event)
    isPaused = nil
    self.trackedMote = nil
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
    if moteTapped and not moteTapped.tappedTween then
        -- Start the visual feedback for tapping
        local lineLength = moteTapped.drawingParams.size * 0.1
        local lineWidth = 2
        local duration = 0.25
        local function updateFunc(progress)
            self:drawSurpriseLines(moteTapped, lineLength, lineWidth, progress)
        end
        tweenWithUpdates(duration, updateFunc, completeFunc)
        
        -- Define the size pop effect
        local originalSize = moteTapped.size
        local popSize = originalSize * 1.5 -- Increase to 150% of original size
        local duration = 0.4 -- Duration of the pop effect
        
        -- Tween for the pop effect
        moteTapped.tappedTween = tween(duration, moteTapped, {size = popSize}, tween.easing.backOut, function()
            -- After popping, bounce back to the original size
            tween(duration, moteTapped, {size = originalSize}, tween.easing.backIn, function()
                moteTapped.tappedTween = nil
            end)
        end)

        
        -- New logic to select a category, then an emoji and its sound
        local category = pickRandomCategory() -- Assuming this function is globally available
        local originalEmoji = moteTapped.defaultEmoji
        -- Force category if special-case emoji
        if moteTapped.emoji == "🥶" then category = "TooCold"
        elseif moteTapped.emoji == "🥵" then category = "TooHot" end

        local newEmoji, soundPath = pickEmojiAndSound(category) -- Assuming this function is globally available
        moteTapped.defaultEmoji = newEmoji -- Temporarily change to a new emoji
        
        -- Play the sound with pitch variation
        if soundPath then
            local pitchVariation = math.random(110, 140) / 100 -- Random pitch between 0.8 and 1.2
            sound(soundPath, 1, pitchVariation)
           -- sound(asset.downloaded.Game_Sounds_One.Female_Grunt_5, 1, pitchVariation) --for testing
        end
        
        -- Schedule to change back after a delay
        tween.delay(0.8, function()
            moteTapped.defaultEmoji = originalEmoji
        end)
    end
    if moteTapped and not moteTapped.isAnimating then
        -- Update or reset tap count based on the time elapsed since the last tap
        if moteTapped.lastTapTime ~= 0 and (ElapsedTime - moteTapped.lastTapTime < 1.5) then
            moteTapped.tapCount = moteTapped.tapCount + 1
        else
            moteTapped.tapCount = 1  -- Reset tap count if too much time has passed
        end
        
        moteTapped.lastTapTime = ElapsedTime  -- Update the last tap time to the current time
        
        -- Check tap count thresholds for different states or actions
        if moteTapped.tapCount == 3 then
            moteTapped.state = "grrrr"
            moteTapped.emoji = "😠"  -- Change to grrrr face
        elseif moteTapped.tapCount >= 4 then
            -- Initiate rage mode behavior when tap count reaches or exceeds 3
            moteTapped.state = "rage"
            moteTapped:startRageMode()
            moteTapped.tapCount = 0  -- Optionally reset tap count after triggering rage mode
        end
    end
end