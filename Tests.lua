PRINTALITTLETIME = 1.02

function printALittle(aString)
    if ElapsedTime < PRINTALITTLETIME then
        print(aString)
    end
end

function testNeighborDetection()
    -- Create test motes
    local testMotes = {
        Mote(100, 100),  -- Mote 1
        Mote(105, 100),  -- Mote 2, close to Mote 1
        Mote(300, 300),  -- Mote 3, far from Mote 1 and 2
    }
    
    -- Clear the grid
    grid = {}
    
    -- Update grid with test motes
    for _, mote in ipairs(testMotes) do
        updateGrid(mote)
        --       print("Updated grid for mote at " .. tostring(mote.position))
    end
    
    -- Check grid contents (Debugging)
    for x, col in pairs(grid) do
        for y, cell in pairs(col) do
            --            print("Grid cell [" .. x .. "," .. y .. "] has " .. #cell .. " motes.")
        end
    end
    
    -- Run neighbor detection for each mote
    for _, mote in ipairs(testMotes) do
        local neighbors = checkForNeighbors(mote, grid)
        
        -- Print results for debugging
        print("Mote at " .. tostring(mote.position) .. " has " .. #neighbors .. " neighbors.")
        for _, neighbor in ipairs(neighbors) do
            print(" - Neighbor at " .. tostring(neighbor.position))
        end
    end
end
    
function testWrappedNeighbors()
    -- Setup
    local currentGrid = {}
    local testMotes = {}
    local screenSize = vec2(WIDTH, HEIGHT)
    local testGridSize = 50 -- Assuming this is the grid size used in your main code
    
    -- Create motes near the edges of the screen
    table.insert(testMotes, Mote(1, 1)) -- Top-left corner
    table.insert(testMotes, Mote(screenSize.x - 1, 1)) -- Top-right corner
    table.insert(testMotes, Mote(1, screenSize.y - 1)) -- Bottom-left corner
    table.insert(testMotes, Mote(screenSize.x - 1, screenSize.y - 1)) -- Bottom-right corner
    
    -- Insert a mote near the center for control
    table.insert(testMotes, Mote(screenSize.x / 2, screenSize.y / 2))
    
    -- Run checkForNeighbors on each mote
    for _, mote in ipairs(testMotes) do
        updateGrid(mote) -- Update grid for each mote
        mote.neighbors = checkForNeighbors(mote, currentGrid) -- Check neighbors
    end
    
    -- Check results
    for i, mote in ipairs(testMotes) do
        print("Mote " .. i .. " has " .. #mote.neighbors .. " neighbors.")
    end
end
