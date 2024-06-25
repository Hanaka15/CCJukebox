-- Initialize variables and peripherals
local disks = {}  -- Global array to store disk details {displayName, audioTitle, slot, length}
local drive = peripheral.wrap("left")  -- Adjust disk drive side as per your setup
local chest = peripheral.find("minecraft:chest")  -- Adjust chest side as per your setup
local mon = peripheral.wrap("top")  -- Adjust monitor side as per your setup

-- Check if peripherals are found
if not drive or not chest or not mon then
    error("Drive, chest, or monitor not found")
end

-- Lengths dictionary with known disk lengths
local lengths = {
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
local DEFAULT_LENGTH = 200

-- Function to load disks from chest into disk drive
local function loadDisks()
    disks = {}  -- Clear existing disks array
    
    for slot = 1, chest.size() do
        local item = chest.getItemDetail(slot)
        if item then
            -- Push disk into disk drive
            chest.pushItems("left", slot)
            
            -- Wait briefly to ensure disk is loaded (adjust timing as needed)
            os.sleep(1)  -- Adjust sleep time if necessary
            
            -- Get audio title of the disk in the disk drive
            local audioTitle = drive.getAudioTitle()
            
            -- Eject disk from the disk drive
            chest.pullItems("left", 1)
            
            -- Determine display name (use DEFAULT_LENGTH if not found in lengths)
            local displayName = item.displayName or "Unknown Disk"
            local length = lengths[displayName] or DEFAULT_LENGTH
            
            -- Store disk details in disks table
            disks[#disks + 1] = {displayName = displayName, audioTitle = audioTitle, slot = slot, length = length}
        end
    end
    
    -- Print loaded disks to console
    print("Loaded disks:")
    for k, v in ipairs(disks) do
        print(k .. ": " .. v.audioTitle .. " in slot " .. v.slot)
    end
end

-- Initial load of disks
loadDisks()

-- Get size of the monitor terminal
local screenWidth, screenHeight = mon.getSize()

-- Variable to track currently selected track (for UI display)
local selectedTrack = 1

-- Function to handle mouse click events
local function handleMouseClick(x, y)
    -- Check if click is within track listing area
    if x >= 1 and x <= screenWidth and y >= 2 and y <= screenHeight then
        local trackIndex = y - 1  -- Convert y coordinate to track index
        if disks[trackIndex] then
            selectedTrack = trackIndex
            -- Print selected track to console
            print("Selected track: " .. disks[selectedTrack].audioTitle)
            disk.stopAudio("left")
            if disk.isPresent("left") then 
                chest.pullItems("left", 1)
            end
            chest.pushItems("left", disks[selectedTrack].slot)
            disk.playAudio("left")
            
        end
    end
end

-- Main loop
while true do
    -- Refresh display
    mon.setBackgroundColor(colors.black)
    mon.clear()

    -- Draw buttons and disk names
    mon.setCursorPos(1, 1)
    mon.setBackgroundColor(colors.blue)

    -- Draw track names
    for k, v in ipairs(disks) do
        mon.setCursorPos(1, k + 1)
        if k == selectedTrack then
            mon.setBackgroundColor(colors.green)
        else
            mon.setBackgroundColor(colors.black)
        end
        mon.write(v.audioTitle)
    end

    -- Wait for mouse click event
    local event, side, x, y = os.pullEvent("monitor_touch")
    
    -- Handle mouse click event
    if event == "monitor_touch" then
        handleMouseClick(x, y)
    end
end
