

--[[

function Mote:draw(frame)
    pushStyle()
    fill(self.color)
    noStroke()
    
    -- Calculate the scaled position and size of the mote
    local scale = WIDTH / frame.width -- Assuming the original WIDTH is the base
    local scaledSize = self.size * scale
    local posX = (self.position.x - frame.x) * scale
    local posY = (self.position.y - frame.y) * scale
    
    -- Draw the mote
    ellipse(posX, posY, scaledSize)
    popStyle()
end

function Mote:draw(frame)
    pushStyle()
    fill(self.color)
    noStroke()
    
    -- Calculate the scale factor based on the frame's width relative to the display width
    local scale = WIDTH / frame.width
    -- Calculate the scaled and translated positions
    local posX = ((self.position.x - frame.x) * scale)
    local posY = ((self.position.y - frame.y) * scale)
    
    -- Draw the mote at the corrected position and with the corrected size
    local scaledSize = self.size * scale
    ellipse(posX, posY, scaledSize)
    
    popStyle()
end
]]



--should draw zoomed motes not a zoomed image
function draw()
    
    -- Update frame count
    frameCount = frameCount + 1
    -- Calculate FPS every second
    if ElapsedTime - lastTime >= 1 then
        fps = frameCount / (ElapsedTime - lastTime)
        frameCount = 0
        lastTime = ElapsedTime
    end
    -- Clear the nextGrid for the next frame
    nextGrid = {}
    
    updateWindDirection()
    
    -- Determine the current drawing buffer and the buffer to display
    local drawingBuffer = useBufferA and bufferA or bufferB
    local displayBuffer = useBufferA and bufferB or bufferA
    
    -- Switch the buffer for the next frame
    useBufferA = not useBufferA
    
    -- Set the drawing context to the current drawing buffer
  --  setContext(drawingBuffer)
    local frame = zoomScroller.frame
    pushStyle()
    background(40, 40, 50)
    spriteMode(CENTER)
    
    pushStyle()
    strokeWidth(10)
    stroke(255, 14, 0)
    noFill()
    rect(frame.x - frame.width / 2, frame.y - frame.height / 2, frame.width, frame.height)
    popStyle()
    

    
    for i, mote in ipairs(motes) do
        updateGrid(mote, nextGrid)
        checkForNeighbors(mote, currentGrid)  -- Pass currentGrid for neighbor checking
        mote:update()
        -- Calculate screen position for each mote based on zoomScroller's frame
        --  local screenPos = vec2((mote.position.x * aScale) - offsetX, (mote.position.y * aScale) - offsetY)
        
        -- Use isMoteVisible adjusted for zoomScroller's frame (implementation needed)
        -- if isMoteVisible(mote, zoomScroller.frame) then
        -- Draw mote at calculated screen position with adjusted scale
        mote:draw(frame)
        --  end
    end
    
    
    -- Reset the drawing context to the screen
    popStyle()
  --  setContext()
    
    -- Use ZoomScroller to draw the displayBuffer tiled across the screen
 --   zoomScroller:drawTiledImageInBounds(displayBuffer)
    -- Swap grids
    
    currentGrid, nextGrid = nextGrid, currentGrid
end



