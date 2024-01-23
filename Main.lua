viewer.mode = FULLSCREEN

-- Particle class
Particle = class()

function Particle:init(x, y)
    self.position = vec2(x, y)
    self.velocity = vec2(math.random(-1, 1), math.random(-1, 1))
    self.speed = math.random()
end

function Particle:update()
    -- Simulate breeze effect
    local breeze = vec2(math.random(-1, 1), math.random(-1, 1))
    self.velocity = self.velocity + breeze * 0.1
    self.velocity = self.velocity:normalize() * self.speed
    
    -- Update position
    self.position = self.position + self.velocity
    
    -- Screen wrapping
    self.position.x = (self.position.x + WIDTH) % WIDTH
    self.position.y = (self.position.y + HEIGHT) % HEIGHT
end

function Particle:draw()
    ellipse(self.position.x, self.position.y, 5)
end

-- Global variables
local particles = {}
local numParticles = 4000

function setup()
    -- Create particles
    for i = 1, numParticles do
        table.insert(particles, Particle(math.random(WIDTH), math.random(HEIGHT)))
    end
end

function draw()
    background(40, 40, 50)
    
    -- Update and draw particles
    for i, particle in ipairs(particles) do
        particle:update()
        particle:draw()
    end
end
