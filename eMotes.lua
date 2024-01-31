MOTE_SIZE = 3
MOTE_COUNT = 3000
TIMESCALE = 1
WIND_ANGLE = 0
MOTE_SPEED_DEFAULT = 0.5
BASE_EMOJI_SIZE = MOTE_SIZE  -- Initial guess for text size
ZOOM_THRESHOLD = 1.7  -- Threshold for switching to emote drawing
-- Global variables
local motes = {}
local currentGrid = {}
local nextGrid = {}
local gridSize = 10  -- Adjust this value as needed
local zoomLevel = 1.0
local zoomOrigin = vec2(WIDTH / 2, HEIGHT / 2)
local emojiSize = BASE_EMOJI_SIZE

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
    BASE_EMOJI_SIZE = BASE_EMOJI_SIZE * 0.85 -- artificial adjustment
    emojiSize = BASE_EMOJI_SIZE
    print(BASE_EMOJI_SIZE)
end

function setup()
    screen = {x=0,y=0,w=WIDTH,h=HEIGHT} 
    sensor = Sensor {parent=screen} -- tell the object you want to be listening to touches, here the screen
    sensor:onZoom( zoomCallback )
    
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
end

-- Zoom callback function
function zoomCallback(event)
    local touch1 = event.touches[1]
    local touch2 = event.touches[2]
    
    -- Calculate the midpoint of the two touches
    zoomOrigin = vec2((touch1.x + touch2.x) / 2, (touch1.y + touch2.y) / 2)
    
    local zoomChange = 1 + (event.dw + event.dh) / 500 -- Adjust the denominator to control zoom sensitivity
    zoomLevel = zoomLevel * zoomChange
    zoomLevel = math.max(0.1, math.min(zoomLevel, 10)) -- Limit the zoom level
end

function updateWindDirection()
    -- Slowly change the wind direction over time
    WIND_ANGLE = noise(ElapsedTime * 0.1) * math.pi * 2
end





-- Mote class
Mote = class()

function Mote:init(x, y)
    self.size = MOTE_SIZE
    self.position = vec2(x or math.random(WIDTH), y or math.random(HEIGHT))
    self.velocity = vec2(math.random() * 4 - 2, math.random() * 4 - 2)
    self.maxSpeed = MOTE_SPEED_DEFAULT
    self.noiseOffset = math.random() * 1000
    self.perceptionRadius = 6 -- Adjust as needed
    self.maxForce = math.random() * 2 -- Adjust as needed
    self.defaultColor = color(239, 178, 61) -- Default color for motes
    self.defaultColor = color(216, 138, 49) -- Default color for motes
    self.defaultColor = color(229, 205, 91)
    self.color = self.defaultColor
    self.currentAffecting = {}
    self.affectedBy = {}  -- Table to keep track of affecting catalytes
    self.state = "normal" -- Possible states: "normal", "hot", "cold"
end

function Mote:update()
    local newPosition, newVelocity = wind(self)
    
    -- Apply time scale to the velocity
    newVelocity = newVelocity * TIMESCALE
    
    self.position = self.position + newVelocity
    self.velocity = newVelocity
    
    -- Screen wrapping
    self.position.x = (self.position.x + WIDTH) % WIDTH
    self.position.y = (self.position.y + HEIGHT) % HEIGHT
    self:applyCatalytes()
    self:updateAppearance()
end

function Mote:updateAppearance()
    --skip if this mote is a catalyte itself
    if self.applyEffect then return end
    if self.state == "hot" then
        self.color = color(172, 100, 81) -- Hot color
    elseif self.state == "cold" then
        self.color = color(82, 111, 117) -- Cold color
    else
        self.color = self.defaultColor -- Normal color
    end
end

function Mote:applyCatalytes()
    --skip if this mote is a catalyte itself
    if self.applyEffect then return end
    
    -- Apply effects from current affecting catalytes
    for catalyte, _ in pairs(self.currentAffecting) do
        catalyte:applyEffect(self)
    end
    
    -- Remove effects from no longer affecting catalytes
    for catalyte, _ in pairs(self.affectedBy) do
        if not self.currentAffecting[catalyte] then
            catalyte:undoEffect(self)
        end
    end
    -- Update affectedBy to match currentAffecting
    self.affectedBy = self.currentAffecting
    self.currentAffecting = {}
