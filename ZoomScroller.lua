
--[[
function setup()
local spriteAsset = asset.builtin.Surfaces.Basic_Bricks_Color -- Example image, now used only in draw
zoomScroller = ZoomScroller(spriteAsset)

-- Setup sensor for pinch gestures
screen = {x=0, y=0, w=WIDTH, h=HEIGHT}
sensor = Sensor {parent=screen}
sensor:onZoom(function(event) 
zoomScroller:zoomCallback(event)
end)
end

function touched(touch)
-- Pass touch events to the sensor
sensor:touched(touch)
end

function draw()
background(40, 40, 50)
-- drawTiledImage function now uses the frame to draw the image within it
zoomScroller:drawTiledImageInBounds()
end
]]

ZoomScroller = class()

function ZoomScroller:init(anImage, x, y, width, height)
    -- Constructor for the ZoomableFrame class
    self.frame = {x = x or WIDTH / 2, y = y or HEIGHT / 2, width = width or WIDTH, height = height or HEIGHT, lastMidpoint = nil, initialDistance = nil}
    self.image = anImage
end

function ZoomScroller:repositionBoundsIfOffscreen()
    -- Reposition frame if offscreen
    local bounds = self.frame
    -- Check if bounds are offscreen to the right
    if bounds.x > WIDTH then
        bounds.x = bounds.x - 2 * bounds.width
    end
    -- Check if bounds are offscreen to the left
    if bounds.x + bounds.width < 0 then
        bounds.x = bounds.x + 2 * bounds.width
    end
    -- Check if bounds are offscreen to the bottom
    if bounds.y > HEIGHT then
        bounds.y = bounds.y - 2 * bounds.height
    end
    -- Check if bounds are offscreen to the top
    if bounds.y + bounds.height < 0 then
        bounds.y = bounds.y + 2 * bounds.height
    end
end

function ZoomScroller:zoomCallback(event)
    self:repositionBoundsIfOffscreen()
    
    local touch1 = event.touches[1]
    local touch2 = event.touches[2]
    
    local initialDistance = math.sqrt((touch1.prevX - touch2.prevX)^2 + (touch1.prevY - touch2.prevY)^2)
    local currentDistance = math.sqrt((touch1.x - touch2.x)^2 + (touch1.y - touch2.y)^2)
    local distanceChange = currentDistance - initialDistance
    
    local currentMidpoint = vec2((touch1.x + touch2.x) / 2, (touch1.y + touch2.y) / 2)
    
    if touch1.state == BEGAN or touch2.state == BEGAN then
        self.frame.lastMidpoint = currentMidpoint
        self.frame.initialDistance = initialDistance
    else
        local midpointChange = currentMidpoint - self.frame.lastMidpoint
        
        if distanceChange ~= 0 and self.frame.initialDistance then
            local scaleChange = currentDistance / self.frame.initialDistance
            self.frame.initialDistance = currentDistance
            
            local newWidth = self.frame.width * scaleChange
            local newHeight = self.frame.height * scaleChange
            
            if newWidth < WIDTH or newHeight < HEIGHT then
                return
            end
            
            local offsetX = (self.frame.width - newWidth) * ((currentMidpoint.x - self.frame.x) / self.frame.width)
            local offsetY = (self.frame.height - newHeight) * ((currentMidpoint.y - self.frame.y) / self.frame.height)
            
            self.frame.x = self.frame.x + offsetX
            self.frame.y = self.frame.y + offsetY
            self.frame.width = newWidth
            self.frame.height = newHeight
        end
        
        if midpointChange.x ~= 0 or midpointChange.y ~= 0 then
            self.frame.x = self.frame.x + midpointChange.x
            self.frame.y = self.frame.y + midpointChange.y
        end
        
        self.frame.lastMidpoint = currentMidpoint
    end
end

function ZoomScroller:drawTiledImageInBounds(anImageOrNot)
    pushStyle()
    spriteMode(CENTER)
    local anImage = anImageOrNot or self.image
    local bounds = self.frame
    local tilesX = math.ceil(WIDTH / bounds.width) + 1
    local tilesY = math.ceil(HEIGHT / bounds.height) + 1
    
    local startX = bounds.x % bounds.width
    if startX > 0 then startX = startX - bounds.width end
    
    local startY = bounds.y % bounds.height
    if startY > 0 then startY = startY - bounds.height end
    
    for i = -1, tilesX do
        for j = -1, tilesY do
            local x = startX + (i * bounds.width)
            local y = startY + (j * bounds.height)
            sprite(anImage, x, y, bounds.width, bounds.height)
        end
    end
    popStyle()
end
