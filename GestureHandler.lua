
    --to be refactored into a gesture handler soon
    
function ZoomScroller:doubleTapCallback(event)
    testprint("doubleTapCallback called")
    -- Convert the zoomed position to an absolute position
    local absX, absY = self:zoomedPosToAbsolutePos(event.x, event.y)
    if not absX or not absY then return end -- Early exit if conversion failed
    -- Calculate the grid cell coordinates
    local gridX = math.floor(absX / gridSize) + 1
    local gridY = math.floor(absY / gridSize) + 1
    
    -- Access the motes in the identified grid cell
    local motesInCell = currentGrid[gridX] and currentGrid[gridX][gridY]
    
    if motesInCell then
        testprint("motes found in cell")
        for _, mote in ipairs(motesInCell) do
            -- Check if the mote's drawingParams place it under the tap
            local dp = mote.drawingParams
            if dp then
                -- Check if the tap is within the mote's on-screen bounds
                local left = dp.x - dp.size / 2
                local right = dp.x + dp.size / 2
                local bottom = dp.y - dp.size / 2
                local top = dp.y + dp.size / 2
                
                if event.x >= left and event.x <= right and event.y >= bottom and event.y <= top then
                    print("Tapped on mote:", mote.emoji or "no emoji", "at:", dp.x, dp.y)
                    self.trackedMote = mote
                    return -- Exit after finding the first mote that matches to avoid multiple selections
                end
            end
        end
    end
    self.trackedMote = nil
end







