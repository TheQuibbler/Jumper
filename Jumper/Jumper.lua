-- Jumper.lua
-- Simple per-character jump counter
-- Stores counts in the SavedVariable `JumperDB` keyed by realm and character name.

--------------------------------------
-- Locals / Utilities
--------------------------------------
local EventFrame = CreateFrame("Frame")
local Name, Realm = UnitName("player"), GetRealmName()


--------------------------------------
-- SavedVariables Initialization
--------------------------------------
EventFrame:RegisterEvent("PLAYER_LOGIN")
EventFrame:SetScript("OnEvent", function()
	-- Ensure saved table exists and this character has an entry
	JumperDB = JumperDB or {}
	JumperDB[Realm] = JumperDB[Realm] or {}
	JumperDB[Realm][Name] = JumperDB[Realm][Name] or 0

	-- Hook the jump API and increment when appropriate.
	-- Ignore jumps while on a taxi, flying, swimming, or when control is lost (e.g. stuns).
	hooksecurefunc("JumpOrAscendStart", function()
		if UnitOnTaxi("player") or IsFlying() or IsSwimming() or not HasFullControl() then return end
		JumperDB[Realm][Name] = JumperDB[Realm][Name] + 1
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
	local Message = string.format("Jumper: %s has jumped %s times!", Name, JumperDB[Realm][Name])
	Input = string.lower(Input)

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
