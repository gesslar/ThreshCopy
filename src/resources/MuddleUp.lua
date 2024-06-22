--[[
This is absolutely ripped off from 11BelowStudio MUDKIP_Mud2 package
https://github.com/11BelowStudio/MUDKIP_Mud2
]] --

--[[

THE AUTO-UPDATER FOR MUDKIP_Mud2

heavily ripped off from https://forums.mudlet.org/viewtopic.php?p=20504
(DSL PNP 4.0 Main Script, Zachary Hiland, 2/09/2014)

Shoutouts to demonnic for providing the lua code to actually get the package installed and such

]] --

MuddleUp = MuddleUp or {
    download_path = nil,
    package_name = nil,
    package_url = nil,
    version_check_download = nil,
    version_url = nil,
    file_path = nil,
    version_check_save = nil,
    initialized = false,
    downloading = false,
    download_queue = {} -- Ensure this is here in case the initialization function is missed
}

function MuddleUp:new(options)
    options = options or {}
    local me = table.deepcopy(options)
    setmetatable(me, self)
    self.__index = self

    -- Test to see if any of the required fields are nil and error if so
    for k, v in pairs(me) do
        if v == nil then
            error("MuddleUp:new() - Required field " .. k .. " is nil")
        end
    end

    -- Now that we know we have all the required fields, we can setup the fields
    -- that are derived from the required fields
    me.file_path = getMudletHomeDir() .. "/" .. me.package_name .. "/"
    me.temp_file_path = getMudletHomeDir() .. "/" .. me.package_name .. "_temp" .. "/"
    me.package_url = me.download_path .. me.package_name .. ".mpackage"
    me.version_url = me.download_path .. me.version_check_download

    local packageInfo = getPackageInfo(me.package_name)
    if not packageInfo then
        error("MuddleUp:new() - Package " .. me.package_name .. " not found")
    end
    if not packageInfo.version then
        error("MuddleUp:new() - Package " .. me.package_name .. " does not have a version")
    end

    me.current_version = packageInfo.version

    me.initialized = true
    me.downloading = false
    me.download_queue = {} -- Ensure download_queue is initialized as an empty table
    debugc("MuddleUp:new() - Initialized download_queue")

    registerNamedEventHandler(me.package_name, "DownloadComplete", "sysDownloadDone", function(...)
        me:eventHandler("sysDownloadDone", ...)
    end)
    registerNamedEventHandler(me.package_name, "DownloadError", "sysDownloadError", function(...)
        me:eventHandler("sysDownloadError", ...)
    end)

    return me
end

function MuddleUp:Start()
    debugc("MuddleUp:Start() - Auto-updater started")

    if not self.initialized then
        error("MuddleUp:Start() - MuddleUp object not initialized")
    end

    self:update_scripts()
end

function MuddleUp:fileOpen(filename, mode)
    mode = mode or "read"
    assert(table.contains({ "read", "write", "append", "modify" }, mode), "Invalid mode: must be 'read', 'write', 'append', or 'modify'.")

    if mode ~= "write" then
        local info = lfs.attributes(filename)
        if not info or info.mode ~= "file" then
            return nil, "Invalid filename: " .. (info and "path points to a directory." or "no such file.")
        end
    end

    local file = { name = filename, mode = mode, type = "fileIO_file", contents = {} }
    if mode == "read" or mode == "modify" then
        local tmp, err = io.open(filename, "r")
        if not tmp then
            return nil, err
        end
        for line in tmp:lines() do
            table.insert(file.contents, line)
        end
        tmp:close()
    end

    return file, nil
end

function MuddleUp:fileClose(file)
    assert(file.type == "fileIO_file", "Invalid file: must be file returned by fileIO.open.")
    local tmp
    if file.mode == "write" then
        tmp = io.open(file.name, "w")
    elseif file.mode == "append" then
        tmp = io.open(file.name, "a")
    elseif file.mode == "modify" then
        tmp = io.open(file.name, "w+")
    end
    if tmp then
        for k, v in ipairs(file.contents) do
            tmp:write(v .. "\n")
        end
        tmp:flush()
        tmp:close()
        tmp = nil
    end
    return true
end

function MuddleUp:uninstallAndInstall(path)
    self:UninstallPackage()
    tempTimer(1, function()
        installPackage(path)
        os.remove(path)
        lfs.rmdir(self.temp_file_path)
    end)
end

function MuddleUp:update_the_package()
    local download_here = self.package_url
    self:UninstallPackage()
    tempTimer(2, function() installPackage(download_here) end)
end

function MuddleUp:load_package_xml(path)
    if path ~= self.temp_file_path .. self.package_name .. ".xml" then return end
    self:uninstallAndInstall(path)
