
---Sound Effects from <a href="https://pixabay.com/?utm_source=link-attribution&utm_medium=referral&utm_campaign=music&utm_content=99409">Pixabay</a>
---yeehaw by Sound Effect by <a href="https://pixabay.com/users/tygger281-14052289/?utm_source=link-attribution&utm_medium=referral&utm_campaign=music&utm_content=13229">Virginia Dickenson</a> from <a href="https://pixabay.com//?utm_source=link-attribution&utm_medium=referral&utm_campaign=music&utm_content=13229">Pixabay</a>
---Sound Effect by <a href="https://pixabay.com/users/sergequadrado-24990007/?utm_source=link-attribution&utm_medium=referral&utm_campaign=music&utm_content=123862">Sergei Chetvertnykh</a> from <a href="https://pixabay.com//?utm_source=link-attribution&utm_medium=referral&utm_campaign=music&utm_content=123862">Pixabay</a>
--[[
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
        
        local originalEmoji = moteTapped.defaultEmoji
        local newEmoji = moteTapped:randomStandardEmoji()
        moteTapped.defaultEmoji = newEmoji -- Temporarily change to a new emoji
        
        -- Determine sound based on the new emoji's set
        local soundToPlay = self:determineSoundForEmoji(newEmoji)
        soundToPlay = asset.downloaded.A_Hero_s_Quest.Broke
        soundToPlay = true
        if soundToPlay then
            local thing = sound(asset.downloaded.Game_Sounds_One.Bell_2) -- Play the sound (assuming a 'sound' function or similar API)
            print(thing)
        end
        
        -- Schedule to change back after 2 seconds
        tween.delay(0.8, function()
            moteTapped.defaultEmoji = originalEmoji
        end)
    end
end
]]

function ZoomScroller:determineSoundForEmoji(emoji)
    -- Return a sound file path or identifier based on the emoji's set
    -- Example:
    if happyJoyfulSet and happyJoyfulSet[emoji] then
        return "path/to/happy_sound.wav"
    elseif curiousThoughtfulSet and curiousThoughtfulSet[emoji] then
        return "path/to/curious_sound.wav"
        -- Continue for other sets
    end
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
        
        stroke(attribute.color[1], attribute.color[2], attribute.color[3], alpha)
        strokeWidth(lineWidth)
        line(startX, startY, endX, endY)
    end
    
    if progress >= 1 then
        self.lineAttributes = nil -- Reset attributes at the end of the animation
    end
    
    popStyle()
end

function draw()
    
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
    pushStyle()
    background(40, 40, 50)
    spriteMode(CENTER)
    
    tint(148, 162, 223)
    sprite(bgImage, WIDTH/2, HEIGHT/2, WIDTH, HEIGHT)
    noTint()
    
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

function ZoomScroller:longPressCallback(event)
    isPaused = { forRecording = true }
    local moteTapped = self:detectMoteUnderTouch(event)
    if moteTapped then
        -- Set the app to a paused state specifically for recording
        print("Long-pressed on mote for recording:", moteTapped.emoji or "no emoji", "at:", moteTapped.position.x, moteTapped.position.y)
        -- Additional logic for showing recording UI and handling recording can be added here
    else
     --   isPaused = nil
    end
end

function ZoomScroller:detectMoteUnderTouch(event)
    local absX, absY = self:zoomedPosToAbsolutePos(event.x, event.y)
    if not absX or not absY then return nil end -- Early exit if conversion failed
    
    local gridX = math.floor(absX / gridSize) + 1
    local gridY = math.floor(absY / gridSize) + 1
    
    local motesInCell = currentGrid[gridX] and currentGrid[gridX][gridY]
    if motesInCell then
        for _, mote in ipairs(motesInCell) do
            local dp = mote.drawingParams
            if dp and event.x >= (dp.x - dp.size / 2) and event.x <= (dp.x + dp.size / 2) and event.y >= (dp.y - dp.size / 2) and event.y <= (dp.y + dp.size / 2) then
                return mote
            end
        end
    end
    return nil
end

---- Define emoji categories with sounds as tables
local categories = {
    HappyJoyful = {
        emojis = {"😀", "😃", "😄", "🙃", "🙂", "😏", "😁", "😆", "😅", "😊", "😇", "😉", "😌", "🤭", "😋", "😛", "😝", "😜", "🤪", "🤓", "😎", "😙", "😚"},
        sounds = {"happy_sound1.mp3"} -- Add more sounds as needed
    },
    CuriousThoughtful = {
        emojis = {"🤨", "🧐", "🤔", "😗"},
        sounds = {"curious_sound1.mp3"} -- Add more sounds as needed
    },
    -- Define other categories similarly
    SpecialCases = {
        customSounds = {
            ["🤠"] = {"yeehaw_sound.mp3"},
            ["👻"] = {"boo_sound.mp3"},
            ["🤖"] = {"robot_sound.mp3"},
            ["👽"] = {"alien_sound.mp3"}
        }
    }
}

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
    if moteTapped then
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
        local popSize = originalSize * 2 -- Increase to 150% of original size
        local duration = 0.4 -- Duration of the pop effect
        
        -- Tween for the pop effect
        tween(duration, moteTapped, {size = popSize}, tween.easing.backOut, function()
            -- After popping, bounce back to the original size
            tween(duration, moteTapped, {size = originalSize}, tween.easing.backIn)
        end)

        
        -- New logic to select a category, then an emoji and its sound
        local category = pickRandomCategory() -- Assuming this function is globally available
        local originalEmoji = moteTapped.defaultEmoji
        local newEmoji, soundPath = pickEmojiAndSound(category) -- Assuming this function is globally available
        moteTapped.defaultEmoji = newEmoji -- Temporarily change to a new emoji
        
        -- Play the sound with pitch variation
        if soundPath then
            local pitchVariation = math.random(110, 140) / 100 -- Random pitch between 0.8 and 1.2
            --sound(asset.documents.Dropbox[soundPath], 1, pitchVariation)
            sound(asset.downloaded.Game_Sounds_One.Female_Grunt_5, 1, pitchVariation) --for testing
        end
        
        -- Schedule to change back after a delay
        tween.delay(0.8, function()
            moteTapped.defaultEmoji = originalEmoji
        end)
    end
end