MOTE_SIZE = 2.5
MOTE_COUNT = 3000
TIMESCALE = 1
WIND_ANGLE = 0
MOTE_SPEED_DEFAULT = 0.25
BASE_EMOJI_SIZE = MOTE_SIZE  -- Initial guess for text size
ZOOM_THRESHOLD = 1.7  -- Threshold for switching to emote drawing
-- Global variables
motes = {}
currentGrid = {}
nextGrid = {}
gridSize = 10  -- Adjust this value as needed
zoomLevel = 1.0
zoomOrigin = vec2(WIDTH / 2, HEIGHT / 2)
emojiSize = BASE_EMOJI_SIZE
lastTime = ElapsedTime
frameCount = 0
fps = 0
motesDrawn = 0
motesNotDrawn = 0

-- Function to check if a mote is visible on screen
function isMoteVisible(mote)
    -- Calculate the transformed position
    local transformedX = (mote.position.x - zoomOrigin.x) * zoomLevel + zoomOrigin.x
    local transformedY = (mote.position.y - zoomOrigin.y) * zoomLevel + zoomOrigin.y
    
    -- Check if the transformed position is within screen bounds
    return transformedX >= 0 and transformedX <= WIDTH and transformedY >= 0 and transformedY <= HEIGHT
end

-- Function to calculate appropriate text size for emotes
function calculateTextSize()
    local targetWidth = MOTE_SIZE
    local currentWidth = 0
    local emote = "😀"  -- Example emote
    
    fontSize(BASE_EMOJI_SIZE)
    currentWidth = textSize(emote)
    
    while false and math.abs(currentWidth - targetWidth) > 1 do
        if currentWidth > targetWidth then
            BASE_EMOJI_SIZE = BASE_EMOJI_SIZE - 0.1
        else
            BASE_EMOJI_SIZE = BASE_EMOJI_SIZE + 0.1
        end
        fontSize(TEXT_SIZE)
        currentWidth = textSize(emote)
    end
    BASE_EMOJI_SIZE = BASE_EMOJI_SIZE * 0.75 -- artificial adjustment
    emojiSize = BASE_EMOJI_SIZE
    print(BASE_EMOJI_SIZE)
end

function setup()   
    zoomScroller = ZoomScroller()
    
    -- Setup sensor for pinch gestures
    screen = {x=0, y=0, w=WIDTH, h=HEIGHT}
    sensor = Sensor {parent=screen}
    sensor:onZoom(function(event) 
        zoomScroller:zoomCallback(event)
    end)
    
    calculateTextSize()
    
    sun = Sun()
    snowflake = Snowflake()
    table.insert(motes, sun)
    table.insert(motes, snowflake)
    for i = 1, MOTE_COUNT do
        table.insert(motes, Mote(math.random(WIDTH), math.random(HEIGHT)))
    end

    parameter.watch("visibleCorner")
    parameter.watch("ratioTableCount")
    parameter.number("TIMESCALE", 0.1, 50, 1)  -- Slider from 0.1x to 5x speed
    parameter.boolean("zoomActive", true)
    parameter.boolean("clumpAndAvoid", true)
    parameter.watch("fps")
    parameter.watch("motesDrawn")
    parameter.watch("motesNotDrawn")
    parameter.watch("greenFrames")
    
    shouldTest = false
    if shouldTest then
        testVisibleAreas()
        testNeighborDetection()
        testWrappedNeighbors()
    end
    
    testComparisonOfCombinedAndOriginalFunction()
    testConvertVisibleAreaToScreenRatio()
end

function updateWindDirection()
    -- Slowly change the wind direction over time
    WIND_ANGLE = noise(ElapsedTime * 0.1) * math.pi * 2
end

