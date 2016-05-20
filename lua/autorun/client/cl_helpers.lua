include ("helpers/cl_init.lua")

concommand.Add ("helpers_reload", function ()
	include ("autorun/client/cl_helpers.lua")
end)