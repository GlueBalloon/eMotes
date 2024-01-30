PRINTALITTLETIME = 1.02
MOTE_SIZE = 3
MOTE_COUNT = 1500
MOTE_SPEED_DEFAULT = 0.5
TIMESCALE = 1
WIND_ANGLE = 0
-- Initialize the grid
gridSize = 10  -- Adjust this value as needed
grid = {}

--[[
function testNeighborDetection()
    -- Create test motes
    local testMotes = {
        Mote(100, 100),  -- Mote 1
        Mote(105, 100),  -- Mote 2, close to Mote 1
        Mote(300, 300),  -- Mote 3, far from Mote 1 and 2
    }
    
    -- Clear the grid
    grid = {}
    
    -- Update grid with test motes
    for _, mote in ipairs(testMotes) do
        updateGrid(mote)
        --       print("Updated grid for mote at " .. tostring(mote.position))
    end
    
    -- Check grid contents (Debugging)
    for x, col in pairs(grid) do
        for y, cell in pairs(col) do
            --            print("Grid cell [" .. x .. "," .. y .. "] has " .. #cell .. " motes.")
        end
    end
    
    -- Run neighbor detection for each mote
    for _, mote in ipairs(testMotes) do
        local neighbors = checkForNeighbors(mote, grid)
        
        -- Print results for debugging
        print("Mote at " .. tostring(mote.position) .. " has " .. #neighbors .. " neighbors.")
        for _, neighbor in ipairs(neighbors) do
            print(" - Neighbor at " .. tostring(neighbor.position))
        end
    end
end
]]

-- Global variables
local motes = {}

function setup()
    -- testNeighborDetection()
    -- Initialize motes
    for i = 1, MOTE_COUNT do
        table.insert(motes, Mote(math.random(WIDTH), math.random(HEIGHT)))
    end
    
    -- Initialize Sun and Snowflake catalytes
    sun = Sun()
    snowflake = Snowflake()
    for i = 1, 1 do  -- Adjust the number of Sun and Snowflake catalytes as needed
        table.insert(motes, sun)
        table.insert(motes, snowflake)
    end
    parameter.number("TIMESCALE", 0.1, 50, TIMESCALE)  -- Slider from 0.1x to 5x speed
end

function updateWindDirection()
    -- Slowly change the wind direction over time
    WIND_ANGLE = noise(ElapsedTime * 0.1) * math.pi * 2
end

-- Mote class
Mote = class()

function Mote:init(x, y)
    self.position = vec2(x or math.random(WIDTH), y or math.random(HEIGHT))
    self.velocity = vec2(math.random() * 4 - 2, math.random() * 4 - 2)
    --self.maxSpeed = (math.random() < 0.5 and math.random() * 0.5 or math.random() * 0.02)
    self.maxSpeed = MOTE_SPEED_DEFAULT or 0.3
    self.noiseOffset = math.random() * 1000
    self.perceptionRadius = 16 -- Adjust as needed
    self.maxForce = math.random() * 20 -- Adjust as needed
    self.defaultColor = color(226, 224, 192)  -- Default color for motes
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

function Mote:draw()
    pushStyle()
    fill(self.color)
    ellipse(self.position.x, self.position.y, MOTE_SIZE)
    popStyle()
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
    local gridSize = gridSize
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
                        --  if neighbor ~= mote and mote.position:dist(neighbor.position) < gridSize then
                        if neighbor ~= mote and mote.position:dist(neighbor.position) < gridSize then
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
    if mote.affectNeighbors then
        -- If the mote is a Catalyte, affect its neighbors
        mote:affectNeighbors(neighbors)
    end
    return neighbors
end

function findCatalyteNeighbors(catalyte)
    
    --    local gridSize = math.max(gridSize, mote.effectRadius)
    
    local gridX = math.floor(catalyte.position.x / gridSize) + 1
    local gridY = math.floor(catalyte.position.y / gridSize) + 1
    local neighbors = {}
    
    -- Calculate the range of cells to check based on effectRadius
    local cellsToCheck = math.ceil(catalyte.effectRadius / gridSize)
    
    for dx = -cellsToCheck, cellsToCheck do
        for dy = -cellsToCheck, cellsToCheck do
            local x = gridX + dx
            local y = gridY + dy
            -- Check if the cell is within the grid bounds
            if x > 0 and x <= math.ceil(WIDTH / gridSize) and y > 0 and y <= math.ceil(HEIGHT / gridSize) then
                local cell = grid[x] and grid[x][y]
                if cell then
                    for _, neighbor in ipairs(cell) do
                        -- Check if the neighbor is within the effectRadius
                        if catalyte.position:dist(neighbor.position) < catalyte.effectRadius then
                            table.insert(neighbors, neighbor)
                        end
                    end
                end
            end
        end
    end
    
    local clumpForce = catalyte:clump(neighbors)
    local avoidanceForce = catalyte:avoid(neighbors)    
    
    catalyte:applyForce(clumpForce)
    catalyte:applyForce(avoidanceForce)
    
    catalyte:affectNeighbors(neighbors)
end



function draw()
    background(40, 40, 50)
    -- if ElapsedTime < PRINTALITTLETIME then
    printALittle("------------DRAWING------------")
    -- Clear the grid
    grid = {}
    
    updateWindDirection()
    
    for i, mote in ipairs(motes) do
        updateGrid(mote)
        checkForNeighbors(mote)
        mote:update()
        mote:draw()
    end
    --  end
end

function touched(touch)
    if touch.state == BEGAN or touch.state == MOVING then
        local newMote = Mote(touch.x, touch.y)
        table.insert(motes, newMote)
    end
end


-- Catalyte class
Catalyte = class(Mote)

function Catalyte:init(x, y, effectRadius)
    Mote.init(self, x, y)  -- Adjust effect radius as needed
    self.effectRadius = effectRadius or 60
end

function Catalyte:affectNeighbors(neighbors)
    for _, neighbor in ipairs(neighbors) do
        if neighbor.position:dist(self.position) < self.effectRadius then
            self:applyEffect(neighbor)
            neighbor.currentAffecting[self] = true
        end
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
    ellipse(self.position.x, self.position.y, MOTE_SIZE)
    popStyle()
end

-- Snowflake class
Snowflake = class(Catalyte)

-- Snowflake class
function Snowflake:init(x, y)
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
    ellipse(self.position.x, self.position.y, MOTE_SIZE)
    popStyle()
end

function blendColor(color1, color2, intensity)
    return color(
    lerp(color1.r, color2.r, intensity),
    lerp(color1.g, color2.g, intensity),
    lerp(color1.b, color2.b, intensity)
    )
end

function lerp(a, b, t)
    return a + (b - a) * t
end