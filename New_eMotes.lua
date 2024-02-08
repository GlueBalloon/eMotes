





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
    self.defaultColor = color(229, 205, 91)
    self.color = self.defaultColor
    self.currentAffecting = {}
    self.affectedBy = {}  -- Table to keep track of affecting catalytes
    self.state = "normal" -- Possible states: "normal", "hot", "cold"
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
        -- Calculate shortest wrap-around distance to neighbor
        local dx = neighbor.position.x - self.position.x
        local dy = neighbor.position.y - self.position.y
        
        -- Adjust dx and dy for wrap-around
        dx = dx - WIDTH * math.floor((dx + WIDTH/2) / WIDTH)
        dy = dy - HEIGHT * math.floor((dy + HEIGHT/2) / HEIGHT)
        
        -- Add adjusted position
        averagePosition = averagePosition + vec2(self.position.x + dx, self.position.y + dy)
        total = total + 1
    end
    
    if total > 0 then
        averagePosition = averagePosition / total
        local difference = averagePosition - self.position
        local desiredVelocity = difference:normalize() * self.maxSpeed
        local steeringForce = desiredVelocity - self.velocity
        steeringForce = limit(steeringForce, self.maxForce)
        
        -- Make the steering force stronger based on distance to average position
        local distance = difference:len()
        steeringForce = steeringForce * (distance/ self.perceptionRadius)
        return steeringForce
    else
        return vec2(0, 0)
    end
end

-- Mote drawing function
--[[
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

]]

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
--[[
function Mote:drawllll()
    pushStyle()
    spriteMode(CORNER)
    fill(self.color)
    
    -- Since we're drawing to a buffer, we no longer need to adjust for zoomLevel here.
    -- The decision to draw an emoji or a dot can be based on a global state or condition.
    if shouldDrawEmoji then -- This condition needs to be defined based on your application logic
        fontSize(BASE_EMOJI_SIZE) -- Adjust fontSize based on your application needs
        local textWidth, textHeight = textSize("😀")
        -- Draw the emoji centered on the mote's position
        text("😀", self.position.x - textWidth / 2, self.position.y - textHeight / 2)
    else
        -- Draw simple dot at the mote's position
        ellipse(self.position.x, self.position.y, self.size)
    end
    
    popStyle()
end


function Mote:draw()

pushStyle()
fill(self.color)
spriteMode(CORNER)

-- Calculate the mote's scaled and repositioned coordinates
local scale = WIDTH / zoomScroller.frame.width
local posX = (self.position.x - zoomScroller.frame.x) * scale
local posY = (self.position.y - zoomScroller.frame.y) * scale
local scaledSize = self.size * scale

-- Draw the mote at the scaled and repositioned coordinates
ellipse(posX, posY, scaledSize)

popStyle()
end


function Mote:draw(frame)
    pushStyle()
    fill(self.color)
    noStroke()
    
    -- Calculate the scaled position and size of the mote
    local aScale = WIDTH / frame.width -- Assuming the original WIDTH is the base
    -- Adjusting for the frame being centered
    local centerX = frame.width / 2 + frame.x
    local centerY = frame.height / 2 + frame.y
    local posX = (self.position.x - centerX) * aScale + WIDTH
    local posY = (self.position.y - centerY) * aScale + HEIGHT
    local scaledSize = self.size * aScale
    
    -- Draw the mote
    ellipse(posX, posY, scaledSize)
    popStyle()
end


function Mote:drawwwww(frame)
    pushStyle()
    fill(self.color)
    noStroke()
    
    -- Calculate the scaled position and size of the mote
    local aScale = frame.width / WIDTH-- Assuming the original WIDTH is the base
    -- Adjusting for the frame being centered
    local centerX = frame.width / 2 + frame.x
    local centerY = frame.height / 2 + frame.y
    local posX = (self.position.x - frame.x) * aScale + WIDTH
    local posY = (self.position.y - frame.y) * aScale + HEIGHT
    local scaledSize = self.size * aScale
    
    -- Draw the mote
    ellipse(posX, posY, scaledSize)
    popStyle()
end

function Mote:draw(frame)
    pushStyle()
    fill(self.color)
    noStroke()
    
    -- Recalculate the scale based on frame width relative to the original viewport width
    local aScale = WIDTH / frame.width
    
    -- Adjust position calculations given that frame.x and frame.y are the center
    local posX = (self.position.x - (frame.x - frame.width / 2)) * aScale
    local posY = (self.position.y - (frame.y - frame.height / 2)) * aScale
    
    local scaledSize = self.size * aScale
    
    -- Draw the mote
    ellipse(posX, posY, scaledSize)
    popStyle()
end

function Mote:draw(frame)
    pushStyle()
    fill(self.color)
    noStroke()
    
    -- Recalculate the scale based on frame width relative to the original viewport width
    local aScale = frame.width / WIDTH
    
    -- Adjust position calculations given that frame.x and frame.y are the center
    local posX = (self.position.x + (frame.x - frame.width / 2)) * aScale
    local posY = (self.position.y + (frame.y - frame.height / 2)) * aScale
    
    local scaledSize = self.size * aScale
    
    -- Draw the mote
    ellipse(posX, posY, scaledSize)
    popStyle()
end
]]

--correct scrolling:
function Mote:draw(frame)
    pushStyle()
    fill(self.color)
    noStroke()
    
    -- Directly apply the frame's position and size to calculate the mote's position.
    -- Scale is determined by the frame width relative to the initial viewport width (WIDTH).
    local scaleRatio = frame.width / WIDTH
    
    -- Calculate the mote's position considering the frame's bottom-left as the origin.
    -- frame.x and frame.y denote the center; adjust to find the bottom-left corner.
    local bottomLeftX = frame.x - (frame.width / 2)
    local bottomLeftY = frame.y - (frame.height / 2)
    
    -- Adjust the mote's position based on the bottom-left origin.
    local posX = (self.position.x + bottomLeftX) * scaleRatio
    local posY = (self.position.y + bottomLeftY) * scaleRatio
    
    -- Scale the mote's size according to the same ratio.
    local adjustedSize = self.size * scaleRatio
    
    -- Draw the mote at the new position with the adjusted size.
    ellipse(posX, posY, adjustedSize)
    
    popStyle()
end

function Mote:draw(frame)
    pushStyle()
    fill(self.color)
    noStroke()
    
    -- Calculate the effective startX and startY based on the frame being centered
    -- and the fact that 0,0 is at the lower left in Codea coordinates.
    local effectiveStartX = (frame.x - frame.width / 2)
    local effectiveStartY = (frame.y - frame.height / 2)
    
    -- Adjust mote's position considering the frame's center and the increase direction of coordinates.
    -- Here, posX and posY calculate positions from the bottom-left corner, considering the frame's adjustments.
    local posX = effectiveStartX + (self.position.x * (frame.width / WIDTH))
    local posY = effectiveStartY + (self.position.y * (frame.height / HEIGHT))
    
    local adjustedSize = self.size * (frame.width / WIDTH)
    
    -- Draw the mote at the new position with its original size.
    ellipse(posX, posY, adjustedSize)
    
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