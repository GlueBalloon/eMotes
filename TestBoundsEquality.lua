function ZoomScroller:testAllBoundsEquality(frame)
    -- Generate allBounds using the original two-step approach
    local visibleFrameRatios, visibleScreenAreas = self:visibleWrappedOnscreenAndFrameRatios2(frame)
    local allBoundsOriginal = self:calculateAllBounds(visibleFrameRatios, visibleScreenAreas)
    
    -- Generate allBounds using the single-step approach
    local allBoundsSingleStep = self:frameToAllBounds(frame)
    
    local discrepancies = {}
    
    -- Check if both allBounds tables have the same number of entries
    if #allBoundsOriginal ~= #allBoundsSingleStep then
        table.insert(discrepancies, "Mismatch in number of bounds entries.")
    else
        -- Compare each corresponding element
        for i = 1, #allBoundsOriginal do
            local original = allBoundsOriginal[i]
            local singleStep = allBoundsSingleStep[i]
            
            -- Compare screenRatios and frameRatios
            if not self:ratiosAreEqual(original.screenRatios, singleStep.screenRatios) or
            not self:ratiosAreEqual(original.frameRatios, singleStep.frameRatios) then
                table.insert(discrepancies, "Ratio mismatch at index " .. i)
            end
            
            -- Compare screenBounds and frameBounds
            if not self:boundsAreEqual(original.screenBounds, singleStep.screenBounds) or
            not self:boundsAreEqual(original.frameBounds, singleStep.frameBounds) then
                table.insert(discrepancies, "Bounds mismatch at index " .. i)
            end
        end
    end
    
    -- Print discrepancies or pass message
    if #discrepancies > 0 then
        print("Test Failed: Found discrepancies.")
        for _, discrepancy in ipairs(discrepancies) do
            print(discrepancy)
        end
        -- Print the entire tables for comparison
        print("Original allBounds:")
        self:printAllBounds(allBoundsOriginal)
        print("SingleStep allBounds:")
        self:printAllBounds(allBoundsSingleStep)
    else
        print("Test Passed: All bounds and ratios match.")
    end
end

function ZoomScroller:printAllBounds(allBounds)
    for i, bounds in ipairs(allBounds) do
        print("Index " .. i .. ":")
        print("  Screen Ratios:", self:formatRatios(bounds.screenRatios))
        print("  Frame Ratios:", self:formatRatios(bounds.frameRatios))
        print("  Screen Bounds:", self:formatBounds(bounds.screenBounds))
        print("  Frame Bounds:", self:formatBounds(bounds.frameBounds))
    end
end

function ZoomScroller:formatRatios(ratios)
    local xR = ratios.xR and tostring(ratios.xR) or "nil"
    local wR = ratios.wR and tostring(ratios.wR) or "nil"
    local yR = ratios.yR and tostring(ratios.yR) or "nil"
    local hR = ratios.hR and tostring(ratios.hR) or "nil"
    return "xR: " .. xR .. ", wR: " .. wR .. ", yR: " .. yR .. ", hR: " .. hR
end

function ZoomScroller:formatBounds(bounds)
    return "left: " .. bounds.left .. ", width: " .. bounds.width .. ", bottom: " .. bounds.bottom .. ", height: " .. bounds.height
end

function ZoomScroller:ratiosAreEqual(ratio1, ratio2)
    return ratio1.xR == ratio2.xR and ratio1.wR == ratio2.wR and
    ratio1.yR == ratio2.yR and ratio1.hR == ratio2.hR
end

function ZoomScroller:boundsAreEqual(bounds1, bounds2)
    return bounds1.left == bounds2.left and bounds1.width == bounds2.width and
    bounds1.bottom == bounds2.bottom and bounds1.height == bounds2.height
end