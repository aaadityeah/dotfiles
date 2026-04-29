-- Remap caps_lock → F18 at the OS level (so we get real keyDown/keyUp events)
hs.task.new("/usr/bin/hidutil", nil, {
    "property", "--set",
    '{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x700000039,"HIDKeyboardModifierMappingDst":0x70000006D}]}'
}):start()

-- Caps Lock (now F18) → Escape (tap) or Control (hold)
local f18Down = false
local sendEscape = false

keyWatcher = hs.eventtap.new({
    hs.eventtap.event.types.keyDown,
    hs.eventtap.event.types.keyUp,
}, function(e)
    local keyCode = e:getKeyCode()
    local isDown = e:getType() == hs.eventtap.event.types.keyDown

    -- F18 = key code 79
    if keyCode == 79 then
        if isDown then
            f18Down = true
            sendEscape = true
        else
            f18Down = false
            if sendEscape then
                sendEscape = false
                hs.eventtap.keyStroke({}, 'escape')
            end
        end
        return true -- consume F18
    end

    -- Any other key pressed while caps held → add ctrl modifier
    if f18Down and isDown then
        sendEscape = false
        local flags = e:getFlags()
        flags['ctrl'] = true
        e:setFlags(flags)
    end

    return false
end)

keyWatcher:start()
