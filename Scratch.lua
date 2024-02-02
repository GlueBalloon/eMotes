function Mote:clump(neighbors)
    local averagePosition = vec2(0, 0)
    local total = 0
    
    for _, neighbor in ipairs(neighbors) do
        -- Calculate shortest wrap-around distance to neighbor
        local dx = neighbor.position.x - self.position.x
        local dy = neighbor.position.y - self.position.y
        
        -- Adjust dx and dy for wrap-around
        dx = dx - WIDTH * math.floor((dx + WIDTH/2) / WIDTH)
        dy = dy - HEIGHT * math.floor((dy + HEIGHT/2) / HEIGHT)
        
        -- Add adjusted position
        averagePosition = averagePosition + vec2(self.position.x + dx, self.position.y + dy)
        total = total + 1
    end
    
    if total > 0 then
        averagePosition = averagePosition / total
        local difference = averagePosition - self.position
        local desiredVelocity = difference:normalize() * self.maxSpeed
        local steeringForce = desiredVelocity - self.velocity
        steeringForce = limit(steeringForce, self.maxForce)
        
        -- Make the steering force stronger based on distance to average position
        local distance = difference:len()
        steeringForce = steeringForce * (distance/ self.perceptionRadius)
        return steeringForce
    else
        return vec2(0, 0)
    end
end