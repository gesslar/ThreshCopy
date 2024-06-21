local function getSelectedText(window, startCol, startRow, endCol, endRow)
  if startCol == endCol and startRow == endRow then return "" end
  local parsed = ""
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

local function trimRight(s)
  return s:gsub("%s+$", "")
end

local function wrapText(text, width)
  local wrapped = {}
  local line = ""
  local indent = text:match("^(%s*)")  -- Capture the leading whitespace
  local isFirstLine = true
  for word in text:gmatch("%S+") do
    if (isFirstLine and #indent + #line + #word + 1 > width) or
       (not isFirstLine and #line + #word + 1 > width) then
      table.insert(wrapped, (isFirstLine and indent or "") .. line)
      line = word
      isFirstLine = false
    else
      if line ~= "" then line = line .. " " end
      line = line .. word
    end
  end
  if line ~= "" then table.insert(wrapped, (isFirstLine and indent or "") .. line) end
  return table.concat(wrapped, "\n")
end

local handler = function(event, menu, ...)
  local text = getSelectedText(...)

  -- Split the text into lines and process each line
  local lines = {}
  for line in text:gmatch("([^\n]*)\n?") do
    local trimmedLine = trimRight(line)
    
    table.insert(lines, trimmedLine)
  end

  -- Join lines, preserving empty lines as blank lines
  local paragraphs = {}
  local paragraph = ""
  local isPrevLineEmpty = false
  for _, line in ipairs(lines) do
    if line == "" then
      if #paragraph > 0 then
        table.insert(paragraphs, wrapText(paragraph, 79))
        paragraph = ""
      end
      if not isPrevLineEmpty then
        table.insert(paragraphs, "")  -- Insert an empty string to represent a blank line
      end
      isPrevLineEmpty = true
    else
      if #paragraph > 0 then
        paragraph = paragraph .. " " .. line
      else
        paragraph = line
      end
      isPrevLineEmpty = false
    end
  end
  if #paragraph > 0 then
    table.insert(paragraphs, wrapText(paragraph, 79))
  end

  -- Remove consecutive empty strings
  local filteredParagraphs = {}
  for i, paragraph in ipairs(paragraphs) do
    if paragraph ~= "" or (i > 1 and paragraphs[i-1] ~= "") then
      table.insert(filteredParagraphs, paragraph)
    end
  end

  -- Join wrapped paragraphs with double newlines to preserve paragraph breaks
  local wrappedText = table.concat(filteredParagraphs, "\n")
  
  setClipboardText(wrappedText)
end

-- addMouseEvent("Copy Wrapped", "copyAndWrapText")
-- registerNamedEventHandler("threshcopy", "copy and wrap text", "copyAndWrapText", handler)
