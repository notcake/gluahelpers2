local self = Helpers:CreatePlugin ("Anticrap")
self.UsermessageOverrides = {}

function self:OnEnable ()
	self.UsermessageHooks = self:FindUpValue (usermessage.Hook, "Hooks")
	self.UsermessagesOverridden = {}
	
	timer.Create ("Helpers.Anticrap", 5, 0,
		function ()
			self:OnTick ()
		end
	)
end

function self:OnDisable ()
	timer.Destroy ("Helpers.Anticrap")
end

function self:OnTick ()
	for messageName, handler in pairs (self.UsermessageOverrides) do
		if not self.UsermessagesOverridden [messageName] and self.UsermessageHooks [messageName] then
			self.UsermessageHooks [messageName].Original = self.UsermessageHooks [messageName].Original or self.UsermessageHooks [messageName].Function
			self.UsermessageHooks [messageName].Function =
				function (umsg)
					handler (umsg, self.UsermessageHooks [messageName].Original)
				end
			self.UsermessagesOverridden [messageName] = true
		end
	end
end

function self:RegisterUsermessageOverride (messageName, handler)
	self.UsermessageOverrides [messageName] = handler
end

function self:FindUpValue (func, name)
	local i = 1
	local upValueName, value = debug.getupvalue (func, i)
	while upValueName and upValueName ~= name do
		i = i + 1
		upValueName, value = debug.getupvalue (func, i)
	end
	return value, upValueName
end

self:RegisterUsermessageOverride ("ulx_blind",
	function ()
		chat.AddText (Color (255, 0, 0, 255), "Blocked ulx_blind.")
		
		hook.Remove ("HUDPaint", "ulx_blind")
	end
)

self:RegisterUsermessageOverride ("ulx_fuckface",
	function ()
		chat.AddText (Color (255, 0, 0, 255), "Blocked ulx_fuckface.")
		
		hook.Remove ("HUDPaint", "fuck")
		timer.Destroy ("poop")
	end
)

self:RegisterUsermessageOverride ("ulx_gag",
	function ()
		chat.AddText (Color (255, 0, 0, 255), "Blocked ulx_gag.")
		
		hook.Remove ("PlayerBindPress", "ULXGagForce")
		timer.Destroy ("GagLocalPlayer")
	end
)