-- Mote class
Mote = class()
Mote.standardEmojis = {"😀", "😃", "😄", "😁", "😆", "😅", "😊", "😇", 
    "🙂", "🙃", "😉", "😌", "😗", "😙", "😚", "😋", "😛", "😝", "😜", 
    "🤪", "🤨", "🧐", "🤓", "😎", "😏", "😒", "😔", "😟", "😕", 
    "🙁", "🥺", "😢", "😠", "🤐", "🥴",
    "😳", "🤔", "🤭", "🤫", "🤥", "😶", "😐", 
    "😑", "😬", "🙄", "😯", "😴", "🤤",
    "😷", "🤒", "🤕", "🤠"}

function Mote:randomStandardEmoji()
    return self.standardEmojis[math.random(#Mote.standardEmojis)]
end

function Mote:init(x, y)
    self.size = MOTE_SIZE
    self.emoji = math.random() < 0.4 and self:randomStandardEmoji() or "😀"
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
    self.tapCount = 0
    self.velocityForRageMode = vec2(math.random(-1, 1) * 10, math.random(-1, 1) * 10)
end

function Mote:updateAppearance()
    --skip if this mote is a catalyte itself
    if self.applyEffect then return end
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

function Mote:draw()
    pushStyle()
    fill(self.color)
    noStroke()
    ellipse(self.position.x, self.position.y, self.size)
    popStyle()
end

function Mote:drawFromParams()
    local x, y, size = self.drawingParams.x, self.drawingParams.y, self.drawingParams.size
    pushStyle()
    fill(self.color)
    noStroke()
    spriteMode(CENTER)
    local transitionalSize = 8 -- your defined value or logic here
    -- Use the provided x, y, and size to draw
    if size >= transitionalSize then
        fill(255)
        fontSize(size * 0.75)
        text(self.emoji, x * 0.9969, y * 0.9992)
    else
        ellipse(x, y, size)
    end
    popStyle()
end

function Mote:startRageMode()
    local mote = self --shortcut for adapting some GPT code
    local jitterDuration = 1
    self.velocityForRageMode = vec2(math.random(-1, 1) * 30, math.random(-1, 1) * 30) 
    -- Start jitter as a buildup to rage mode
    self:createChainedJitterSequence(jitterDuration, 1.25, 20, function()
        -- After jitter completes, start the rage mode
        self.isAnimating = true
        self.velocityForRageMode = vec2(math.random(-5, 5), math.random(-5, 5))  -- Assign random velocity
--        self.velocityForRageMode = vec2(math.random(-1, 1) * 1, math.random(-1, 1) * 1) 
                
        local rageTime = 8  -- Duration of rage mode in seconds
        local startTime = os.clock() + jitterDuration -- Capture the start time for rage mode
        
        local function rageUpdate()
                if os.clock() - startTime >= rageTime then
                    -- End rage mode
                    mote.state = "normal"
                    mote.tapCount = 0
                    mote.isAnimating = false
                    mote.emoji = mote.originalEmoji  -- Reset emoji
                    --mote.velocityForRageMode = vec2(0, 0)  -- Stop moving
                    self:decelerate(1)
                    return
                end
                
                -- Update mote position based on velocity
                mote.position.x = mote.position.x + mote.velocityForRageMode.x
                mote.position.y = mote.position.y + mote.velocityForRageMode.y
                
                -- Determine current grid cell and check for collisions
                local neighbors = checkForNeighbors(mote, currentGrid)
                for _, neighbor in ipairs(neighbors) do
                    if isColliding(mote, neighbor) then
                        -- Reflect the enraged mote's velocity
                        local dx = mote.position.x - neighbor.position.x
                        local dy = mote.position.y - neighbor.position.y
                        local angle = math.atan(dy, dx)
                        mote.velocityForRageMode = vec2(math.cos(angle), math.sin(angle)) * mote.velocityForRageMode:len()
                    end
                end
            self:handleCollisions()  -- Handle collisions
            -- Schedule next update
            if self.isAnimating then
                tween.delay(0.05, rageUpdate)
            end
        end
        
        rageUpdate()
    end)
end

function Mote:decelerate(decelerationTime)
    local initialVelocity = vec2(self.velocityForRageMode.x, self.velocityForRageMode.y)
    local decelerationRate = vec2(initialVelocity.x / decelerationTime, initialVelocity.y / decelerationTime)
    
    local function reduceSpeed(elapsedTime)
        if elapsedTime >= decelerationTime then
            self.velocityForRageMode = vec2(0, 0)  -- Stop moving
            self.isAnimating = false
            return
        end
        
        self.velocityForRageMode.x = initialVelocity.x - decelerationRate.x * elapsedTime
        self.velocityForRageMode.y = initialVelocity.y - decelerationRate.y * elapsedTime
        
        -- Update mote position based on decreasing velocity
        self.position.x = self.position.x + self.velocityForRageMode.x
        self.position.y = self.position.y + self.velocityForRageMode.y
        
        tween.delay(0.05, function() reduceSpeed(elapsedTime + 0.05) end)
    end
    
    reduceSpeed(0)  -- Start deceleration from t=0
end


function isColliding(mote1, mote2)
    local dist = vec2(mote1.position.x - mote2.position.x, mote1.position.y - mote2.position.y)
    return dist:len() <= (mote1.size / 2 + mote2.size / 2)
end

function Mote:createChainedJitterSequence(duration, intensity, numJitters, onComplete)
    -- Store original position only once at the beginning of the sequence
    local originalPosition = vec2(self.position.x, self.position.y)
    
    local function jitterStep(currentStep)
        if currentStep > numJitters then
            -- Ensure the mote returns to the original position at the end of the sequence
            self.position = originalPosition
            if onComplete then onComplete() end
            return
        end
        
        -- Apply jitter by setting a random offset from the original position
        self.position = vec2(
        originalPosition.x + (math.random() - 0.5) * 2 * intensity,
        originalPosition.y + (math.random() - 0.5) * 2 * intensity
        )
        
        -- Schedule the reset to original position
        tween.delay(duration / numJitters, function()
            self.position = originalPosition  -- Reset to original position after each jitter
            
            -- Delay before next jitter to make sure the reset is visible
            tween.delay(duration / (numJitters * 2), function()
                jitterStep(currentStep + 1)  -- Continue to the next jitter
            end)
        end)
    end
    
    -- Start the jitter sequence
    jitterStep(1)
end

function Mote:applyInstantVisualOffset(intensity)
    self.originalPosition = vec2(self.position.x, self.position.y)  -- Save the original position
    local randomOffset = vec2(
    (math.random() - 0.5) * 2 * intensity, 
    (math.random() - 0.5) * 2 * intensity
    )
    self.position = vec2(self.originalPosition.x + randomOffset.x, self.originalPosition.y + randomOffset.y)
end

function Mote:removeVisualOffset()
    self.position = self.originalPosition  -- Reset to the original position
end

function Mote:handleCollisions()
    local neighbors = checkForNeighbors(self, currentGrid)  -- Assuming this function returns nearby motes
    for _, neighbor in ipairs(neighbors) do
        if isColliding(self, neighbor) then
            -- Reflect the enraged mote's velocity
            local dx = self.position.x - neighbor.position.x
            local dy = self.position.y - neighbor.position.y
            local angle = math.atan(dy, dx)
            self.velocity = vec2(math.cos(angle), math.sin(angle)) * self.velocity:len()
            
            -- Apply jitter effect to the neighbor mote as a reaction to collision
            neighbor:createChainedJitterSequence(0.0051, 0.9, 5, function()
                -- Optional callback if needed after jitter
            end)
            
            -- Play collision sound, spatially adjusted
          --  self:playSpatialSound("path/to/pinball_collision.wav")
        end
    end
end





-- Catalyte class
Catalyte = class(Mote)

function Catalyte:init(x, y, effectRadius)
    Mote.init(self, x, y)  -- Adjust effect radius as needed
    self.size = MOTE_SIZE * 1.25
    self.effectRadius = effectRadius or MOTE_SIZE * 6.5
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