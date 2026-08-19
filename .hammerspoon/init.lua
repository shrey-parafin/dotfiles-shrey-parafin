-- Ghostty split-pane navigation. Hammerspoon must have Accessibility and
-- Automation permission to receive key events and control Ghostty.
local chooser = hs.chooser.new(function(choice)
  if choice then
    local script = string.format([[
      tell application "Ghostty"
        set currentTab to selected tab of front window
        focus (terminal %d of currentTab)
      end tell
    ]], choice.index)
    hs.osascript.applescript(script)
  end
end)

local function isGhosttyFocused()
  local app = hs.application.frontmostApplication()
  return app and app:name() == "Ghostty"
end

local function panesInFocusedTab()
  local ok, names = hs.osascript.applescript([[
    tell application "Ghostty"
      return name of every terminal of selected tab of front window
    end tell
  ]])

  if not ok then
    hs.alert.show("Hammerspoon needs permission to control Ghostty")
    return nil
  end

  if type(names) == "string" then
    names = {names}
  end

  local panes = {}
  for index, name in ipairs(names) do
    table.insert(panes, {
      text = string.format("%d — %s", index, name),
      subText = string.format("Focus split pane %d", index),
      index = index,
    })
  end
  return panes
end

local function focusPane(index)
  local script = string.format([[
    tell application "Ghostty"
      set currentTab to selected tab of front window
      focus (terminal %d of currentTab)
    end tell
  ]], index)
  hs.osascript.applescript(script)
end

local function showPanePicker()
  local panes = panesInFocusedTab()
  if not panes then
    return
  end
  chooser:choices(panes)
  chooser:placeholderText("Choose a Ghostty split pane")
  chooser:show()
end

local previousCommandRelease = 0
local commandWasDown = false
local commandWasUsed = false
local doublePressInterval = 0.35
local digitKeyCodes = {
  [18] = 1,
  [19] = 2,
  [20] = 3,
  [21] = 4,
  [23] = 5,
  [22] = 6,
  [26] = 7,
  [28] = 8,
  [25] = 9,
}

hs.eventtap.new({hs.eventtap.event.types.flagsChanged, hs.eventtap.event.types.keyDown}, function(event)
  if not isGhosttyFocused() then
    return false
  end

  local eventType = event:getType()
  local flags = event:getFlags()

  if eventType == hs.eventtap.event.types.flagsChanged then
    if flags.cmd then
      commandWasDown = true
      commandWasUsed = false
    elseif commandWasDown then
      commandWasDown = false
      if not commandWasUsed then
        local now = hs.timer.secondsSinceEpoch()
        if now - previousCommandRelease <= doublePressInterval then
          previousCommandRelease = 0
          showPanePicker()
        else
          previousCommandRelease = now
        end
      end
    end
    return false
  end

  if flags.cmd then
    commandWasUsed = true
  end

  if flags.cmd and not flags.alt and not flags.ctrl and not flags.shift then
    local paneIndex = digitKeyCodes[event:getKeyCode()]
    if paneIndex then
      focusPane(paneIndex)
      return true
    end
  end

  return false
end):start()
