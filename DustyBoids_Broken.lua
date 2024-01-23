Boid = class()

function Boid:init(x, y)
    self.position = vec2(x, y)
    self.velocity = vec2(math.random(-2, 2), math.random(-2, 2))
    self.acceleration = vec2(0, 0)
    self.maxSpeed = math.random(2) * math.random()
    self.maxForce = 0.03
    self.perceptionRadius = 30
    self.state = "flocking"  -- Possible states: "flocking", "stumbling", "still"
    self.stumbleTimer = 0
end

function Boid:applyForce(force)
    self.acceleration = self.acceleration + force
end

function Boid:update()
    if true then
    -- Decide on the state of the boid
    if math.random() < 0.01 then
        if self.state == "flocking" then
            self.state = (math.random() < 0.5) and "stumbling" or "still"
        else
            self.state = "flocking"
        end
    end
    
    -- Apply different behaviors based on state
    if self.state == "flocking" then
        -- Normal Boids behavior
        self.velocity = self.velocity + self.acceleration
        
        -- Stumbly motion
        if self.stumbleTimer <= 0 then
            self.velocity = vec2(math.random(-1, 1), math.random(-1, 1))
            self.stumbleTimer = math.random(30, 60)
        else
            self.stumbleTimer = self.stumbleTimer - 1
        end
    elseif self.state == "still" then
        -- Stay in place
        self.velocity = vec2(0, 0)
    end
    
    -- Continue with existing update code
    self.velocity = limit(self.velocity, self.maxSpeed)
    self.position = self.position + self.velocity
    self.acceleration = vec2(0, 0)
    
    -- Screen wrapping
    self.position.x = (self.position.x + WIDTH) % WIDTH
    self.position.y = (self.position.y + HEIGHT) % HEIGHT
    
        return
    end
    
    -- Debugging state transition
    local prevState = self.state
    
    -- Decide on the state of the boid
    if math.random() < 0.01 then
        if self.state == "flocking" then
            self.state = (math.random() < 0.5) and "stumbling" or "still"
        else
            self.state = "flocking"
        end
    end
    
    -- Handle state behaviors
    if self.state == "flocking" then
        self.velocity = self.velocity + self.acceleration
    elseif self.state == "stumbling" then
        -- Stumbling behavior
    elseif self.state == "still" then
        -- Gradually reduce velocity to zero
        self.velocity = self.velocity * 0.9
        if self.velocity:len() < 0.05 then
            self.velocity = vec2(0, 0)
        end
    end
    
    -- Debugging output
    if prevState ~= self.state then
        print(prevState .. " to " .. self.state)
    end
    -- Continue with existing update code
    self.velocity = limit(self.velocity, self.maxSpeed)
    self.position = self.position + self.velocity
    self.acceleration = vec2(0, 0)
    
    -- Screen wrapping
    self.position.x = (self.position.x + WIDTH) % WIDTH
    self.position.y = (self.position.y + HEIGHT) % HEIGHT
end

function Boid:draw()
    if self.state == "still" then
        fill(255, 0, 0)  -- Red color for still boids
    elseif self.state == "stumbling" then
        fill(255, 127, 0)  -- orange color for stumbling boids
    else
        fill(255)  -- Default color for flocking states
    end
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
local numBoids = 100

function setup()
    for i = 1, numBoids do
        table.insert(boids, Boid(math.random(WIDTH), math.random(HEIGHT)))
    end
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
