

---- Define emoji categories with sounds as tables-- Function to pick a random emoji and sound from the selected category


-- Function to pick a random category
function pickRandomCategory()
    local keys = {}
    for key, _ in pairs(categories) do
        table.insert(keys, key)
    end
    local category = keys[math.random(#keys)]
    return category
end

-- Function to pick a random emoji and sound from the selected category
function pickEmojiAndSound(category)
    if category == "SpecialCases" then
        local customKeys = {}
        for key, _ in pairs(categories[category].customSounds) do
            table.insert(customKeys, key)
        end
        local emoji = customKeys[math.random(#customKeys)]
        local soundOptions = categories[category].customSounds[emoji]
        local sound = soundOptions[math.random(#soundOptions)]
        return emoji, sound
    else
        print(category)
        local emojis = categories[category].emojis
        local emoji = emojis[math.random(#emojis)]
        local soundOptions = categories[category].sounds
        local sound = soundOptions[math.random(#soundOptions)]
        return emoji, sound
    end
end








