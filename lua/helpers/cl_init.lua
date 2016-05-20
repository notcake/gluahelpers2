Helpers = Helpers or {}
Helpers.Plugins = Helpers.Plugins or {}

include ("helpers/sh_oop.lua")
include ("helpers/sh_eventprovider.lua")
include ("helpers/cl_plugin.lua")

function Helpers:CreatePlugin (pluginName)
	if self.Plugins [pluginName] then
		self.Plugins [pluginName]:Disable ()
	end
	
	self.Plugins [pluginName] = self.Plugin (pluginName)
	return self.Plugins [pluginName]
end

function Helpers:GetPlugin (pluginName)
	return self.Plugins [pluginName]
end

local pluginFiles = file.Find ("helpers/plugins/*.lua", "LUA")
local pluginSet = {}
for _, pluginFile in ipairs (pluginFiles) do
	pluginSet [pluginFile] = true
end

if GetConVar ("sv_allowcslua"):GetBool () then
	pluginFiles = file.Find ("helpers/plugins/*.lua", "LCL")
	pluginSet = {}
	for _, pluginFile in ipairs (pluginFiles) do
		pluginSet [pluginFile] = true
	end
end

for pluginFile, _ in pairs (pluginSet) do
	include ("helpers/plugins/" .. pluginFile)
end

timer.Simple (1, function ()
	for pluginName, plugin in pairs (Helpers.Plugins) do
		plugin:Enable ()
	end
end)