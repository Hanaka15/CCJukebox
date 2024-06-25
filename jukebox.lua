disk.stopAudio() --stop all currently playing disks

-- Lengths dictionary with known disk lengths
lengths = {
    ["C418 - 13"] = 180,
    ["C418 - cat"] = 187,
    ["C418 - blocks"] = 347,
    ["C418 - chirp"] = 187,
    ["C418 - far"] = 176,
    ["C418 - mall"] = 199,
    ["C418 - mellohi"] = 98,
    ["C418 - stal"] = 152,
    ["C418 - strad"] = 190,
    ["C418 - ward"] = 253,
    ["C418 - 11"] = 73,
    ["C418 - wait"] = 240
}

-- Default length for unknown disks
DEFAULT_LENGTH = 200

-- Wrap the peripherals
per = peripheral.getNames()
drive = nil
chest = nil
mon = nil

for k,v in pairs(per) do
    if peripheral.getType(v) == "drive" then
        drive = peripheral.wrap(v)
    elseif peripheral.getType(v) == "monitor" then
        mon = peripheral.wrap(v)
    elseif peripheral.getType(v) == "minecraft:chest" then
        chest = peripheral.wrap(v)
    end
end
per = nil

-- Check if peripherals are found
if not drive or not chest or not mon then
    error("Drive, chest, or monitor not found")
end

disks = {} -- array of disk details {displayName, slot}

-- Function to load disks from the chest
function loadDisks()
    disks = {}
    for slot = 1, chest.size() do
        local item = chest.getItemDetail(slot)
        if item and item.name:find("music_disc") then
            local displayName = item.displayName or "Unknown Disk"
            disks[#disks + 1] = {displayName = displayName, slot = slot}
            
            -- Apply default length if the disk is unknown
            if lengths[displayName] == nil then
                lengths[displayName] = DEFAULT_LENGTH
            end
        end
    end
end

-- Initial load of disks
loadDisks()

track = 1 -- selected track
timer = 0 -- token of the timer that signals the end of a track
playing = false -- indicates if a disk is currently playing
shuffle = true -- when true; selects a random track when track is over

function restart() -- restarts playback
    stop()
    play()
end

function stop() -- stops playback
    playing = false
    os.cancelTimer(timer)
    drive.stopAudio()
end

function play() -- starts playback
    if not disks[track] then
        return -- if no disks are loaded, do nothing
    end
    
    local slot = disks[track].slot
    chest.pushItems(peripheral.getName(drive), slot, 1, 1)
    os.sleep(1) -- Wait for the disk to transfer
    playing = true
    timer = os.startTimer(lengths[disks[track].displayName])
    drive.playAudio()
end

function skip() -- skips to the next track
    track = track + 1
    if track > #disks then
        track = 1
    end
    restart()
end

function back() -- goes back to the previous track
    track = track - 1
    if track < 1 then
        track = #disks
    end
    restart()
end

function skipto(tr) -- skips to a particular track according to 'tr'
    track = tr
    if track > #disks or track < 1 then
        return
    end
    restart()
end

-- Function to handle monitor touch events
function handleTouch(x, y)
    if y > 1 and y <= #disks + 1 then -- a track was pressed
        skipto(y - 1)
    elseif x <= 2 then -- back was pressed
        back()
    elseif x == 4 then -- stop/play was pressed
        if playing then
            stop()
        else
            play()
        end
    elseif x == 6 or x == 7 then -- skip was pressed
        skip()
    elseif x == 9 then -- shuffle was pressed
        shuffle = not shuffle
    elseif x == 18 then -- secret close button was pressed
        stop()
        return
    end
end

-- Main loop
while true do
    -- Refresh display
    mon.setBackgroundColor(colors.black)
    mon.clear()

    -- Drawing buttons
    mon.setCursorPos(1, 1)
    mon.setBackgroundColor(colors.blue)
    mon.write("<- ")
    if not playing then
        mon.write("> ")
    else
        mon.write("O ")
    end
    mon.write("-> ")
    if not shuffle then
        mon.write("=")
    else
        mon.write("x")
    end

    -- Load disks again (in case new disks are added)
    loadDisks()

    -- Draw track names
    for k, v in ipairs(disks) do
        mon.setCursorPos(1, k + 1)
        if k == track then
            mon.setBackgroundColor(colors.green)
        else
            mon.setBackgroundColor(colors.black)
        end
        mon.write(v.displayName)
    end

    -- Wait for event
    local event, dev, cx, cy = os.pullEvent()
    
    -- Test event
    if event == "timer" then -- the timer ended
        if shuffle then
            track = math.random(#disks)
            restart()
        else
            skip()
        end
    elseif event == "monitor_touch" then -- monitor was touched
        handleTouch(cx, cy)
    end
end
