-- Utilities.lua
-- Shared helpers for Jumper

local _, Addon = ...
Addon.Utilities = Addon.Utilities or {}

function Addon.Utilities.FormatCount(n)
    if BreakUpLargeNumbers then
        return BreakUpLargeNumbers(n or 0)
    end
    local s = tostring(n or 0)
    local k
    repeat
        s, k = s:gsub("^(%-?%d+)(%d%d%d)", "%1,%2")
    until k == 0
    return s
end