--should draw zoomed motes not a zoomed image
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
    
    -- Clear the nextGrid for the next frame
    nextGrid = {}
    
    updateWindDirection()
    
    local frame = zoomScroller.frame
    pushStyle()
    background(40, 40, 50)
    spriteMode(CENTER)
    
    pushStyle()
    strokeWidth(5)
    stroke(255, 14, 0)
    noFill()
    --rect(frame.x - frame.width / 2, frame.y - frame.height / 2, frame.width, frame.height)
    popStyle()
    
    local visibleAreas, ratioAreas = zoomScroller:combinedVisibleAreasWithRatios(frame)
    -- local visibleRatios, _ = zoomScroller:visibleAreasWithRatios890(frame)
    drawFrameFromCoordinates(visibleAreas, color(67, 166, 236, 157), 13)    
    zoomScroller:drawRatioAreas(ratioAreas, color(243, 99, 77, 191), 8)


    function drawAsFrameAndRatio(frame, position, size)
        -- Draw directly using the given position
        pushStyle()
        fill(255, 0, 0) -- Set color to red for the direct drawing
        ellipse(position.x, position.y, size + 10)
        popStyle()
        
        -- Now convert the position to a ratio of the frame's dimensions
        local ratioX = (position.x - (frame.x - frame.width / 2)) / frame.width
        local ratioY = (position.y - (frame.y - frame.height / 2)) / frame.height
        
        -- Translate the ratios back to screen positions, assuming the frame is fully visible on the screen
        local screenPosX = ratioX * WIDTH + (frame.x - frame.width / 2)
        local screenPosY = ratioY * HEIGHT + (frame.y - frame.height / 2)
        
        -- Draw using the calculated ratios, should overlap the first ellipse if calculations are correct
        pushStyle()
        fill(0, 255, 0) -- Set color to green for the ratio-based drawing
        ellipse(screenPosX, screenPosY, size)
        popStyle()
    end
    local frame = {
        x = WIDTH / 2,
        y = HEIGHT / 2,
        width = WIDTH,  -- Assuming the frame covers the whole screen
        height = HEIGHT
    }
    
    -- Your object's position, for example:
    local position = {
        x = WIDTH / 2 + 100,
        y = HEIGHT / 2 + 100
    }
    
    -- The size of the ellipse
    local size = 20
    
    -- Now call the draw function
    --drawAsFrameAndRatio(frame, position, size)    
      

    -- Define the frame and the visibleArea
    local frame2 = {
        x = WIDTH / 2,
        y = HEIGHT / 2,
        width = WIDTH, -- Assuming the frame covers the whole screen
        height = HEIGHT
    }
    
    local visibleArea2 = {
        left = 100,
        right = WIDTH - 100,
        top = HEIGHT - 100,
        bottom = 100
    }
    
    -- Call the function to draw ellipses at the corners
    --drawCornersVisibleAreaAndRatio(visibleArea2, frame2)
    

    function drawCornersForMultipleAreas(areas)
        for _, bounds in ipairs(areas) do
            -- Define the corners based on the bounds
            local corners = {
                topLeft = {x = bounds.left, y = bounds.top},
                topRight = {x = bounds.right, y = bounds.top},
                bottomLeft = {x = bounds.left, y = bounds.bottom},
                bottomRight = {x = bounds.right, y = bounds.bottom}
            }
            
            -- Draw ellipses at the corners using screen positions
            pushStyle()
            fill(72, 0, 255) -- Red for direct screen position
            for _, corner in pairs(corners) do
                ellipse(corner.x, corner.y, 30)
            end
            popStyle()
            
            -- Convert corners to ratios based on the full screen as the frame
            local cornerRatios = {
                topLeft = {
                    xR = (corners.topLeft.x) / WIDTH,
                    yR = (corners.topLeft.y) / HEIGHT
                },
                topRight = {
                    xR = (corners.topRight.x) / WIDTH,
                    yR = (corners.topRight.y) / HEIGHT
                },
                bottomLeft = {
                    xR = (corners.bottomLeft.x) / WIDTH,
                    yR = (corners.bottomLeft.y) / HEIGHT
                },
                bottomRight = {
                    xR = (corners.bottomRight.x) / WIDTH,
                    yR = (corners.bottomRight.y) / HEIGHT
                }
            }
            
            -- Draw ellipses at the corners using ratios converted back to screen positions
            pushStyle()
            fill(0, 255, 0) -- Green for ratio position
            for _, ratio in pairs(cornerRatios) do
                local screenPosX = ratio.xR * WIDTH
                local screenPosY = ratio.yR * HEIGHT
                ellipse(screenPosX, screenPosY, 10)
            end
            popStyle()
        end
    end    

    --drawCornersForMultipleAreas(visibleAreas)

    function drawCornersForRatioTables(ratioTables, frame)
        for _, ratio in ipairs(ratioTables) do
            -- Convert ratio back to screen positions for corners
            local corners = {
                topLeft = {
                    x = frame.x - frame.width / 2 + ratio.leftRatio * frame.width,
                    y = frame.y + frame.height / 2 - ratio.topRatio * frame.height
                },
                topRight = {
                    x = frame.x + frame.width / 2 - ratio.rightRatio * frame.width,
                    y = frame.y + frame.height / 2 - ratio.topRatio * frame.height
                },
                bottomLeft = {
                    x = frame.x - frame.width / 2 + ratio.leftRatio * frame.width,
                    y = frame.y - frame.height / 2 + ratio.bottomRatio * frame.height
                },
                bottomRight = {
                    x = frame.x + frame.width / 2 - ratio.rightRatio * frame.width,
                    y = frame.y - frame.height / 2 + ratio.bottomRatio * frame.height
                }
            }
    
            -- Draw ellipses at corners
            pushStyle()
            fill(255, 0, 162) -- Pink for corners from ratio to screen position
            for _, corner in pairs(corners) do
                ellipse(corner.x, corner.y, 28)
            end
            popStyle()
    
            -- Convert corners back to ratios for demonstration
            local cornerRatios = {
                topLeft = {
                    xR = (corners.topLeft.x - (frame.x - frame.width / 2)) / frame.width,
                    yR = ((frame.y + frame.height / 2) - corners.topLeft.y) / frame.height
                },
                topRight = {
                    xR = ((frame.x + frame.width / 2) - corners.topRight.x) / frame.width,
                    yR = ((frame.y + frame.height / 2) - corners.topRight.y) / frame.height
                },
                bottomLeft = {
                    xR = (corners.bottomLeft.x - (frame.x - frame.width / 2)) / frame.width,
                    yR = (corners.bottomLeft.y - (frame.y - frame.height / 2)) / frame.height
                },
                bottomRight = {
                    xR = ((frame.x + frame.width / 2) - corners.bottomRight.x) / frame.width,
                    yR = (corners.bottomRight.y - (frame.y - frame.height / 2)) / frame.height
                }
            }
    
            -- Draw ellipses at corners from ratios converted back
            pushStyle()
            fill(217, 255, 0) -- Yellow for corners back from ratios
            for _, ratioCorner in pairs(cornerRatios) do
                local screenPosX = frame.x - frame.width / 2 + ratioCorner.xR * frame.width
                local screenPosY = frame.y + frame.height / 2 - ratioCorner.yR * frame.height
                ellipse(screenPosX, screenPosY, 10)
            end
            popStyle()
        end
    end

    function drawCornersForRatioTables(ratioTables, frame)
        for _, ratio in ipairs(ratioTables) do
        --Debug: Print the input ratios for verification
        -- printALittle("Input Ratios:",
        --     "Left", tostring(ratio.leftRatio), "Right", tostring(ratio.rightRatio),
        --     "Top", tostring(ratio.topRatio), "Bottom", tostring(ratio.bottomRatio),
        --     "Types",
        --     "Left", type(ratio.leftRatio), "Right", type(ratio.rightRatio),
        --     "Top", type(ratio.topRatio), "Bottom", type(ratio.bottomRatio))
    
            -- Convert ratio back to screen positions for corners
            local corners = {
                topLeft = {
                    x = frame.x - frame.width / 2 + ratio.leftRatio * frame.width,
                    y = frame.y + frame.height / 2 - ratio.topRatio * frame.height
                },
                topRight = {
                    x = frame.x + frame.width / 2 - ratio.rightRatio * frame.width,
                    y = frame.y + frame.height / 2 - ratio.topRatio * frame.height
                },
                bottomLeft = {
                    x = frame.x - frame.width / 2 + ratio.leftRatio * frame.width,
                    y = frame.y - frame.height / 2 + ratio.bottomRatio * frame.height
                },
                bottomRight = {
                    x = frame.x + frame.width / 2 - ratio.rightRatio * frame.width,
                    y = frame.y - frame.height / 2 + ratio.bottomRatio * frame.height
                }
            }

            -- printALittle("ratio.leftRatio: ", ratio.leftRatio)
    
            -- Debug: Print the screen positions for verification
            -- printALittle("Screen Positions:")
            -- for k, v in pairs(corners) do
            --     printALittle(k, "x:", tostring(v.x), "y:", tostring(v.y))
            -- end            
    
            -- Draw ellipses at corners
           -- Draw ellipses at corners
           pushStyle()
           fill(255, 0, 162) -- Pink for corners from ratio to screen position
           for _, corner in pairs(corners) do
                -- printALittle("pink corner as drawn", corner.x, corner.y)
               ellipse(corner.x, corner.y, 28)
           end
           popStyle()

            -- Convert corners back to ratios for demonstration
            local cornerRatios = {
                topLeft = {
                    xR = (corners.topLeft.x - (frame.x - frame.width / 2)) / frame.width,
                    yR = ((frame.y + frame.height / 2) - corners.topLeft.y) / frame.height
                },
                topRight = {
                    xR = ((frame.x + frame.width / 2) - corners.topRight.x) / frame.width,
                    yR = ((frame.y + frame.height / 2) - corners.topRight.y) / frame.height
                },
                bottomLeft = {
                    xR = (corners.bottomLeft.x - (frame.x - frame.width / 2)) / frame.width,
                    yR = (corners.bottomLeft.y - (frame.y - frame.height / 2)) / frame.height
                },
                bottomRight = {
                    xR = ((frame.x + frame.width / 2) - corners.bottomRight.x) / frame.width,
                    yR = (corners.bottomRight.y - (frame.y - frame.height / 2)) / frame.height
                }
            }
    
            -- Debug: Print the recalculated ratios and a direct comparison to the input ratios
            -- print("Recalculated Ratios vs Input Ratios:")
            -- for k, v in pairs(cornerRatios) do
            --     print(k, 
            --         "xR", tostring(v.xR), 
            --         "yR", tostring(v.yR), 
            --         "Input xR", tostring(ratio.leftRatio or ratio.rightRatio), 
            --         "Input yR", tostring(ratio.topRatio or ratio.bottomRatio))
            -- end

    
            -- Draw ellipses at corners from ratios converted back
            pushStyle()
            fill(217, 255, 0) -- Yellow for corners back from ratios
            for _, ratioCorner in pairs(cornerRatios) do
                local screenPosX = frame.x - frame.width / 2 + ratioCorner.xR * frame.width
                local screenPosY = frame.y + frame.height / 2 - ratioCorner.yR * frame.height
                ellipse(screenPosX, screenPosY, 10)
            end
            popStyle()        
        end
    end
    
    drawCornersForRatioTables(ratioAreas, frame)
   
     for i, mote in ipairs(motes) do
        updateGrid(mote, nextGrid)
        checkForNeighbors(mote, currentGrid)  -- Pass currentGrid for neighbor checking
        mote:update()
        local drawingParams = zoomScroller:getDrawingParameters1(mote.position, mote.size, visibleAreas)
        if drawingParams then
            mote:drawWithParams(drawingParams.x, drawingParams.y, drawingParams.size)
            motesDrawn = motesDrawn + 1
        else
            motesNotDrawn = motesNotDrawn + 1
        end
    end
       
    popStyle()
    
    currentGrid, nextGrid = nextGrid, currentGrid
