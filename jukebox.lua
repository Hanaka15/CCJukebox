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
per=peripheral.getNames()
drive=nil
chest=nil
mon=nil

for k,v in pairs(per) do
 if peripheral.getType(v)=="drive" then
  drive=peripheral.wrap(v)
 elseif peripheral.getType(v)=="monitor" then
  mon=peripheral.wrap(v)
 elseif peripheral.getType(v)=="minecraft:chest" then
  chest=peripheral.wrap(v)
 end
end
per=nil

-- Check if peripherals are found
if not drive or not chest or not mon then
 error("Drive, chest, or monitor not found")
end

disks={} -- the name of the disk in the chest
diskSlots={} -- the corresponding slots of the disks in the chest

-- Function to load disks from the chest
function loadDisks()
 disks = {}
 diskSlots = {}
 for slot=1, chest.size() do
  local item = chest.getItemDetail(slot)
  if item and item.name:find("music_disc") then
   local title = item.displayName
   disks[#disks+1] = title
   diskSlots[#disks] = slot
   
   -- Apply default length if the disk is unknown
   if lengths[title] == nil then
    lengths[title] = DEFAULT_LENGTH
   end
  end
 end
end

-- Initial load of disks
loadDisks()

track=1 --selected track
timer=0 --token of the timer that signals the end of a track
playing=false --i'm not going to insult you by explaining this one
shuffle=true --when true; selects a random track when track is over

function restart() --restarts playback (more useful than it sounds)
 stop()
 play()
end

function stop() --stops playback
 playing=false
 os.cancelTimer(timer)
 drive.stopAudio()
end

function play() --starts playback
 -- Swap the disk into the drive
 local slot = diskSlots[track]
 chest.pushItems(peripheral.getName(drive), slot, 1, 1)
 os.sleep(1) -- Wait for the disk to transfer
 playing=true
 timer=os.startTimer(lengths[disks[track]])
 drive.playAudio()
end

function skip() --skips to the next track
 track=track+1
 if track>#disks then
  track=1
 end
 restart() --see?
end

function back() --goes back to the previous track
 track=track-1
 if track<1 then
  track=#disks
 end
 restart()
end

function skipto(tr) --skips to a particular track according to 'tr'
 track=tr
 if track>#disks or track<1 then
  return
 end
 restart()
end

repeat --main loop

 --refresh display
 mon.setBackgroundColor(colors.black) --clearing
 mon.clear()

 mon.setCursorPos(1,1) --drawing back, play, skip, and shuffle
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

 mon.setBackgroundColor(colors.black) --clearing the bits in between the buttons
 mon.setCursorPos(3,1) --inefficient; I know.
 mon.write(" ")
 mon.setCursorPos(5,1)
 mon.write(" ")
 mon.setCursorPos(8,1)
 mon.write(" ")

 for k,v in pairs(disks) do --drawing tracks
  if k==track then
   mon.setBackgroundColor(colors.green)
  else
   mon.setBackgroundColor(colors.black)
  end
  mon.setCursorPos(1,k+2)
  mon.write(v)
 end

 --wait for event
 repeat
  eve,dev,cx,cy=os.pullEvent()
 until eve=="timer" or eve=="monitor_touch"

 --test event
 if eve=="timer" then --the timer ended
  if shuffle then
   track=math.random(#disks)
   restart()
  else
   skip()
  end

 else --the monitor was pressed
  if cy>1 then --a track was pressed
   skipto(cy-2)
  elseif cx<=2 then --back was pressed
   back()
  elseif cx==4 then --stop/play was pressed
   if playing then
    stop()
   else
    play()
   end
  elseif cx==6 or cx==7 then --skip was pressed
   skip()
  elseif cx==9 then --shuffle was pressed
   shuffle=not shuffle
  elseif cx==18 then --secret close button was pressed
   stop()
   return
  end
 end

until false
