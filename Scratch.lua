

--[[
function zoomCallback(event)
    if zoomActive then
        local touch1 = event.touches[1]
        local touch2 = event.touches[2]
        
        -- Calculate the midpoint of the two touches
        zoomOrigin = vec2((touch1.x + touch2.x) / 2, (touch1.y + touch2.y) / 2)
        
        local zoomChange = 1 + (event.dw + event.dh) / 1200 -- Adjust the denominator to control zoom sensitivity
        zoomLevel = zoomLevel * zoomChange
        zoomLevel = math.max(1, math.min(zoomLevel, 10)) -- Limit the zoom level
    end
end

function zoomCallback(event)
if zoomActive then
-- Extract touch points
local touch1 = event.touches[1]
local touch2 = event.touches[2]

-- Calculate the midpoint of the two touches
local midpoint = vec2((touch1.x + touch2.x) / 2, (touch1.y + touch2.y) / 2)

-- Calculate the initial distance between the two touches
local initialDistance = vec2(touch1.prevX - touch2.prevX, touch1.prevY - touch2.prevY):len()

-- Calculate the current distance between the two touches
local currentDistance = vec2(touch1.x - touch2.x, touch1.y - touch2.y):len()

-- Calculate the zoom change based on the ratio of current distance to initial distance
local zoomChange = currentDistance / initialDistance

-- Update the zoom level
zoomLevel = zoomLevel * zoomChange
zoomLevel = math.max(1, math.min(zoomLevel, 10)) -- Limit the zoom level

-- Adjust the zoom origin to keep the midpoint under the user's fingers stable
zoomOrigin = (zoomOrigin - midpoint) * zoomChange + midpoint
end
end
]]
function zoomCallback(event)
    if zoomActive then
        -- Extract touch points
        local touch1 = event.touches[1]
        local touch2 = event.touches[2]
        
        -- Calculate the midpoint of the two touches
        local midpoint = vec2((touch1.x + touch2.x) / 2, (touch1.y + touch2.y) / 2)
        
        -- Calculate the initial distance between the two touches
        local initialDistance = vec2(touch1.prevX - touch2.prevX, touch1.prevY - touch2.prevY):len()
        
        -- Calculate the current distance between the two touches
        local currentDistance = vec2(touch1.x - touch2.x, touch1.y - touch2.y):len()
        
        -- Calculate the zoom change based on the ratio of current distance to initial distance
        local zoomChange = currentDistance / initialDistance

        -- Adjust the zoom origin to the midpoint of the gesture
        if touch1.state == BEGAN or touch2.state == BEGAN then
            zoomOrigin = midpoint
        end
        
        -- Update the zoom level
        zoomLevel = zoomLevel * zoomChange
        zoomLevel = math.max(1, math.min(zoomLevel, 10)) -- Limit the zoom level

    end
end

function zoomCallback(event)
    if zoomActive then
        local touch1 = event.touches[1]
        local touch2 = event.touches[2]
        
        -- Calculate the midpoint of the two touches in screen coordinates
        local midpoint = vec2((touch1.x + touch2.x) / 2, (touch1.y + touch2.y) / 2)
        
        -- Calculate the zoom change based on touch movement
        local zoomChange = calculateZoomChange(touch1, touch2)
        
        -- Adjust the midpoint by "unzooming" it to what it would be at zoomLevel = 1
        local adjustedMidpoint = (midpoint - zoomOrigin) / zoomLevel + zoomOrigin
        zoomOrigin = adjustedMidpoint + zoomOrigin
        
        -- Apply the zoom change
        zoomLevel = zoomLevel * zoomChange
     --   zoomLevel = math.max(1, math.min(zoomLevel, 10))  -- Limit the zoom level
        
        -- Update the zoom origin to the adjusted midpoint
        zoomOrigin = adjustedMidpoint
    end
end

function calculateZoomChange(touch1, touch2)
    -- Calculate the initial distance between the two touches
    local initialDistance = vec2(touch1.prevX - touch2.prevX, touch1.prevY - touch2.prevY):len()
    
    -- Calculate the current distance between the two touches
    local currentDistance = vec2(touch1.x - touch2.x, touch1.y - touch2.y):len()
    
    -- Calculate the zoom change based on the ratio of current distance to initial distance
    local zoomChange = currentDistance / initialDistance
    
    return zoomChange
end

function zoomCallback(event)
    if zoomActive then
        local touch1 = event.touches[1]
        local touch2 = event.touches[2]
        
        -- Calculate the midpoint of the two touches
        local midpoint = vec2((touch1.x + touch2.x) / 2, (touch1.y + touch2.y) / 2)
        
        -- Calculate the initial and current distances between touches
        local initialDistance = vec2(touch1.prevX - touch2.prevX, touch1.prevY - touch2.prevY):len()
        local currentDistance = vec2(touch1.x - touch2.x, touch1.y - touch2.y):len()
        
        -- Calculate zoom change based on distance ratio
        local zoomChange = currentDistance / initialDistance
        
        -- Directly apply zoom change to zoom level
        zoomLevel = zoomLevel * zoomChange
        
        -- Remove any constraints on zoom level here if needed
        zoomLevel = math.max(1, zoomLevel) -- Example constraint removal
        
        -- Adjust zoom origin directly without constraints
        zoomOrigin = midpoint
    end
end

