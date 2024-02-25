function ZoomScroller:frameToViewMapping(frame)
    local tilesX, tilesY = math.ceil(WIDTH / frame.width), math.ceil(HEIGHT / frame.height)
    local allMappings = {}
    
    for i = -1, tilesX do
        for j = -1, tilesY do
            local startX = frame.x + (i * frame.width) - frame.width / 2
            local startY = frame.y + (j * frame.height) - frame.height / 2
            
            local visibleAreaLeft = math.max(startX, 0)
            local visibleAreaRight = math.min(startX + frame.width, WIDTH)
            local visibleAreaTop = math.min(startY + frame.height, HEIGHT)
            local visibleAreaBottom = math.max(startY, 0)
            
            if visibleAreaRight > visibleAreaLeft and visibleAreaTop > visibleAreaBottom then
                local absoluteSourceRatios = {
                    xR = (visibleAreaLeft) / WIDTH,
                    wR = (visibleAreaRight - visibleAreaLeft) / WIDTH,
                    yR = (HEIGHT - visibleAreaTop) / HEIGHT,
                    hR = (visibleAreaTop - visibleAreaBottom) / HEIGHT,
                }
                
                local zoomedSectionRatios = {
                    xR = (visibleAreaLeft - startX) / frame.width,
                    wR = (visibleAreaRight - visibleAreaLeft) / frame.width,
                    yR = (startY + frame.height - visibleAreaTop) / frame.height,
                    hR = (visibleAreaTop - visibleAreaBottom) / frame.height,
                }
                
                local zoomedSectionBounds = {
                    width = absoluteSourceRatios.wR * WIDTH,
                    height = absoluteSourceRatios.hR * HEIGHT,
                    left = absoluteSourceRatios.xR * WIDTH,
                    bottom = HEIGHT - absoluteSourceRatios.yR * HEIGHT - (absoluteSourceRatios.hR * HEIGHT),
                }
                
                local absoluteSourceBounds = {
                    width = zoomedSectionRatios.wR * WIDTH,
                    height = zoomedSectionRatios.hR * HEIGHT,
                    left = zoomedSectionRatios.xR * WIDTH,
                    bottom = HEIGHT - zoomedSectionRatios.yR * HEIGHT - (zoomedSectionRatios.hR * HEIGHT),
                }
                
                table.insert(allMappings, {
                    absoluteSourceRatios = absoluteSourceRatios,
                    zoomedSectionRatios = zoomedSectionRatios,
                    absoluteSourceBounds = absoluteSourceBounds,
                    zoomedSectionBounds = zoomedSectionBounds,
                })
            end
        end
    end
    
    return allMappings
end

function ZoomScroller:getDrawingParameters3(nativePosition, nativeSize, allMappings)
    for index, mapping in ipairs(allMappings) do
        local absoluteSourceBounds = mapping.absoluteSourceBounds
        local zoomedSectionBounds = mapping.zoomedSectionBounds
        
        -- Check if the mote's native position is within the absolute source area before adjustment
        if nativePosition.x >= absoluteSourceBounds.left and nativePosition.x <= (absoluteSourceBounds.left + absoluteSourceBounds.width) and
        nativePosition.y >= absoluteSourceBounds.bottom and nativePosition.y <= (absoluteSourceBounds.bottom + absoluteSourceBounds.height) then
            
            local zoomRatioWidth = zoomedSectionBounds.width / absoluteSourceBounds.width
            local zoomRatioHeight = zoomedSectionBounds.height / absoluteSourceBounds.height
            
            -- Apply the displacement to the mote's position
            local displacementX = zoomedSectionBounds.left - absoluteSourceBounds.left
            local displacementY = zoomedSectionBounds.bottom - absoluteSourceBounds.bottom
            local adjustedPosX = (nativePosition.x - absoluteSourceBounds.left) * zoomRatioWidth + absoluteSourceBounds.left + displacementX
            local adjustedPosY = (nativePosition.y - absoluteSourceBounds.bottom) * zoomRatioHeight + absoluteSourceBounds.bottom + displacementY
            
            local adjustedSize = nativeSize * (zoomRatioWidth + zoomRatioHeight) / 2  -- Average of width and height zoom ratio for uniform scaling
            
            -- The mote is within the visible zoomed section, return the adjusted position and size
            return {
                x = adjustedPosX,
                y = adjustedPosY,
                size = adjustedSize
            }
        end
    end
    
    -- Return nil if the mote isn't within any visible zoomed section
    return nil
end