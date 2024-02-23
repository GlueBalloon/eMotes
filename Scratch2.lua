function ZoomScroller:calculateTileRanges(frame)
    local tilesX = math.ceil(WIDTH / frame.width)
    local tilesY = math.ceil(HEIGHT / frame.height)
    return tilesX, tilesY
end

function ZoomScroller:calculateTileStartPoints(frame, i, j)
    local startX = frame.x + (i * frame.width) - frame.width / 2
    local startY = frame.y + (j * frame.height) - frame.height / 2
    return startX, startY
end

function ZoomScroller:defineVisibleAreaBounds(startX, startY, frame)
    local left = startX
    local right = startX + frame.width
    local top = startY + frame.height
    local bottom = startY
    return left, right, top, bottom
end

function ZoomScroller:ensureVisibleAreaWithinScreenBounds(left, right, top, bottom)
    local visibleArea = {
        left = math.max(left, 0),
        right = math.min(right, WIDTH),
        top = math.min(top, HEIGHT),
        bottom = math.max(bottom, 0),
    }
    return visibleArea
end

function ZoomScroller:calculateRatioForVisibleArea(visibleArea, frame, startX, startY)
    local ratio = {
        leftRatio = (visibleArea.left - startX) / frame.width,
        rightRatio = (startX + frame.width - visibleArea.right) / frame.width,
        topRatio = (startY + frame.height - visibleArea.top) / frame.height,
        bottomRatio = (visibleArea.bottom - startY) / frame.height,
    }
    return ratio
end

function ZoomScroller:combinedVisibleAreasWithRatios(frame)
    local tilesX, tilesY = self:calculateTileRanges(frame)
    local frameAreasFillingScreen = {}
    local areasAsRatiosOfFrame = {}
    
    for i = -1, tilesX do
        for j = -1, tilesY do
            local startX, startY = self:calculateTileStartPoints(frame, i, j)
            local left, right, top, bottom = self:defineVisibleAreaBounds(startX, startY, frame)
            local frameArea = self:ensureVisibleAreaWithinScreenBounds(left, right, top, bottom)
            if right > 0 and left < WIDTH and bottom < HEIGHT and top > 0 then
                local ratio = self:calculateRatioForVisibleArea(frameArea, frame, startX, startY)
                table.insert(frameAreasFillingScreen, frameArea)
                table.insert(areasAsRatiosOfFrame, ratio)
            end
        end
    end
    
    return frameAreasFillingScreen, areasAsRatiosOfFrame
end

function ZoomScroller:combinedVisibleRatiosAndFrameRatios(frame)
    local tilesX, tilesY = self:calculateTileRanges(frame)
    local visibleOnscreenRatios = {} -- Renamed and repurposed to store ratios of screen
    local frameRatios = {} -- Stays as is, for storing areas as ratios of the frame
    
    for i = -1, tilesX do
        for j = -1, tilesY do
            local startX, startY = self:calculateTileStartPoints(frame, i, j)
            local left, right, top, bottom = self:defineVisibleAreaBounds(startX, startY, frame)
            local frameArea = self:ensureVisibleAreaWithinScreenBounds(left, right, top, bottom)
            if right > 0 and left < WIDTH and bottom < HEIGHT and top > 0 then
                -- Calculate and store the area as ratios of the screen, instead of direct coordinates
                local screenRatio = self:convertVisibleAreaToScreenRatio(frameArea, frame) -- Hypothetical function
                local frameRatio = self:calculateRatioForVisibleArea(frameArea, frame, startX, startY)
                
                table.insert(visibleOnscreenRatios, screenRatio)
                table.insert(frameRatios, frameRatio)
            end
        end
    end
    
    return visibleOnscreenRatios, areasAsRatiosOfFrame
end

function ZoomScroller:convertVisibleAreaToScreenRatio(visibleArea)
    -- Ensure WIDTH and HEIGHT are defined as the screen's width and height.
    local screenWidth = WIDTH
    local screenHeight = HEIGHT

    -- Calculate the ratio of each side of the visible area to the screen dimensions.
    local screenRatio = {
        leftRatio = visibleArea.left / screenWidth,
        rightRatio = (screenWidth - visibleArea.right) / screenWidth,
        topRatio = (screenHeight - visibleArea.top) / screenHeight,
        bottomRatio = visibleArea.bottom / screenHeight,
    }

    return screenRatio
end

function testComparisonOfCombinedAndOriginalFunction()
    local zoomScroller = ZoomScroller()
    local frame = {x = WIDTH / 2, y = HEIGHT / 2, width = WIDTH / 2, height = HEIGHT / 2}

    local originalVisibleAreas, originalVisibleAreaRatios = zoomScroller:visibleAreasWithRatios89(frame)
    local combinedVisibleAreas, combinedVisibleAreaRatios = zoomScroller:combinedVisibleAreasWithRatios(frame)

    -- Test for matching number of visible areas
    if #originalVisibleAreas == #combinedVisibleAreas then
        print("Success: Number of visible areas matches.")
    else
        print("Error: Mismatch in number of visible areas.")
    end

    -- Test for matching number of visible area ratios
    if #originalVisibleAreaRatios == #combinedVisibleAreaRatios then
        print("Success: Number of visible area ratios matches.")
    else
        print("Error: Mismatch in number of visible area ratios.")
    end

    -- Example of a deeper comparison, comparing the first ratio table of both methods
    if #originalVisibleAreaRatios > 0 and #combinedVisibleAreaRatios > 0 then
        local originalRatio = originalVisibleAreaRatios[1]
        local combinedRatio = combinedVisibleAreaRatios[1]
        local allMatch = true
        for key, value in pairs(originalRatio) do
            if combinedRatio[key] ~= value then
                print("Error: Mismatch in ratio values for key: " .. key)
                allMatch = false
                break
            end
        end
        if allMatch then
            print("Success: First ratio table values match.")
        end
    else
        print("Error: One of the ratio tables is empty.")
    end
end

function testConvertVisibleAreaToScreenRatio()
    -- Mock frame and visible area
    local zoomScroller = ZoomScroller()
    local frame = {x = 150, y = 150, width = 300, height = 300} -- Example frame
    local visibleArea = {left = 50, right = 250, top = 250, bottom = 50} -- Example visible area within the screen

    -- Expected ratio results, calculated manually or through expected logic for this test
    local expectedRatio = {
        leftRatio = 50 / WIDTH,
        rightRatio = (WIDTH - 250) / WIDTH,
        topRatio = (HEIGHT - 250) / HEIGHT,
        bottomRatio = 50 / HEIGHT,
    }

    -- Call the hypothetical function
    local screenRatio = zoomScroller:convertVisibleAreaToScreenRatio(visibleArea, frame)

    -- Check if the calculated ratios match the expected ratios
    assert(math.abs(screenRatio.leftRatio - expectedRatio.leftRatio) < 0.01, "Left ratio mismatch")
    assert(math.abs(screenRatio.rightRatio - expectedRatio.rightRatio) < 0.01, "Right ratio mismatch")
    assert(math.abs(screenRatio.topRatio - expectedRatio.topRatio) < 0.01, "Top ratio mismatch")
    assert(math.abs(screenRatio.bottomRatio - expectedRatio.bottomRatio) < 0.01, "Bottom ratio mismatch")

    print("Test passed: convertVisibleAreaToScreenRatio correctly translates the frameArea.")
end