end

-- Limit the magnitude of a vector
function limit(vec, max)
    if vec:len() > max then
        return vec:normalize() * max
    end
    return vec
end

function updateGrid(mote, grid)
    local gridX = math.floor(mote.position.x / gridSize) + 1
    local gridY = math.floor(mote.position.y / gridSize) + 1
    
    grid[gridX] = grid[gridX] or {}
    grid[gridX][gridY] = grid[gridX][gridY] or {}
    table.insert(grid[gridX][gridY], mote)
end

function touched(touch)
    if sensor:touched(touch) then return true end
    if touch.state == BEGAN or touch.state == MOVING then
        local newMote = Mote(touch.x, touch.y)
        newMote.isTouchBorn = true
        table.insert(motes, 1, newMote)
    end
end

function checkForNeighbors(mote, grid)
    local checkRadius = gridSize
    if mote.effectRadius and mote.effectRadius > gridSize then
        checkRadius = mote.effectRadius
    end
    
    local gridX = math.floor(mote.position.x / gridSize) + 1
    local gridY = math.floor(mote.position.y / gridSize) + 1
    local neighbors = {}
    
    -- Calculate the range of cells to check
    local cellsToCheck = math.ceil(checkRadius / gridSize)
    
    for dx = -cellsToCheck, cellsToCheck do
        for dy = -cellsToCheck, cellsToCheck do
            local x = (gridX + dx - 1) % math.ceil(WIDTH / gridSize) + 1
            local y = (gridY + dy - 1) % math.ceil(HEIGHT / gridSize) + 1
            
            local cell = grid[x] and grid[x][y]
            if cell then
                for _, neighbor in ipairs(cell) do
                    if neighbor ~= mote and isNeighbor(mote, neighbor, checkRadius) then
                        table.insert(neighbors, neighbor)
                    end
                end
            end
        end
    end
    
    if clumpAndAvoid then
        local clumpForce = mote:clump(neighbors)
        --   local avoidanceForce = mote:avoid(neighbors)
        
        mote:applyForce(clumpForce)
        --  mote:applyForce(avoidanceForce)
    end
    
    -- If the mote is a Catalyte, affect its neighbors
    if mote.registerWith then
        mote:registerWith(neighbors)
    end
    
    return neighbors
