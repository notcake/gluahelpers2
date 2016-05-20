local self = Helpers:CreatePlugin ("Entity Info")
self.Data.Events = Helpers.EventProvider ()
include ("helpers/plugins/entityinfo/entityinfopanel.lua")

local hookFiles = file.Find ("helpers/plugins/entityinfo/hooks/*.lua", "LCL")
for _, hookFile in ipairs (hookFiles) do
	include ("helpers/plugins/entityinfo/hooks/" .. hookFile)
end

function self:OnEnable ()
	self.Data.Panel = vgui.Create ("EntityInfoPanel")
end

function self:OnDisable ()
	self.Data.Panel:Remove ()
end