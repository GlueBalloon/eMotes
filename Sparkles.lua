Sparkle = class()

function Sparkle:init()
    -- Random position on the screen
    self.x = math.random(WIDTH)
    self.y = math.random(HEIGHT)
    
    -- Random size and speed
    self.size = math.random(5, 15)
    self.speed = math.random(1, 3)
    
    -- Random floatingDot color
    self.color = color(math.random(150, 255), math.random(150, 255), math.random(150, 255), math.random(100, 255))
    
    -- Random direction
    self.dx = math.random(-1, 1)
    self.dy = math.random(-1, 1)
end

function Sparkle:update()
    -- Update position
    self.x = self.x + self.dx * self.speed
    self.y = self.y + self.dy * self.speed
    
    -- Wrap around the screen edges
    if self.x < 0 then self.x = WIDTH end
    if self.x > WIDTH then self.x = 0 end
    if self.y < 0 then self.y = HEIGHT end
    if self.y > HEIGHT then self.y = 0 end
end

function Sparkle:draw()
    pushStyle()
    fill(self.color)
    noStroke()
    ellipse(self.x, self.y, self.size)
    popStyle()
end





