local PLUGIN = PLUGIN

PLUGIN.name = "Fake Names"
PLUGIN.author = "Ron"
PLUGIN.description = "Adds the ability to use the f3 menu to provide a false name to people."

ix.lang.AddTable("english", {
	rgnFakeName = "Allow those in speaking range to recognize you by a fake name.",
	fakeNameSub = "Enter a fake name to display to other players in range.",
})

-- Important changes: 'rgn' now serves if a character is recognized by any name.
-- CharsWeKnow now serves as a list of people we know the true identity of. Like the old 'rgn'.
-- character:Recognize takes a character input rather than an ID input.

-- Known issue currently: Scoreboard icon doesn't behave properly.

ix.char.RegisterVar("RecognizedAs", {
    field = "recognized_as",
    fieldType = ix.type.text,
    default = {},
    bNoDisplay = true
})

ix.char.RegisterVar("CharsWeKnow", { -- This is kind of like the old 'rgn', but it lists the true identities of people we know.
    field = "chars_we_know",
    fieldType = ix.type.text,
    default = {},
    bNoDisplay = true
})

do
	local character = ix.meta.character

	if (SERVER) then
		function character:Recognize(character, name)
			local id = character:GetID()
			if (!isnumber(id) and id.GetID) then
				id = id:GetID()
			end

			local recognized = self:GetData("rgn", "")

			local peopleWhoWeKnow = character:GetCharsWeKnow()

			if (recognized != "" and recognized:find(","..id..",") and peopleWhoWeKnow[id]) then
				return false
			end

			self:SetData("rgn", recognized..","..id..",") -- rgn is set if we recognize them by any name.
			
			local nameList = self:GetRecognizedAs()
			if(string.len(name) > 0) then
				nameList[id] = name
			else
				nameList[id] = tostring(character:GetName())
				peopleWhoWeKnow[id] = true
				
			end
			character:SetCharsWeKnow(peopleWhoWeKnow)
			self:SetRecognizedAs(nameList)
			return true
		end
	end

	function character:DoesRecognize(id)
		if (!isnumber(id) and id.GetID) then
			id = id:GetID()
		end

		return hook.Run("IsCharacterRecognized", self, id)
	end

	function PLUGIN:IsCharacterRecognized(char, id)
		if (char.id == id) then
			return true
		end

		local other = ix.char.loaded[id]

		if (other) then
			local faction = ix.faction.indices[other:GetFaction()]

			if (faction and faction.isGloballyRecognized) then
				return true
			end
		end

		local recognized = char:GetData("rgn", "")

		if (recognized != "" and recognized:find(","..id..",")) then
			return true
		end
	end
end

if (CLIENT) then

	function PLUGIN:GetCharacterName(client, chatType)
		if (client != LocalPlayer()) then
			local character = client:GetCharacter()
			local ourCharacter = LocalPlayer():GetCharacter()

			if (ourCharacter and character and !ourCharacter:DoesRecognize(character) and !hook.Run("IsPlayerRecognized", client)) then
				if (chatType and hook.Run("IsRecognizedChatType", chatType)) then
					local description = character:GetDescription()

					if (#description > 40) then
						description = description:utf8sub(1, 37).."..."
					end

					return "["..description.."]"
				elseif (!chatType) then
					return L"unknown"
				end
			else
				local myReg = ourCharacter:GetRecognizedAs()
				if(myReg[character:GetID()]) then
					return myReg[character:GetID()]
				end
			end
			
		end
	end

	local function Recognize(level, name)
		net.Start("ixRecognize")
			net.WriteUInt(level, 2)
			if(name) then
				net.WriteString(name)
			end
		net.SendToServer()
	end

	net.Receive("ixRecognizeMenu", function(length, client)
		local menu = DermaMenu()
			menu:AddOption(L"rgnLookingAt", function()
				Recognize(0)
			end)
			menu:AddOption(L"rgnWhisper", function()
				Recognize(1)
			end)
			menu:AddOption(L"rgnTalk", function()
				Recognize(2)
			end)
			menu:AddOption(L"rgnYell", function()
				Recognize(3)
			end)
			menu:AddOption(L"rgnFakeName", function()
				local client = LocalPlayer()
				local name = nil
				Derma_StringRequest(L"rgnFakeName", L"fakeNameSub", default or "", function(text)
					if(text) then
						Recognize(2, text)
					end
				end)
			end)
		menu:Open()
		menu:MakePopup()
		menu:Center()
	end)


	function PLUGIN:CharacterRecognized(client)
		surface.PlaySound("buttons/button17.wav")
	end
else

	function PLUGIN:ShowSpare1(client)
		if (client:GetCharacter()) then
			net.Start("ixRecognizeMenu")
				net.WriteEntity(client)
			net.Send(client)
		end
	end

	net.Receive("ixRecognize", function(length, client)
		local level = net.ReadUInt(2)
		local name = net.ReadString()
		
		if (isnumber(level)) then
			local targets = {}

			if (level < 1) then
				local entity = client:GetEyeTraceNoCursor().Entity

				if (IsValid(entity) and entity:IsPlayer() and entity:GetCharacter()
				and ix.chat.classes.ic:CanHear(client, entity)) then
					targets[1] = entity
				end
			else
				local class = "w"

				if (level == 2) then
					class = "ic"
				elseif (level == 3) then
					class = "y"
				end

				class = ix.chat.classes[class]

				for _, v in ipairs(player.GetAll()) do
					if (client != v and v:GetCharacter() and class:CanHear(client, v)) then
						targets[#targets + 1] = v
					end
				end
			end

			if (#targets > 0) then
				local id = client:GetCharacter():GetID()
				local character = client:GetCharacter()
				local i = 0

				for _, v in ipairs(targets) do
					if (v:GetCharacter():Recognize(character, name)) then
						i = i + 1
					end
				end

				if (i > 0) then
					net.Start("ixRecognizeDone")
					net.Send(client)

					hook.Run("CharacterRecognized", client)
				end
			end
		end
	end)
end
