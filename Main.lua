MOTE_SIZE = 3
MOTE_COUNT = 3000
TIMESCALE = 1
WIND_ANGLE = 0
MOTE_SPEED_DEFAULT = 1.0
BASE_EMOJI_SIZE = MOTE_SIZE  -- Initial guess for text size
ZOOM_THRESHOLD = 1.7  -- Threshold for switching to emote drawing
-- Global variables
motes = {}
currentGrid = {}
nextGrid = {}
gridSize = 10  -- Adjust this value as needed
zoomLevel = 1.0
zoomOrigin = vec2(WIDTH / 2, HEIGHT / 2)
emojiSize = BASE_EMOJI_SIZE

-- Function to check if a mote is visible on screen
function isMoteVisible(mote)
    -- Calculate the transformed position
    local transformedX = (mote.position.x - zoomOrigin.x) * zoomLevel + zoomOrigin.x
    local transformedY = (mote.position.y - zoomOrigin.y) * zoomLevel + zoomOrigin.y
    
    -- Check if the transformed position is within screen bounds
    return transformedX >= 0 and transformedX <= WIDTH and transformedY >= 0 and transformedY <= HEIGHT
end

-- Function to calculate appropriate text size for emotes
function calculateTextSize()
    local targetWidth = MOTE_SIZE
    local currentWidth = 0
    local emote = "😀"  -- Example emote
    
    fontSize(BASE_EMOJI_SIZE)
    currentWidth = textSize(emote)
    
    while false and math.abs(currentWidth - targetWidth) > 1 do
        if currentWidth > targetWidth then
            BASE_EMOJI_SIZE = BASE_EMOJI_SIZE - 0.1
        else
            BASE_EMOJI_SIZE = BASE_EMOJI_SIZE + 0.1
        end
        fontSize(TEXT_SIZE)
        currentWidth = textSize(emote)
    end
    BASE_EMOJI_SIZE = BASE_EMOJI_SIZE * 0.85 -- artificial adjustment
    emojiSize = BASE_EMOJI_SIZE
    print(BASE_EMOJI_SIZE)
end

function setup()
    screen = {x=0,y=0,w=WIDTH,h=HEIGHT} 
    sensor = Sensor {parent=screen} -- tell the object you want to be listening to touches, here the screen
    sensor:onZoom( zoomCallback )
    
    calculateTextSize()
    
    sun = Sun()
    snowflake = Snowflake()
    table.insert(motes, sun)
    table.insert(motes, snowflake)
    for i = 1, MOTE_COUNT do
        table.insert(motes, Mote(math.random(WIDTH), math.random(HEIGHT)))
    end
    testNeighborDetection()
    testWrappedNeighbors()
    parameter.number("TIMESCALE", 0.1, 50, 1)  -- Slider from 0.1x to 5x speed
    parameter.boolean("zoomActive", true)
end

-- Zoom callback function
function zoomCallback(event)
    local touch1 = event.touches[1]
    local touch2 = event.touches[2]
    
    -- Calculate the midpoint of the two touches
    zoomOrigin = vec2((touch1.x + touch2.x) / 2, (touch1.y + touch2.y) / 2)
    
    local zoomChange = 1 + (event.dw + event.dh) / 500 -- Adjust the denominator to control zoom sensitivity
    zoomLevel = zoomLevel * zoomChange
    zoomLevel = math.max(0.1, math.min(zoomLevel, 10)) -- Limit the zoom level
end

function updateWindDirection()
    -- Slowly change the wind direction over time
    WIND_ANGLE = noise(ElapsedTime * 0.1) * math.pi * 2
end