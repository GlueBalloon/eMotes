-- Mote class
Mote = class()

function Mote:randomStartEmoji()
    local startEmojis = {"😀", "😃", "😄", "😁", "😆", "😅", "😊", "😇", 
    "🙂", "🙃", "😉", "😌", "😗", "😙", "😚", "😋", "😛", "😝", "😜", 
    "🤪", "🤨", "🧐", "🤓", "😎", "😏", "😒", "😔", "😟", "😕", 
    "🙁", "🥺", "😢", "😠", "🤐", "🥴",
    "😳", "🤔", "🤭", "🤫", "🤥", "😶", "😐", 
    "😑", "😬", "🙄", "😯", "😴", "🤤",
    "😷", "🤒", "🤕", "🤠"}
    return startEmojis[math.random(#startEmojis)]
end

function Mote:init(x, y)
    self.size = MOTE_SIZE
    self.emoji = math.random() < 0.4 and self:randomStartEmoji() or "😀"
    self.defaultEmoji = self.emoji
    self.position = vec2(x or math.random(WIDTH), y or math.random(HEIGHT))
    self.velocity = vec2(math.random() * 4 - 2, math.random() * 4 - 2)
    self.maxSpeed = MOTE_SPEED_DEFAULT + (math.random() * 0.05)
    self.noiseOffset = math.random() * 1000
    self.perceptionRadius = 6 -- Adjust as needed
    self.maxForce = math.random() * 2 -- Adjust as needed
    self.defaultColor = color(248, 211, 15)
    self.color = self.defaultColor
    self.currentAffecting = {}
    self.affectedBy = {}  -- Table to keep track of affecting catalytes
    self.state = "normal" -- Possible states: "normal", "hot", "cold"
end

function Mote:updateAppearance()
    --skip if this mote is a catalyte itself
    if self.applyEffect then return end
    --[[
    --code commented out but left in as a reminder:
    --randomly removing special-case emoji feels
    --disappointing to a viewer
    if math.random() < 0.01 then
        if self.emoji == "😀" then
            self.emoji = self:randomStartEmoji()
        else  
            self.emoji = "😀"
        end
    end
    ]]
    if self.state == "hot" then
        self.emoji = "🥵"
        self.color = color(229, 143, 46) -- Hot color
    elseif self.state == "cold" then
        self.emoji = "🥶"
        self.color = color(90, 183, 224) -- Cold color
    else
        self.emoji = self.defaultEmoji
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

function Mote:draw(frame)
    pushStyle()
    fill(self.color)
    noStroke()
    spriteMode(CENTER)
    -- Calculate the effective startX and startY based on the frame being centered
    -- and the fact that 0,0 is at the lower left in Codea coordinates.
    local effectiveStartX = (frame.x - frame.width / 2)
    local effectiveStartY = (frame.y - frame.height / 2)
    
    -- Adjust mote's position considering the frame's center and the increase direction of coordinates.
    -- Here, posX and posY calculate positions from the bottom-left corner, considering the frame's adjustments.
    local posX = effectiveStartX + (self.position.x * (frame.width / WIDTH))
    local posY = effectiveStartY + (self.position.y * (frame.height / HEIGHT))
    
    local adjustedSize = self.size * (frame.width / WIDTH)
    local transitionalSize = 8 -- your defined value or logic here
    
    if adjustedSize >= transitionalSize then
        if self.color == self.defaultColor then
            fill(255)--to remove tint from emoji normally
        end
        local textRatio = adjustedSize / self.size
        fontSize(BASE_EMOJI_SIZE * textRatio)
        local textWidth, textHeight = textSize("😀")
        local textX = posX - textWidth / 2
        local textY = posY - textHeight / 2
        -- Draw the emoji centered on the mote's position
        text(self.emoji, posX, posY)
    else
        -- Draw simple dot at the mote's position
        ellipse(posX, posY, adjustedSize)
    end
    
    popStyle()
end
]]

function Mote:isVisibleInSingle(frame, visibleAreas)
    if not visibleAreas then return false end -- Handle case of no visible area
    
    -- Adjust mote's position based on the frame's center coordinates
    local adjustedPosX = frame.x + (self.position.x - WIDTH / 2) * (frame.width / WIDTH)
    local adjustedPosY = frame.y + (self.position.y - HEIGHT / 2) * (frame.height / HEIGHT)
    
    -- Check if the mote's adjusted position is within the calculated visible areas
    return adjustedPosX >= visibleAreas.left and adjustedPosX <= visibleAreas.right and
    adjustedPosY >= visibleAreas.bottom and adjustedPosY <= visibleAreas.top
end

function Mote:isVisibleIn(frame, visibleAreas)
    for _, area in ipairs(visibleAreas) do
        -- Adjust mote's position based on the frame's center coordinates
        local adjustedPosX = frame.x + (self.position.x - WIDTH / 2) * (frame.width / WIDTH)
        local adjustedPosY = frame.y + (self.position.y - HEIGHT / 2) * (frame.height / HEIGHT)
        -- Check if the mote's position is within any of the calculated visible areas
        if adjustedPosX >= area.left and adjustedPosX <= area.right and
        adjustedPosY >= area.bottom and adjustedPosY <= area.top then
            return true
        end
    end
    return false
end

function Mote:drawWithParams(x, y, size)
    pushStyle()
    fill(self.color)
    noStroke()
    spriteMode(CENTER)
    local transitionalSize = 8 -- your defined value or logic here
    -- Use the provided x, y, and size to draw
    if size >= transitionalSize then
        fill(255)
        fontSize(BASE_EMOJI_SIZE * (size / self.size))  -- Adjust fontSize based on the new size
        text(self.emoji, x, y)
    else
        ellipse(x, y, size)
    end
    popStyle()
end



-- Catalyte class
Catalyte = class(Mote)

function Catalyte:init(x, y, effectRadius)
    Mote.init(self, x, y)  -- Adjust effect radius as needed
    self.size = MOTE_SIZE * 1.25
    self.effectRadius = effectRadius or MOTE_SIZE * 4.5
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
    self.color = color(255, 157, 0)  -- Warm color for the sun
    self.emoji = "🌞"
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
    self.emoji = "❄️"
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