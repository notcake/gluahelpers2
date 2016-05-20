local self = Helpers:CreatePlugin ("PACLOL")

local hats = 
{
	"models/player/items/all_class/oh_xmas_tree_sniper.mdl",
	"models/player/items/spy/fwk_spy_disguisedhat.mdl",
	"models/player/items/sniper/hat_first_nr.mdl"
}

function self:OnEnable ()
	timer.Create ("PACLOL", 5, 0, function ()
		if not LocalPlayer or not LocalPlayer () or not LocalPlayer ():IsValid () then return end
		
		local config = LocalPlayer ().CurrentPACConfig
		if not config then return end
		
		usermessage.GetTable () ["PACSubmissionAcknowledged"] = 
		{
			Function = function () return end,
			PreArgs = {}
		}
		
		local scale = math.random () * 2
		-- config.overall_scale = Vector (scale, scale, scale)
		
		if config.parts and config.parts [1] then
			config.parts [1].model = table.Random (hats)
			config.parts [1].bone = "head"
			config.parts [1].offset = Vector (2, 2, 0)
			config.parts [1].angles = Angle (0, -90, -90)
		end
		
		-- LocalPlayer ():SetPACConfig (LocalPlayer ():GetPACConfig ())
	end)
end

function self:OnDisable ()
	timer.Destroy ("PACLOL")
end