end


function Mote:applyForce(force)
    self.velocity = self.velocity + force
end

function Mote:clump(neighbors)
    local averagePosition = vec2(0, 0)
    local total = 0
    
    for _, neighbor in ipairs(neighbors) do
        averagePosition = averagePosition + neighbor.position
        total = total + 1
    end
    
    if total > 0 then
        averagePosition = averagePosition / total
        local desiredVelocity = (averagePosition - self.position):normalize() * self.maxSpeed
        local steeringForce = desiredVelocity - self.velocity
        steeringForce = limit(steeringForce, self.maxForce)
        
        -- Make the steering force stronger based on distance to average position
        local distance = self.position:dist(averagePosition)
        steeringForce = steeringForce * (distance / self.perceptionRadius)
        --steeringForce = steeringForce * (distance)
        return steeringForce
    else
        return vec2(0, 0)
    end
end

function Mote:avoid(neighbors)
    local avoidanceForce = vec2(0, 0)
    local total = 0
    local avoidanceRadius = MOTE_SIZE * 2 -- Adjust as needed
    
    for _, neighbor in ipairs(neighbors) do
        local distance = self.position:dist(neighbor.position)
        if distance < avoidanceRadius then
            local pushAway = self.position - neighbor.position
            pushAway = pushAway / (distance * distance)  -- Increase repulsion for closer motes
            avoidanceForce = avoidanceForce + pushAway
            total = total + 1
        end
    end
    
    if total > 0 then
        avoidanceForce = avoidanceForce / total
        avoidanceForce = avoidanceForce * 0.02  -- Adjust the strength of avoidance
        return limit(avoidanceForce, self.maxForce)
    else
        return vec2(0, 0)
    end
end

-- Mote drawing method
--[[
function Mote:draw()
pushStyle()
fill(self.color)

if zoomLevel > ZOOM_THRESHOLD then
if self.state == "normal" then
fill(255)
end
-- Draw text emote
fontSize(EMOJI_SIZE)
local textWidth = textSize("😀")
local textX = self.position.x - textWidth / 2
local textY = self.position.y - EMOJI_SIZE / 2
text("😀", textX, textY)
else
-- Draw simple dot
ellipse(self.position.x, self.position.y, MOTE_SIZE)
end

popStyle()
end


function Mote:draw(screenPos, zoomLevel)
    pushStyle()
    fill(self.color)
    
    if zoomLevel > ZOOM_THRESHOLD then
        if self.state == "normal" then
            fill(255)
        end
        -- Draw text emote
        local textWidth = textSize("😀")
        -- Calculate scaled font size based on zoom level
        emojiSize = BASE_EMOJI_SIZE * (zoomLevel)
        fontSize(emojiSize)
        local textX = screenPos.x - textWidth / 2
        local textY = screenPos.y - BASE_EMOJI_SIZE / 2
        text("😀", textX, textY)
    else
        -- Draw simple dot
        ellipse(screenPos.x, screenPos.y, MOTE_SIZE * zoomLevel)
    end
    
    popStyle()
end
]]
-- Mote drawing function
function Mote:draw(screenPos, zoomLevel)
    pushStyle()
    fill(self.color)
    
    if zoomLevel > ZOOM_THRESHOLD then
        if self.state == "normal" then
            fill(255)
        end
        
        -- Calculate visible width at current zoom level
        local visibleWidth = WIDTH / zoomLevel
        
        -- Calculate scaled font size based on visible width
        local emojiRatio = BASE_EMOJI_SIZE / MOTE_SIZE  -- Original ratio of emoji size to screen width
        local scaledFontSize = BASE_EMOJI_SIZE * emojiRatio
        
        fontSize(scaledFontSize * zoomLevel)
        
        -- Calculate text width for centering
        local textWidth = textSize("😀")
        local textX = screenPos.x - textWidth / 2
        local textY = screenPos.y - scaledFontSize / 2
        
        -- Draw text emote
        text("😀", textX, textY)
    else
        -- Draw simple dot
        ellipse(screenPos.x, screenPos.y, MOTE_SIZE * zoomLevel)
    end
    
    popStyle()
