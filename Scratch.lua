function blendColor(color1, color2, intensity)
    return color(
    lerp(color1.r, color2.r, intensity),
    lerp(color1.g, color2.g, intensity),
    lerp(color1.b, color2.b, intensity)
    )
end

function lerp(a, b, t)
    return a + (b - a) * t
end