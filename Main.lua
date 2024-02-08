MOTE_SIZE = 3
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
    
    bufferA = image(WIDTH, HEIGHT)
    bufferB = image(WIDTH, HEIGHT)
    useBufferA = true
    
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
    testNeighborDetection()
    testWrappedNeighbors()
    parameter.number("TIMESCALE", 0.1, 50, 1)  -- Slider from 0.1x to 5x speed
    parameter.boolean("zoomActive", true)
    parameter.boolean("clumpAndAvoid", true)
    parameter.watch("fps")
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
    
    -- Clear the nextGrid for the next frame
    nextGrid = {}
    
    updateWindDirection()
    
    local frame = zoomScroller.frame
    pushStyle()
    background(40, 40, 50)
    spriteMode(CENTER)
    
    pushStyle()
    strokeWidth(10)
    stroke(255, 14, 0)
    noFill()
    rect(frame.x - frame.width / 2, frame.y - frame.height / 2, frame.width, frame.height)
    popStyle()
    
    
    
    for i, mote in ipairs(motes) do
        updateGrid(mote, nextGrid)
        checkForNeighbors(mote, currentGrid)  -- Pass currentGrid for neighbor checking
        mote:update()
        mote:draw(frame)
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