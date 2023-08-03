util.AddNetworkString("BleedingOut")

function PLUGIN:PostPlayerDeath(ply)
	local char = ply:GetCharacter()

	if(char and char:GetBleedout()) then
		char:SetBleedout(false)
		net.Start("BleedingOut")
		net.Send(ply)
	end
end

hook.Add("PlayerSpawn", "Player_Spawned", function(ply)
	local char = ply:GetCharacter()
	if (char and char:GetBleedout()) then
		ply:NotifyLocalized("bledOut")
		ply:Kill()
	end
end)


