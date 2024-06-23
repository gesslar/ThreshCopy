__PKGNAME__ = __PKGNAME__ or {
  InstallHandler = nil,
  UninstallHandler = nil
}

function __PKGNAME__:getSelectedText(window, startCol, startRow, endCol, endRow)
  -- Check whether there's an actual selection
  if startCol == endCol and startRow == endRow then return "" end
  local parsed = ""
  -- Loop through each symbol within the range
  for lineNum = startRow, endRow do
    local cStart = lineNum == startRow and startCol or 0
    moveCursor(window, cStart, lineNum)
    local cEnd = lineNum == endRow and endCol or #getCurrentLine() - 1
    selectSection(window, cStart, cEnd - cStart + 1)
    parsed = parsed .. (getSelection(window) or "")
    if lineNum ~= endRow then parsed = parsed .. "\n" end
  end
  return parsed
end

function __PKGNAME__:trim(s)
  return s:match("^%s*(.-)%s*$")
end

__PKGNAME__.handler = function(event, menu, ...)
  local text = __PKGNAME__:getSelectedText(...)
  -- Split the text into lines, trim each line, and handle blank lines separately
  local lines = {}
  for line in text:gmatch("([^\n]*)\n?") do
    if line == "" then
      table.insert(lines, "")
    else
      table.insert(lines, __PKGNAME__:trim(line))
    end
  end

  -- Join lines, preserving empty lines as blank lines
  local withoutNewLines = ""
  local previousLineEmpty = false
  for _, line in ipairs(lines) do
    if line == "" then
      withoutNewLines = withoutNewLines .. "\n\n"
      previousLineEmpty = true
    else
      if #withoutNewLines > 0 and not previousLineEmpty then
        withoutNewLines = withoutNewLines .. " "
      end
      withoutNewLines = withoutNewLines .. line
      previousLineEmpty = false
    end
  end

  -- Remove any trailing newlines
  withoutNewLines = withoutNewLines:gsub("%s*\n*$", "")

  setClipboardText(withoutNewLines)
end

-- ------------------------------------------------------------------- --
-- HANDLERS
-- ------------------------------------------------------------------- --

function __PKGNAME__:enableHandlers()
  addMouseEvent("Copy Collapsed", "copyWithoutNewLines")
  registerNamedEventHandler("__PKGNAME__", "copy without new lines", "copyWithoutNewLines", self.handler)
end

function __PKGNAME__:disableHandlers()
    removeMouseEvent("Copy Collapsed")
    stopNamedEventHandler("__PKGNAME__", "copy without new lines")
end

function __PKGNAME__:Install(_, package)
  if package == "__PKGNAME__" then
    if self.InstallHandler ~= nil then killAnonymousEventHandler(__PKGNAME__.InstallHandler) end
    self:enableHandlers()
    self.InstallHandler = nil
    print(f"Thank you for installing __PKGNAME__!")
    print("Right-click selected text in the output pane for copy functions.")
  end
end
__PKGNAME__.InstallHandler = __PKGNAME__.InstallHandler or registerAnonymousEventHandler("sysInstallPackage", "__PKGNAME__:Install")

function __PKGNAME__:Uninstall(_, package)
  if package == "__PKGNAME__" then
    if self.UninstallHandler ~= nil then killAnonymousEventHandler(self.UninstallHandler) end
    self:disableHandlers()
    self.UninstallHandler = nil
    cecho(f"<red>You have uninstalled __PKGNAME__.\n")
  end
end
__PKGNAME__.UninstallHandler = __PKGNAME__.UninstallHandler or registerAnonymousEventHandler("sysUninstallPackage", "__PKGNAME__:Uninstall")

-- Auto Updater
__PKGNAME__ = __PKGNAME__ or {}
__PKGNAME__.MupdateUser = "__PKGNAME__.AutoMupdate"
__PKGNAME__.MupdateFunction = "__PKGNAME__:AutoMupdate"

function __PKGNAME__:AutoMupdate(handle)
  debugc("AutoMupdate - Package Name: __PKGNAME__, Handle: " .. handle)
  if handle ~= self.MupdateUser then return end

    local timerName = "__PKGNAME__.AutoMupdate"
    local timers = getNamedTimers(self.MupdateUser)

    for _, timer in ipairs(timers) do
        if timer.name == timerName then return end
    end

    registerNamedTimer(self.MupdateUser, self.MupdateUser, 2, function()
        deleteAllNamedTimers(self.MupdateUser)

        local Mupdate = require("__PKGNAME__\\Mupdate")
        local updater = Mupdate:new({
            download_path = "https://github.com/gesslar/__PKGNAME__/releases/latest/download/",
            package_name = "__PKGNAME__",
            remote_version_file = "__PKGNAME___version.txt",
            param_key = "response-content-disposition",
            param_regex = "attachment; filename=(.*)",
            debug_mode = true,
        })
        updater:Start(function()
            updater:Cleanup()
            updater = nil
        end)
    end)
end

-- Start it up
__PKGNAME__.MupdateLoadHandler = __PKGNAME__.MupdateLoadHandler or
    registerNamedEventHandler (
        __PKGNAME__.MupdateUser, -- username
        "__PKGNAME__.Load", -- handler name
        "sysLoadEvent", -- event name
        function(event)
            __PKGNAME__:AutoMupdate(__PKGNAME__.MupdateUser)
        end
    )
__PKGNAME__.MupdateInstallHandler = __PKGNAME__.MupdateInstallHandler or
    registerNamedEventHandler(
        __PKGNAME__.MupdateUser, -- username
        "__PKGNAME__.Install", -- handler name
        "sysInstallPackage", -- event name
        function(event, package, path)
            if package ~= "__PKGNAME__" then return end
            __PKGNAME__:AutoMupdate(__PKGNAME__.MupdateUser)
        end
    )
