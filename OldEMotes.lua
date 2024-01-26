MOTE_SIZE = 6
MOTE_COUNT = 2000
MOTE_SPEED_DEFAULT = 0.1
TIMESCALE = 100
WIND_ANGLE = 0

-- Global variables
local motes = {}

function setup()
    -- Initialize motes
    for i = 1, MOTE_COUNT do
        table.insert(motes, Mote(math.random(WIDTH), math.random(HEIGHT)))
    end
    
    -- Initialize a few Sun and Snowflake catalytes
    for i = 1, 1 do  -- Adjust the number of Sun and Snowflake catalytes as needed
        table.insert(motes, Sun(math.random(WIDTH), math.random(HEIGHT)))
        table.insert(motes, Snowflake(math.random(WIDTH), math.random(HEIGHT)))
    end
    parameter.number("TIMESCALE", 0.1, 50, 3)  -- Slider from 0.1x to 5x speed
end

function updateWindDirection()
    -- Slowly change the wind direction over time
    WIND_ANGLE = noise(ElapsedTime * 0.1) * math.pi * 2
end

-- Define gridSize for the grid
local gridSize = 50  -- Adjust this value as needed

-- Initialize the grid
local grid = {}

-- Mote class
Mote = class()

function Mote:init(x, y)
    self.position = vec2(x, y)
    self.velocity = vec2(math.random() * 4 - 2, math.random() * 4 - 2)
    --self.maxSpeed = (math.random() < 0.5 and math.random() * 0.5 or math.random() * 0.02)
    self.maxSpeed = MOTE_SPEED_DEFAULT or 0.3
    self.noiseOffset = math.random() * 1000
    self.perceptionRadius = 16 -- Adjust as needed
    self.maxForce = math.random() * 20 -- Adjust as needed
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
end

function Mote:draw()
    ellipse(self.position.x, self.position.y, MOTE_SIZE)
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
        --  steeringForce = steeringForce * (distance / self.perceptionRadius)
        steeringForce = steeringForce * (distance) 
        return steeringForce
    else
        return vec2(0, 0)
    end
end

function Mote:avoid(neighbors)
    local avoidanceForce = vec2(0, 0)
    local total = 0
    local avoidanceRadius = MOTE_SIZE  -- Adjust as needed
    
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
        avoidanceForce = avoidanceForce * 0.1  -- Adjust the strength of avoidance
        return limit(avoidanceForce, self.maxForce)
    else
        return vec2(0, 0)
    end
end

function Mote:affectNeighbors(neighbors)
    -- Default implementation does nothing
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



-- Limit the magnitude of a vector
function limit(vec, max)
    if vec:len() > max then
        return vec:normalize() * max
    end
    return vec
end

-- Update grid function
function updateGrid(mote)
    local gridX = math.floor(mote.position.x / gridSize) + 1
    local gridY = math.floor(mote.position.y / gridSize) + 1
    
    grid[gridX] = grid[gridX] or {}
    grid[gridX][gridY] = grid[gridX][gridY] or {}
    
    table.insert(grid[gridX][gridY], mote)
end

-- Check for neighbors function
function checkForNeighbors(mote)
    local gridX = math.floor(mote.position.x / gridSize) + 1
    local gridY = math.floor(mote.position.y / gridSize) + 1
    local neighbors = {}
    
    for dx = -1, 1 do
        for dy = -1, 1 do
            local x = gridX + dx
            local y = gridY + dy
            if x > 0 and x <= math.ceil(WIDTH / gridSize) and y > 0 and y <= math.ceil(HEIGHT / gridSize) then
                local cell = grid[x] and grid[x][y]
                if cell then
                    for _, neighbor in ipairs(cell) do
                        if neighbor ~= mote and mote.position:dist(neighbor.position) < MOTE_SIZE then
                            table.insert(neighbors, neighbor)
                        end
                    end
                end
            end
        end
    end
    
    local clumpForce = mote:clump(neighbors)
    local avoidanceForce = mote:avoid(neighbors)
    
    mote:applyForce(clumpForce)
    mote:applyForce(avoidanceForce)
end


function draw()
    background(40, 40, 50)
    
    -- Clear the grid
    grid = {}
    
    updateWindDirection()
    
    for i, mote in ipairs(motes) do
        updateGrid(mote)
        checkForNeighbors(mote)
        mote:update()
        mote:draw()
    end
end

function touched(touch)
    if touch.state == BEGAN or touch.state == MOVING then
        local newMote = Mote(touch.x, touch.y)
        table.insert(motes, newMote)
    end
end


-- Catalyte class as a subclass of Mote
Catalyte = class(Mote)

function Catalyte:init(x, y, effectRadius)
    Mote.init(self, x, y)
    self.effectRadius = effectRadius
end

function Catalyte:affectNeighbors(neighbors)
    for _, neighbor in ipairs(neighbors) do
        if neighbor.position:dist(self.position) < self.effectRadius then
            self:applyEffectToMote(neighbor)
        end
    end
end

Sun = class(Catalyte)

function Sun:init(x, y)
    Catalyte.init(self, x, y, 100)
    self.maxSpeed = MOTE_SPEED_DEFAULT * 2
end

function Sun:applyEffectToMote(mote)
    local distance = mote.position:dist(self.position)
    if distance < self.effectRadius then
        mote.isWarm = true
    end
end

function Sun:draw()
    pushStyle()
    fill(255, 255, 0)
    ellipse(self.position.x, self.position.y, MOTE_SIZE * 3)
    popStyle()
end

Snowflake = class(Catalyte)

function Snowflake:init(x, y)
    Catalyte.init(self, x, y, 100)
    self.maxSpeed = MOTE_SPEED_DEFAULT * 5
end

function Snowflake:applyEffectToMote(mote)
    local distance = mote.position:dist(self.position)
    if distance < self.effectRadius then
        mote.isCold = true
    end
end

function Snowflake:draw()
    pushStyle()
    fill(0, 255, 255)
    ellipse(self.position.x, self.position.y, MOTE_SIZE * 3)
    popStyle()
end
