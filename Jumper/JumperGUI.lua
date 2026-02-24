-- JumperGUI.lua
-- GUI listing jump counts with print and reset actions.

--------------------------------------
-- JumperGUI.lua
-- AceGUI-powered UI listing jump counts with per-entry print/reset.

--------------------------------------
-- Locals / Utilities
--------------------------------------
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
local JumperGUIFrame
local ScrollContainer
local ScrollStatus = { scrollvalue = 0, offset = 0 }
local PlayerName, PlayerRealm = UnitName("player"), GetRealmName()
local PlayerClass = select(2, UnitClass("player"))
local SelectedChannel = "SAY"
local ShowClassColors = true

local function FormatCount(n)
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

local CHANNELS = {
	SAY = "Say",
	YELL = "Yell",
	PARTY = "Party",
	RAID = "Raid",
	GUILD = "Guild",
	OFFICER = "Officer",
}


--------------------------------------
-- Confirmation Dialog
--------------------------------------
StaticPopupDialogs["JUMPER_REMOVE_CONFIRM"] = {
	text = "Remove %s-%s from saved data?",
	button1 = YES,
	button2 = CANCEL,
	OnAccept = function(_, data)
		if not data or not data.realm or not data.name then return end
		if not JumperDB or not JumperDB[data.realm] then return end
		local realmTable = JumperDB[data.realm]
		realmTable[data.name] = nil
		if next(realmTable) == nil then
			JumperDB[data.realm] = nil
		end
		if JumperGUIFrame and JumperGUIFrame.RefreshList then
			JumperGUIFrame:RefreshList()
		end
	end,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
}


--------------------------------------
-- Data Helpers
--------------------------------------
local function CollectJumpData()
	local data = {}
	JumperDB = JumperDB or {}
	JumperDB[PlayerRealm] = JumperDB[PlayerRealm] or {}
	local playerEntry = JumperDB[PlayerRealm][PlayerName]
	if type(playerEntry) == "number" then
		JumperDB[PlayerRealm][PlayerName] = { count = playerEntry, class = PlayerClass }
	elseif type(playerEntry) ~= "table" then
		JumperDB[PlayerRealm][PlayerName] = { count = 0, class = PlayerClass }
	else
		playerEntry.count = playerEntry.count or 0
		playerEntry.class = playerEntry.class or PlayerClass
	end

	local total = 0

	for realmName, chars in pairs(JumperDB) do
		if type(chars) == "table" then
			for charName, value in pairs(chars) do
				local count = 0
				local classToken
				if type(value) == "table" then
					count = value.count or 0
					classToken = value.class
				else
					count = value or 0
				end

				total = total + count
				table.insert(data, { realm = realmName, name = charName, count = count, class = classToken })
			end
		end
	end

	table.sort(data, function(a, b)
		if a.count == b.count then
			if a.realm == b.realm then
				return a.name < b.name
			end
			return a.realm < b.realm
		end
		return a.count > b.count
	end)

	return data, total
end


--------------------------------------
-- Row Builder (AceGUI)
--------------------------------------
local function CreateRow(entry, isTotal)
	local row = AceGUI:Create("SimpleGroup")
	row:SetFullWidth(true)
	row:SetLayout("Flow")
	row:SetAutoAdjustHeight(true) -- allow wrapping rows to grow so buttons stay visible

	local nameLabel = AceGUI:Create("Label")
	local labelText = string.format("%s - %s", entry.name, entry.realm)
	if not isTotal and ShowClassColors and entry.class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[entry.class] then
		local c = RAID_CLASS_COLORS[entry.class]
		labelText = string.format("|c%s%s|r - %s", c.colorStr or string.format("ff%02x%02x%02x", c.r * 255, c.g * 255, c.b * 255), entry.name, entry.realm)
	end
	nameLabel:SetText(labelText)
	nameLabel:SetWidth(200)
	row:AddChild(nameLabel)

	local countLabel = AceGUI:Create("Label")
	countLabel:SetText(FormatCount(entry.count))
	countLabel:SetWidth(100)
	countLabel:SetJustifyH("LEFT")
	row:AddChild(countLabel)

	-- Always create button slots so spacing matches; hide/disable on total row
	local printBtn = AceGUI:Create("Button")
	printBtn.frame:SetAlpha(1) -- reset in case this widget was pooled from a hidden state
	printBtn:SetText("Print")
	printBtn:SetWidth(90)
    printBtn:SetCallback("OnClick", function()
        local msg = string.format("Jumper: %s-%s has jumped %s times!", entry.name, entry.realm, FormatCount(entry.count))
        if isTotal then
            msg = string.format("Jumper: Total jumps across all characters is %s!", FormatCount(entry.count))
        end

        C_ChatInfo.SendChatMessage(msg, SelectedChannel)
    end)
	
	row:AddChild(printBtn)

	local removeBtn = AceGUI:Create("Button")
	removeBtn.frame:SetAlpha(1) -- reset pooled state so it doesn't stay hidden
	removeBtn:SetText("Remove")
	removeBtn:SetWidth(90)
	removeBtn:SetDisabled(isTotal)
	if not isTotal then
		removeBtn:SetCallback("OnClick", function()
			StaticPopup_Show("JUMPER_REMOVE_CONFIRM", entry.name, entry.realm, { realm = entry.realm, name = entry.name })
		end)
	else
		removeBtn:SetCallback("OnClick", function() end)
		removeBtn.frame:SetAlpha(0) -- visually hide but preserve layout
	end
	row:AddChild(removeBtn)

	return row
