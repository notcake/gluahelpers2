Helpers:GetPlugin ("Entity Info").Data.Events:AddEventListener ("PopulateLines", function (self, entity)
	if not entity or not entity:IsValid () then return end
	
	if entity:GetClass () == "gmod_wire_textscreen" then
		self:AddLine ("Text: " .. entity.text)
	end
end)