end






function draw()
    background(40, 40, 50)
    
    -- Clear the nextGrid for the next frame
    nextGrid = {}
    
    updateWindDirection()
    
    -- Apply zoom and pan
    local thisZoom = zoomLevel >= 1.0 and zoomLevel or 1.0
    pushMatrix()
    translate(zoomOrigin.x, zoomOrigin.y)
    scale(thisZoom)
    translate(-zoomOrigin.x, -zoomOrigin.y)
    
    for i, mote in ipairs(motes) do
        updateGrid(mote)
        checkForNeighbors(mote, currentGrid)  -- Pass currentGrid for neighbor checking
        mote:update()
        if isMoteVisible(mote) then
            -- Calculate screen position for each mote
            local screenPos = (mote.position - zoomOrigin) * zoomLevel + zoomOrigin
            -- Draw mote at calculated screen position
            mote:draw(screenPos, zoomLevel)
            --mote:draw()
        end
    end
    
    popMatrix()
    
    -- Swap grids
    currentGrid, nextGrid = nextGrid, currentGrid
end

-- Limit the magnitude of a vector
function limit(vec, max)
    if vec:len() > max then
        return vec:normalize() * max
    end
    return vec
end

function updateGrid(mote)
    local gridX = math.floor(mote.position.x / gridSize) + 1
    local gridY = math.floor(mote.position.y / gridSize) + 1
    
    nextGrid[gridX] = nextGrid[gridX] or {}
    nextGrid[gridX][gridY] = nextGrid[gridX][gridY] or {}
    table.insert(nextGrid[gridX][gridY], mote)
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
    
    local clumpForce = mote:clump(neighbors)
    local avoidanceForce = mote:avoid(neighbors)
    
    mote:applyForce(clumpForce)
    mote:applyForce(avoidanceForce)
    
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





-- Catalyte class
Catalyte = class(Mote)

function Catalyte:init(x, y, effectRadius)
    Mote.init(self, x, y)  -- Adjust effect radius as needed
    self.effectRadius = effectRadius or MOTE_SIZE * 8
end

function Catalyte:registerWith(neighbors)
    for _, neighbor in ipairs(neighbors) do
        neighbor.currentAffecting[self] = true
    end
end





-- Sun class
Sun = class(Catalyte)

function Sun:init(x, y, effectRadius)
    Catalyte.init(self, x, y, effectRadius)
    self.color = color(255, 201, 0)  -- Warm color for the su
end

-- Sun class
function Sun:applyEffect(mote)
    if mote.state == "cold" then
        mote.state = "normal"
    else
        mote.state = "hot"
    end
end

function Sun:undoEffect(mote)
    if mote.state == "hot" then
        mote.state = "normal"
    end
end

function Sun:draw()
    pushStyle()
    fill(self.color)
    ellipse(self.position.x, self.position.y, MOTE_SIZE + 1)
    popStyle()
end





-- Snowflake class
Snowflake = class(Catalyte)

-- Snowflake class
function Snowflake:init(x, y, effectRadius)
    Catalyte.init(self, x, y, effectRadius)
    self.color = color(59, 238, 231)  -- Cold color for the snowflake
end

-- Snowflake class
function Snowflake:applyEffect(mote)
    if mote.state == "hot" then
        mote.state = "normal"
    else
        mote.state = "cold"
    end
end

function Snowflake:undoEffect(mote)
    if mote.state == "cold" then
        mote.state = "normal"
    end
end

function Snowflake:draw()
    pushStyle()
    fill(self.color)
    ellipse(self.position.x, self.position.y, MOTE_SIZE + 1)
    popStyle()
end