ITEM.name = "Stimulant"
ITEM.model = "models/props_c17/TrapPropeller_Lever.mdl"
ITEM.description = "Used to stabilize a person who is bleeding out."
ITEM.category = "Medical"

ITEM.functions.Stabilize = { 
	name = "Stabilize",
	tip = "Stabilize the target character.",
	icon = "icon16/user_add.png",
	OnRun = function(item)
		local player = item.player
		local trace = player:GetEyeTraceNoCursor()
		local target = trace.Entity

		if(!target.ixPlayer) then
			player:Notify("You must be looking at a player!")
			return false
		end
	
		player:SetAction("@stabilizing", 10)
		player:DoStaredAction(target, function()
			hook.Run("Revive", target.ixPlayer)
		end, 10)

	end,

	OnCanRun =  function(item)
		local ent = item.player:GetEyeTraceNoCursor().Entity
		
		return ent:IsRagdoll()
	end
}
