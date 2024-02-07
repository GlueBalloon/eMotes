
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
    setContext(drawingBuffer)
    background(40, 40, 50)
    pushStyle()
    strokeWidth(10)
    stroke(255, 14, 0)
    noFill()
    rect(0,0,WIDTH, HEIGHT)
    popStyle()
    
    aScale = WIDTH / zoomScroller.frame.width -- Assuming the original WIDTH is the base
    local offsetX = zoomScroller.frame.x
    local offsetY = zoomScroller.frame.y
    
    
    for i, mote in ipairs(motes) do
        updateGrid(mote, nextGrid)
        checkForNeighbors(mote, currentGrid)  -- Pass currentGrid for neighbor checking
        mote:update()
        -- Calculate screen position for each mote based on zoomScroller's frame
        --  local screenPos = vec2((mote.position.x * aScale) - offsetX, (mote.position.y * aScale) - offsetY)
        
        -- Use isMoteVisible adjusted for zoomScroller's frame (implementation needed)
        -- if isMoteVisible(mote, zoomScroller.frame) then
        -- Draw mote at calculated screen position with adjusted scale
        mote:draw()
        --  end
    end
    
    
    -- Reset the drawing context to the screen
    setContext()
    
    -- Use ZoomScroller to draw the displayBuffer tiled across the screen
    zoomScroller:drawTiledImageInBounds(displayBuffer)
    -- Swap grids
    
    currentGrid, nextGrid = nextGrid, currentGrid
end

function isMoteVisible(mote)
    local screenPos = vec2((mote.position.x + zoomScroller.frame.x) * (zoomScroller.frame.width / WIDTH), (mote.position.y + zoomScroller.frame.y) * (zoomScroller.frame.height / HEIGHT))
    return screenPos.x >= 0 and screenPos.x <= WIDTH and screenPos.y >= 0 and screenPos.y <= HEIGHT
end



