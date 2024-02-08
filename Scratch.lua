function drawVisibleFrameArea(frame)
    pushStyle()
    noFill()
    stroke(0, 255, 0) -- Green color
    strokeWidth(10)
    
    -- Screen dimensions
    local screenWidth = WIDTH
    local screenHeight = HEIGHT
    
    -- Calculate the frame's bounds
    local frameLeft = frame.x - frame.width / 2
    local frameRight = frame.x + frame.width / 2
    local frameTop = frame.y + frame.height / 2
    local frameBottom = frame.y - frame.height / 2
    
    -- Determine the overlap between the frame and the screen
    local visibleLeft = math.max(frameLeft, 0)
    local visibleRight = math.min(frameRight, screenWidth)
    local visibleTop = math.min(frameTop, screenHeight)
    local visibleBottom = math.max(frameBottom, 0)
    
    -- Draw the rectangle around the visible part of the frame
    -- Ensure there's an actual overlap to draw
    if visibleLeft < visibleRight and visibleBottom < visibleTop then
        rect(visibleLeft, visibleBottom, visibleRight - visibleLeft, visibleTop - visibleBottom)
    end
    
    popStyle()
end