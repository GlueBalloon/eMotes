Boid = class()

function Boid:init(x, y)
    self.position = vec2(x, y)
    self.velocity = vec2(math.random(-2, 2), math.random(-2, 2))
    self.acceleration = vec2(0, 0)
    self.maxSpeed = 2
    self.maxForce = 0.03
    self.perceptionRadius = 30
end

function Boid:applyForce(force)
    self.acceleration = self.acceleration + force
end

function Boid:update()
    self.velocity = self.velocity + self.acceleration
    self.velocity = limit(self.velocity, self.maxSpeed)
    self.position = self.position + self.velocity
    self.acceleration = vec2(0, 0)
    
    -- Screen wrapping
    self.position.x = (self.position.x + WIDTH) % WIDTH
    self.position.y = (self.position.y + HEIGHT) % HEIGHT
end

function Boid:draw()
    ellipse(self.position.x, self.position.y, 5)
end

function Boid:align(boids)
    local steering = vec2(0, 0)
    local total = 0
    for i, other in ipairs(boids) do
        local d = self.position:dist(other.position)
        if other ~= self and d < self.perceptionRadius then
            steering = steering + other.velocity
            total = total + 1
        end
    end
    if total > 0 then
        steering = steering / total
        steering = steering:normalize() * self.maxSpeed
        steering = steering - self.velocity
        steering = limit(steering, self.maxForce)
    end
    return steering
end

function Boid:cohesion(boids)
    local perceptionRadius = self.perceptionRadius
    local steering = vec2(0, 0)
    local total = 0
    for i, other in ipairs(boids) do
        local distance = self.position:dist(other.position)
        if other ~= self and distance < perceptionRadius then
            steering = steering + other.position
            total = total + 1
        end
    end
    if total > 0 then
        steering = steering / total
        steering = steering - self.position
        steering = steering:normalize() * self.maxSpeed
        steering = steering - self.velocity
        steering = limit(steering, self.maxForce)
    end
    return steering
end

function Boid:separation(boids)
    local perceptionRadius = self.perceptionRadius
    local steering = vec2(0, 0)
    local total = 0
    for i, other in ipairs(boids) do
        local distance = self.position:dist(other.position)
        if other ~= self and distance < perceptionRadius then
            local diff = self.position - other.position
            diff = diff / (distance * distance)
            steering = steering + diff
            total = total + 1
        end
    end
    if total > 0 then
        steering = steering / total
        steering = steering:normalize() * self.maxSpeed
        steering = steering - self.velocity
        steering = limit(steering, self.maxForce)
    end
    return steering
end

-- Global variables
local boids = {}
local numBoids = 300

function setup()
    for i = 1, numBoids do
        table.insert(boids, Boid(math.random(WIDTH), math.random(HEIGHT)))
    end
    parameter.boolean("boids")
end

function draw()
    background(40, 40, 50)
    for i, boid in ipairs(boids) do
        local alignment = boid:align(boids)
        local cohesion = boid:cohesion(boids)
        local separation = boid:separation(boids)
        
        boid:applyForce(alignment)
        boid:applyForce(cohesion)
        boid:applyForce(separation)
        
        boid:update()
        boid:draw()
    end
end


-- Limit the magnitude of a vector
function limit(vec, max)
    if vec:len() > max then
        return vec:normalize() * max
    end
    return vec
end
