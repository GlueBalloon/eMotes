function updateGrid(mote)
    local gridX = math.floor(mote.position.x / gridSize) + 1
    local gridY = math.floor(mote.position.y / gridSize) + 1
    
    grid[gridX] = grid[gridX] or {}
    grid[gridX][gridY] = grid[gridX][gridY] or {}
    
    table.insert(grid[gridX][gridY], mote)
    
    -- Debugging print

  --  printALittle("Placed mote at (" .. mote.position.x .. ", " ..
  --  mote.position.y .. ") in grid cell (" .. gridX .. ", " .. gridY .. ")")
  --  printALittle("grid cell count: "..#grid[gridX][gridY])
end
    
function printALittle(aString)
    if ElapsedTime < PRINTALITTLETIME then
        print(aString)
    end
end
    function checkForNeighbors(mote)
        local gridX = math.floor(mote.position.x / gridSize) + 1
        local gridY = math.floor(mote.position.y / gridSize) + 1
        local neighbors = {}
        
        for dx = -1, 1 do
            for dy = -1, 1 do
                local x = gridX + dx
                local y = gridY + dy
                if x > 0 and x <= math.ceil(WIDTH / gridSize) and y > 0 and y <= math.ceil(HEIGHT / gridSize) then
                    local cell = grid[x] and grid[x][y]
                    if cell then
              --      printALittle("cell "..x..", "..y.." count: "..#grid[x][y])
                        for _, neighbor in ipairs(cell) do
                            if neighbor ~= mote and mote.position:dist(neighbor.position) < gridSize then
                                table.insert(neighbors, neighbor)
                            end
                        end
                    end
                    -- Debugging print
                  --  printALittle("Checking cell (" .. x .. ", " .. y .. ") for mote at (" .. mote.position.x .. ", " .. mote.position.y .. ")")
                end
            end
        end
        
        return neighbors
    end