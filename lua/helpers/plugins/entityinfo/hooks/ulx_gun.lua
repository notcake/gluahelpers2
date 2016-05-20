-- ulx_gun firing modes
local FireModes = {
	"Kick",
	"Ban",
	"Freeze",
	"Jail",
	"Mute",
	"Blind",
	"Ignite"
}

Helpers:GetPlugin ("Entity Info").Data.Events:AddEventListener ("PopulateWeaponLines", function (self, entity, weapon)
	if not entity or not entity:IsValid () then return end
	if not weapon or not weapon:IsValid () then return end
	
	if entity:GetClass () == "player" then
		if weapon:GetClass () == "ulx_gun" then
			local Mode = entity:GetNetworkedInt ("FireMode")
			local desc = FireModes [Mode]
			if desc then
				self:AddLine ("ULX Gun Mode: " .. desc)
			end
		end
	end
end)