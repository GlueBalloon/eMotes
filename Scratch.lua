

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

function emptyNonsenseICantDeleteWithoutCrashes(event)

end