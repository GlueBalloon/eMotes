





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
        ellipse(screenPos.x, screenPos.y, self.size * zoomLevel)
    end
    
    popStyle()
end












-- Catalyte class
Catalyte = class(Mote)

function Catalyte:init(x, y, effectRadius)
    Mote.init(self, x, y)  -- Adjust effect radius as needed
    self.size = MOTE_SIZE * 1.25
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
    self.color = color(255, 121, 0)  -- Warm color for the su
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