local function getSelectedText(window, startCol, startRow, endCol, endRow)
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

local function trim(s)
  return s:match("^%s*(.-)%s*$")
end

local handler = function(event, menu, ...)
  local text = getSelectedText(...)
  -- Split the text into lines, trim each line, and handle blank lines separately
  local lines = {}
  for line in text:gmatch("([^\n]*)\n?") do
    if line == "" then
      table.insert(lines, "")
    else
      table.insert(lines, trim(line))
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

function ThreshCopy.enableHandlers()
  addMouseEvent("Copy Collapsed", "copyWithoutNewLines")
  registerNamedEventHandler("threshcopy", "copy without new lines", "copyWithoutNewLines", handler)
end

function ThreshCopy.disableHandlers()
    removeMouseEvent("Copy Collapsed")
    stopNamedEventHandler("threshcopy", "copy without new lines")
end

function ThreshCopy.Install(_, package)
  if package == ThreshCopy.AppName then
    if ThreshCopy.installHandler ~= nil then killAnonymousEventHandler(ThreshCopy.installHandler) end
    ThreshCopy.enableHandlers()
    ThreshCopy.installHandler = nil
    print("Thank you for installing ThreshCopy! 😄😁😆😍\n")
    print("Right-click selected text in the output pane for copy functions.\n")
  end
end
ThreshCopy.installHandler = ThreshCopy.installHandler or registerAnonymousEventHandler("sysInstallPackage", ThreshCopy.Install)

function ThreshCopy.Uninstall(_, package)
  if package == ThreshCopy.AppName then
    if ThreshCopy.uninstallHandler ~= nil then killAnonymousEventHandler(ThreshCopy.uninstallHandler) end
    ThreshCopy.disableHandlers()
    ThreshCopy.uninstallHandler = nil
    cecho("\n<red>You have uninstalled ThreshCopy. 😔️😥😢\n")
  end
end
ThreshCopy.uninstallHandler = ThreshCopy.uninstallHandler or registerAnonymousEventHandler("sysUninstallPackage", ThreshCopy.Uninstall)

-- Start it up
ThreshCopy.enableHandlers()