end

function MuddleUp:load_package_mpackage(path)
    self:uninstallAndInstall(path)
end

function MuddleUp:start_next_download()
    debugc("MuddleUp:start_next_download() - Checking download_queue")
    local info = self.download_queue[1]
    if not info then
        self.downloading = false
        debugc("MuddleUp:start_next_download() - No more items in download_queue")
        return
    end

    cecho("\n<b><ansiLightYellow>INFO</b><reset> - Downloading remote version file " .. info[2] .. " to " .. info[1] .. "\n")

    -- Remove the current item from the queue
    table.remove(self.download_queue, 1)
    debugc("MuddleUp:start_next_download() - Removed item from download_queue, new size: " .. #self.download_queue)

    -- Start the download
    downloadFile(info[1], info[2])
    self.downloading = true
end

function MuddleUp:queue_download(path, address)
    -- Add the download request to the queue
    debugc("MuddleUp:queue_download() - Adding to download_queue")
    table.insert(self.download_queue, { path, address })
    debugc("MuddleUp:queue_download() - Current queue size: " .. #self.download_queue)

    -- Start the download if not already in progress
    if not self.downloading then
        self:start_next_download()
    end
end

function MuddleUp:finish_download(path)
    self:start_next_download()
    debugc("MuddleUp:finish_download() - Finished downloading " .. path)
    debugc("MuddleUp:finish_download() - Checking if downloaded file is version info file")

    -- Check if the downloaded file is the version info file
    if string.find(path, self.file_path .. self.version_check_save) then
        self:check_versions()
    elseif string.find(path, ".mpackage") then
        self:load_package_mpackage(path)
    elseif string.find(path, ".xml") then
        self:load_package_xml(path)
    end
end

function MuddleUp:fail_download(...)
    cecho("\n<b><ansiLightRed>ERROR</b><reset> - failed downloading " .. arg[2] .. arg[1] .. "\n")
    self:start_next_download()
end

function MuddleUp:update_package()
    lfs.mkdir(self.temp_file_path)
    self:queue_download(
        self.temp_file_path .. self.package_name .. ".mpackage",
        self.download_path .. self.package_name .. ".mpackage"
    )
end

function MuddleUp:update_scripts()
    self:get_version_check()
end

function MuddleUp:eventHandler(event, ...)
    if event == "sysDownloadDone" then
        self:finish_download(...)
    elseif event == "sysDownloadError" then
        self:fail_download(...)
    end
end

function MuddleUp:semantic_version_splitter(_version_string)
    local t = {}
    for k in string.gmatch(_version_string, "([^.]+)") do
        table.insert(t, tonumber(k))
    end
    return t
end

function MuddleUp:compare_versions(_installed, _remote)
    local current = self:semantic_version_splitter(_installed)
    local remote = self:semantic_version_splitter(_remote)
    if current[1] < remote[1] then
        return true
    elseif current[1] == remote[1] then
        if current[2] < remote[2] then
            return true
        elseif current[2] == remote[2] then
            return current[3] < remote[3]
        end
    end
    return false
end

function MuddleUp:get_version_check()
    lfs.mkdir(self.file_path)
    debugc("MuddleUp:get_version_check() - Getting version check file")
    debugc("MuddleUp:get_version_check() - " .. self.version_url)
    debugc("MuddleUp:get_version_check() - " .. self.file_path .. self.version_check_save)

    -- Ensure the version file is saved in the correct directory
    self:queue_download(
        self.file_path .. self.version_check_save, -- Local path to save the file
        self.version_url                           -- Remote URL to download from
    )
end

function MuddleUp:check_versions()
    local dl_path = self.file_path .. self.version_check_save
    local dl_file, dl_errors = self:fileOpen(dl_path, "read")
    if not dl_file then
        cecho("\n<b><ansiLightRed>ERROR</b><reset> - Could not read remote version info file, aborting auto-update routine. (" .. dl_errors .. ")\n")
        return
    end

    local curr_version = self.current_version
    local dl_version = dl_file.contents[1]
    cecho("\n<b><ansiLightYellow>INFO</b><reset> - installed " .. curr_version .. "; remote " .. dl_version .. ";\n")

    self:fileClose(dl_file)
    os.remove(dl_path)

    if self:compare_versions(curr_version, dl_version) then
        cecho("\n<b><ansiLightYellow>INFO</b><reset> - Attempting to update " .. self.package_name .. " to v" .. dl_version .. "\n")
        self:update_package()
    else
        cecho("\n<b><ansiLightYellow>INFO</b><reset> - " .. self.package_name .. " is up-to-date, have a nice day :)\n")
    end
end
