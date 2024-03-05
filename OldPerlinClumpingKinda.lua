--- ignore this page
MOTE_SIZE = 3
MOTE_COUNT = 3000
-- Global time scale variable
TIMESCALE = 1
WIND_ANGLE = 0
lastTime = ElapsedTime
frameCount = 0
fps = 0

function updateWindDirection()
    -- Slowly change the wind direction over time
    --   WIND_ANGLE = noise(ElapsedTime * 0.1) * math.pi * 2
end

-- Define gridSize for the grid
gridSize = 10  -- Adjust this value as needed

-- Initialize the grid
grid = {}

-- Mote class
Mote = class()

function Mote:init(x, y)
    self.position = vec2(x, y)
    self.baseVelocity = vec2(math.random() * 4 - 2, math.random() * 4 - 2)
    self.velocity = self.baseVelocity
    self.maxSpeed =  0.5
    self.noiseOffset = math.random() * 1000
    self.perceptionRadius = math.min(WIDTH, HEIGHT) * 0.5 -- Adjust as needed
    self.perceptionRadius = 6 -- Adjust as needed
    self.maxForce = math.random() * 2 -- Adjust as needed
end

function Mote:update()
    local newPosition, newVelocity = wind(self)
    self.position = newPosition
    self.velocity = newVelocity
    
    -- Screen wrapping
    self.position.x = (self.position.x + WIDTH) % WIDTH
    self.position.y = (self.position.y + HEIGHT) % HEIGHT
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

function Mote:clump(neighbors)
    return vec2(-#neighbors, -#neighbors)
end
function Mote:avoid(neighbors)
    return vec2(0, 0)
end

function Mote:clump(neighbors)
    local totalNeighbors = #neighbors
    
    -- Define a slowdown factor based on the number of neighbors
    local slowdownFactor = 0.1 -- Adjust this value as needed
    
    -- Calculate the slowdown based on the number of neighbors
    local slowdown = slowdownFactor * totalNeighbors
    
    -- Apply the slowdown to the current velocity
    local reducedVelocity = self.velocity * (1 - slowdown)
    
    -- Ensure the slowdown doesn't reverse the direction
    if reducedVelocity:len() < 0 then
        reducedVelocity = vec2(0, 0)
    end
    
    return vec2(1,1) * -slowdown
end

function Mote:clump(neighbors)
    local slowdownFactor = 0.05 -- Adjust this value as needed
    local totalNeighbors = #neighbors
    
    if totalNeighbors > 0 then
        -- Reduce speed based on the number of neighbors
        local speedReduction = slowdownFactor * totalNeighbors
        local reducedSpeed = self.velocity * (1 - speedReduction)
        return reducedSpeed - self.velocity
    else
        return vec2(0, 0)
    end
end


function Mote:clump(neighbors)
    local slowdownFactor = 0.9 -- Adjust this value as needed
    local recoveryFactor = 0.01 -- Speed recovery rate
    local randomnessFactor = 2 -- Adjust for more or less randomness
    local totalNeighbors = #neighbors
    
    -- Randomness to make the motion less uniform
    local randomAdjustment = vec2(math.random() * randomnessFactor - randomnessFactor / 2, math.random() * randomnessFactor - randomnessFactor / 2)
    
    if totalNeighbors > 0 then
        -- Reduce speed based on the number of neighbors
        local speedReduction = slowdownFactor * totalNeighbors
        local reducedSpeed = self.velocity * (1 - speedReduction)
        return (reducedSpeed + randomAdjustment) - self.velocity
    else
        -- Gradually restore speed towards baseVelocity
        local speedRecovery = (self.baseVelocity - self.velocity) * recoveryFactor
        return speedRecovery + randomAdjustment
    end
end

function Mote:clump(neighbors)
    if #neighbors > 0 then
        -- Randomly select one neighbor
        local selectedNeighbor = neighbors[math.random(#neighbors)]
        
        -- Adjust velocity based on the selected neighbor's velocity
        -- This could be a simple assignment or a more complex calculation
        local adjustmentFactor = 0.9  -- Adjust this factor as needed
        self.velocity = lerp(self.velocity, selectedNeighbor.velocity, adjustmentFactor)
    end
    
    return self.velocity
end

function lerp(a, b, t)
    return a + (b - a) * t
end



function Mote:draw()
    pushStyle()
    fill(236, 212, 67)
    ellipse(self.position.x, self.position.y, MOTE_SIZE)
    popStyle()
   -- ellipse(self.position.x, self.position.y, MOTE_SIZE)
end

-- Wind function using Perlin noise
function wind(mote)
    local scale = 0.01
    local offset = mote.noiseOffset
    
    local angle = noise(mote.position.x * scale + offset, mote.position.y * scale + offset) * math.pi * 2
    local windForce = vec2(math.cos(angle), math.sin(angle))
    --local windForce = vec2(math.cos(WIND_ANGLE), math.sin(WIND_ANGLE))
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
                        if neighbor ~= mote and mote.position:dist(neighbor.position) < gridSize then
                            table.insert(neighbors, neighbor)
                        end
                    end
                end
            end
        end
    end
    
    if clumpAndAvoid then
        local clumpForce = mote:clump(neighbors)
        local avoidanceForce = mote:avoid(neighbors)
        
        mote:applyForce(clumpForce)
        mote:applyForce(avoidanceForce)
    end
end

-- Global variables
local motes = {}

function setup()
    for i = 1, MOTE_COUNT do
        table.insert(motes, Mote(math.random(WIDTH), math.random(HEIGHT)))
    end
    parameter.number("TIMESCALE", 0.1, 50, 1)  -- Slider from 0.1x to 5x speed
    parameter.boolean("clumpAndAvoid", false)
    parameter.watch("fps")
end

function draw()
    background(40, 40, 50)
    -- Calculate FPS every second
    frameCount = frameCount + 1
    if ElapsedTime - lastTime >= 1 then
        fps = frameCount / (ElapsedTime - lastTime)
        frameCount = 0
        lastTime = ElapsedTime
    end
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
