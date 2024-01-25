MOTE_SIZE = 3
MOTE_COUNT = 2000

-- Mote class
Mote = class()

function Mote:init(x, y)
    self.position = vec2(x, y)
    self.velocity = vec2(math.random() * 4 - 2, math.random() * 4 - 2)  -- Random velocity between -2 and 2
    self.maxSpeed = math.random(4) * math.random() * math.random()  -- Random max speed 
    self.noiseOffset = math.random() * 1000  -- Unique offset for Perlin noise
end

function Mote:update()
    local newPosition, newVelocity = wind(self)
    self.position = newPosition
    self.velocity = newVelocity
    
    -- Screen wrapping
    if self.position.x < 0 then
        self.position.x = self.position.x + WIDTH
    elseif self.position.x > WIDTH then
        self.position.x = self.position.x - WIDTH
    end
    
    if self.position.y < 0 then
        self.position.y = self.position.y + HEIGHT
    elseif self.position.y > HEIGHT then
        self.position.y = self.position.y - HEIGHT
    end
end


function Mote:draw()
    ellipse(self.position.x, self.position.y, MOTE_SIZE)
end

-- Wind function using Perlin noise
function wind(mote)
    local scale = 0.01
    local offset = mote.noiseOffset
    
    -- Using Perlin noise for both direction and acceleration
    local angle = noise(mote.position.x * scale + offset, mote.position.y * scale + offset) * math.pi * 2
    local windForce = vec2(math.cos(angle), math.sin(angle))
    
    -- Random adjustment with correct floating-point generation
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

-- Global variables
local motes = {}

function setup()
    for i = 1, MOTE_COUNT do
        table.insert(motes, Mote(math.random(WIDTH), math.random(HEIGHT)))
    end
end

function draw()
    background(40, 40, 50)
    for i, mote in ipairs(motes) do
        mote:update()
        mote:draw()
    end
end
