-- Do "main.js true" if you want force updates.

-- Define the GitHub link
local github = "https://raw.githubusercontent.com/Hanaka15/CCJukebox/main/"

-- Function to update the script
local function update()
    -- Download the updated script
    shell.run("wget -qO /dev/null ", github .. "jukebox.lua")
    
    -- get the startup file.
    if not fs.exists("startup.lua") then
        shell.run("wget -qO /dev/null ", github .. "startup.lua")
    else
        print("Startup file already exists...")
    end

    -- Update the version file
    local version_file = io.open("version.txt", "w")
    if version_file then
        version_file:write(github .. "version.txt")
        version_file:close()
    else
        print("Failed to update version file")
    end
    
    -- Run the updated script
    shell.run("jukebox")
end

-- Check if version file exists
local version_file = io.open("version.txt", "r")
if version_file then
    local version_local = version_file:read("*a")
    version_file:close()
    
    -- Get the version info from GitHub
    local version_github = http.get(github .. "version.txt", {protocol = "https"})
    if version_github then
        local version_info = version_github.readAll()
        version_github.close()
        
        -- Check if the arg is "true"
        local force_update = select(1, ...) == "true"
        
        -- Compare local version with GitHub version or force update
        if force_update or version_local ~= version_info then
            update()
        else
            print("Script is up to date")
        end
    else
        print("Failed to retrieve version info from GitHub")
    end
else
    print("Version file not found. Running initial setup...")
    update()  -- Run initial setup if version file is missing
end