end

function isNeighbor(mote1, mote2, searchRadius)
    local dx = math.abs(mote1.position.x - mote2.position.x)
    local dy = math.abs(mote1.position.y - mote2.position.y)
    
    -- Adjust for screen wrapping
    dx = math.min(dx, WIDTH - dx)
    dy = math.min(dy, HEIGHT - dy)
    
    local result = math.sqrt(dx * dx + dy * dy) < searchRadius
    return result
end

-- Wind function using Perlin noise
function wind(mote)
    local scale = 0.01
    local offset = mote.noiseOffset
    
    -- Adjust coordinates for Perlin noise to wrap around smoothly
    local adjustedX = (mote.position.x % WIDTH) / WIDTH
    local adjustedY = (mote.position.y % HEIGHT) / HEIGHT
    
    local angle = noise(adjustedX * scale + offset, adjustedY * scale + offset) * math.pi * 2
    local windForce = vec2(math.cos(angle), math.sin(angle))
    
    local randomAdjustment = vec2(math.random() * 1 - 0.5, math.random() * 1 - 0.5)
    windForce = windForce + randomAdjustment
    
    local newVelocity = limit(mote.velocity + windForce, mote.maxSpeed)
    local newPosition = mote.position + newVelocity
    
    return newPosition, newVelocity
end