end


--------------------------------------
-- Refresh List (AceGUI)
--------------------------------------
local function RefreshList()
	if not ScrollContainer then return end
	local status = ScrollContainer.status or ScrollContainer.localstatus
	local savedScroll = status and status.scrollvalue or ScrollContainer.scrollbar:GetValue() or 0
	ScrollContainer:ReleaseChildren()

	local data, total = CollectJumpData()

	-- Total row at top, no buttons
	ScrollContainer:AddChild(CreateRow({ name = "Total", realm = "", count = total }, true))

	for _, entry in ipairs(data) do
		ScrollContainer:AddChild(CreateRow(entry))
	end

	if savedScroll then
		ScrollContainer:SetScroll(savedScroll)
	end
end


--------------------------------------
-- GUI Construction (AceGUI)
--------------------------------------
local function EnsureGUI()
	if JumperGUIFrame then return end
	if not AceGUI then
		print("Jumper: AceGUI-3.0 is missing. Please install Ace3.")
		return
	end

	local frame = AceGUI:Create("Frame")
	frame:SetTitle("Jumper - Jump Counts")
	frame:SetWidth(580)
	frame:SetHeight(520)
	frame:SetLayout("List")
	frame:EnableResize(false)
	frame.frame:SetClampedToScreen(true)
	frame:SetCallback("OnClose", function(widget)
		widget:Hide() -- keep it alive, just hide
	end)

	-- Channel selector row
	local channelGroup = AceGUI:Create("SimpleGroup")
	channelGroup:SetFullWidth(true)
	channelGroup:SetLayout("Flow")

	local channelLabel = AceGUI:Create("Label")
	channelLabel:SetText("Print channel:")
	channelLabel:SetFontObject(GameFontHighlight)
	channelLabel:SetWidth(120)
	channelGroup:AddChild(channelLabel)

	local dropdown = AceGUI:Create("Dropdown")
	dropdown:SetList(CHANNELS)
	dropdown:SetValue(SelectedChannel)
	dropdown:SetWidth(220)
	dropdown:SetCallback("OnValueChanged", function(_, _, key)
		SelectedChannel = key or "SAY"
	end)
	channelGroup:AddChild(dropdown)

	local spacer = AceGUI:Create("Label")
	spacer:SetText(" ")
	spacer:SetWidth(40)
	channelGroup:AddChild(spacer)

	local colorToggle = AceGUI:Create("CheckBox")
	colorToggle:SetLabel("Show class colors")
	colorToggle:SetValue(ShowClassColors)
	colorToggle:SetWidth(180)
	colorToggle:SetCallback("OnValueChanged", function(_, _, val)
		ShowClassColors = not not val
		if JumperGUIFrame and JumperGUIFrame.RefreshList then
			JumperGUIFrame:RefreshList()
		end
	end)
	channelGroup:AddChild(colorToggle)

	frame:AddChild(channelGroup)

    -- Add a separator line
    local separator = AceGUI:Create("Label")
    separator:SetFullWidth(true)
    separator:SetText(" ")
    separator:SetHeight(20)
    frame:AddChild(separator)

	-- Header row    
	local header = AceGUI:Create("SimpleGroup")
	header:SetFullWidth(true)
	header:SetLayout("Flow")

	local hName = AceGUI:Create("Label")
	hName:SetText("Character - Realm")
	hName:SetFontObject(GameFontNormal)
	hName:SetWidth(200)
	header:AddChild(hName)

	local hCount = AceGUI:Create("Label")
	hCount:SetText("Jumps")
	hCount:SetFontObject(GameFontNormal)
	hCount:SetWidth(100)
	hCount:SetJustifyH("LEFT")
	header:AddChild(hCount)

	local hActions = AceGUI:Create("Label")
	hActions:SetText("Actions")
	hActions:SetFontObject(GameFontNormal)
	hActions:SetWidth(180)
	header:AddChild(hActions)

	frame:AddChild(header)

	-- Table container with border; align content to header widths
	local listGroup = AceGUI:Create("InlineGroup")
	listGroup:SetFullWidth(true)
	listGroup:SetLayout("Fill")
	listGroup:SetHeight(360)

	local scroll = AceGUI:Create("ScrollFrame")
	scroll:SetFullWidth(true)
	scroll:SetLayout("List")
	scroll:SetStatusTable(ScrollStatus)

	-- Ensure list content mirrors header alignment via row widths
	scroll:SetCallback("OnScroll", function()
		-- no-op: placeholder to keep API happy if needed later
	end)

	ScrollContainer = scroll
	listGroup:AddChild(scroll)
	frame:AddChild(listGroup)

	frame.RefreshList = RefreshList
	JumperGUIFrame = frame
end


--------------------------------------
-- GUI Show + Slash Commands
--------------------------------------
local function ShowGUI()
	JumperDB = JumperDB or {}
	JumperDB[PlayerRealm] = JumperDB[PlayerRealm] or {}
	JumperDB[PlayerRealm][PlayerName] = JumperDB[PlayerRealm][PlayerName] or 0
	EnsureGUI()
	if not JumperGUIFrame then return end
	JumperGUIFrame:Show()
	if JumperGUIFrame.RefreshList then
		JumperGUIFrame:RefreshList()
	end
end

SLASH_JUMPERGUI1 = "/jumpgui"
SLASH_JUMPERGUI2 = "/jumpergui"

SlashCmdList["JUMPERGUI"] = function()
	ShowGUI()
end
