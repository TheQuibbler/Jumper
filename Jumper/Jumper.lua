-- Jumper.lua
-- Simple per-character jump counter
-- Stores counts in the SavedVariable `JumperDB` keyed by realm and character name.

--------------------------------------
-- Locals / Utilities
--------------------------------------
local EventFrame = CreateFrame("Frame")
local Name, Realm = UnitName("player"), GetRealmName()
local Class = select(2, UnitClass("player")) -- class token for coloring


--------------------------------------
-- SavedVariables Initialization
--------------------------------------
EventFrame:RegisterEvent("PLAYER_LOGIN")
EventFrame:SetScript("OnEvent", function()
	-- Ensure saved table exists and this character has an entry
	JumperDB = JumperDB or {}
	JumperDB[Realm] = JumperDB[Realm] or {}

	local entry = JumperDB[Realm][Name]
	if type(entry) == "number" then
		entry = { count = entry, class = Class }
	elseif type(entry) ~= "table" then
		entry = { count = 0, class = Class }
	else
		entry.count = entry.count or 0
		entry.class = entry.class or Class
	end
	JumperDB[Realm][Name] = entry

	-- Hook the jump API and increment when appropriate.
	-- Ignore jumps while on a taxi, flying, swimming, or when control is lost (e.g. stuns).
	hooksecurefunc("JumpOrAscendStart", function()
		if UnitOnTaxi("player") or IsFlying() or IsSwimming() or not HasFullControl() then return end
		local data = JumperDB[Realm][Name]
		if type(data) == "table" then
			data.count = (data.count or 0) + 1
		else
			-- fallback if someone manually edited the saved variable
			JumperDB[Realm][Name] = (data or 0) + 1
		end
	end)
end)


--------------------------------------
-- Slash Commands
--------------------------------------
-- Register slash names first (convention)
SLASH_JUMPER1 = "/jump"
SLASH_JUMPER2 = "/jumper"

-- Main slash handler. Accepts:
--  - no args: prints the current count
--  - chat channel names (say, yell, guild, party, raid, battleground, officer)
--  - "tell <name>" or "whisper <name>" to whisper the count to another player
SlashCmdList["JUMPER"] = function(Input)
	local data = JumperDB[Realm][Name]
	local count = type(data) == "table" and (data.count or 0) or (data or 0)
	local Message = string.format("Jumper: %s has jumped %s times!", Name, count)
	Input = string.lower(Input or "")

	if Input == "guild" or Input == "officer" or Input == "party" or Input == "raid" or Input == "say" or Input == "yell" then
		-- Send to chat channel
		C_ChatInfo.SendChatMessage(Message, string.upper(Input))

	elseif Input:find("tell") or Input:find("whisper") then
		-- whisper/tell <target>
		local Method, Target = string.match(Input, "(%a+)%s+(%S+)")
		if Method and Target and (Method == "tell" or Method == "whisper") then
			C_ChatInfo.SendChatMessage(Message, "WHISPER", nil, Target)
		end
	else 
		-- Show locally
		print(Message)		
	end
end
