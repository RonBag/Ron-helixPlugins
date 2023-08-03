ITEM.name = "Stimulant"
ITEM.model = "models/props_wasteland/prison_toiletchunk01f.mdl"
ITEM.description = "Used to stabilize a person who is bleeding out."
ITEM.category = "Medical"

ITEM.functions.Stabilize = { 
	name = "Stabilize",
	tip = "Stabilize the target character.",
	icon = "icon16/user_add.png",
	OnRun = function(item)
        local ply = item.player
        local trace = ply:GetEyeTraceNoCursor()
		local target = trace.Entity
        ply:SetAction("@stabilizing", 10)
        ply:DoStaredAction(target, function()
			hook.Run("Stabilize", target.ixPlayer)
        end, 10)

	end,

    OnCanRun =  function(item)
        local ply = item.player
		local trace = ply:GetEyeTraceNoCursor()
		local target = trace.Entity
        return target:GetClass()=="prop_ragdoll"
    end
}
