-- Entity owners - For prop protection

local FPPEntity = nil
local FPPOwner = nil

Helpers:GetPlugin ("Entity Info").Data.Events:AddEventListener ("PopulateLines", function (self, entity)
	self.EntityOwner = nil
	self.EntityOwnerName = nil

	local ownerFound = false

	-- Wiremod owner
	if not ownerFound then
		if self.Entity.GetPlayerName then
			local owner = self.Entity:GetPlayerName ()
			if string.len (owner) > 0 then
				self.EntityOwnerName = owner
				ownerFound = true
			end
		end
	end

	-- SPP owner
	if not ownerFound then
		local ownerEntity = self.Entity:GetNetworkedEntity ("OwnerObj", false)
		if ownerEntity and ownerEntity:IsValid () and ownerEntity:IsPlayer() then
			self.EntityOwner = ownerEntity
			self.EntityOwnerName = ownerEntity:Name ()
			ownerFound = true
		else
			local owner = self.Entity:GetNetworkedString ("Owner", "")
			if type (owner) == "string" then
				if string.len (owner) > 0 then
					self.EntityOwnerName = owner
					ownerFound = true
				end
			elseif owner.ValidEntity and owner:ValidEntity () and owner.Name then
				self.EntityOwner = owner
				self.EntityOwnerName = owner:Name ()
				ownerFound = true
			end
		end
	end
	
	-- SPP owner
	if not ownerFound then
		if SPropProtection and SPropProtection.CLProps then
			local Props = SPropProtection.CLProps
			if Props [self.Entity:EntIndex ()] then
				self.EntityOwner = nil
				self.EntityOwnerName = Props [self.Entity:EntIndex ()]
				ownerFound = true
			end
		end
	end

	-- Citrus owner
	if not ownerFound and self.TraceEntity and self.Entity:EntIndex () == self.TraceEntity:EntIndex () then
		local owner = LocalPlayer ():GetNetworkedString (util.CRC("citrus.PlayerInformation['Entity Guard']['Owner']"))
		if owner and string.len (owner) > 0 then
			self.EntityOwnerName = owner
			ownerFound = true
		end
	end

	-- UPS owner
	if !ownerFound and self.Entity.UOwn then
		self.EntityOwnerName = UPS.nameFromID (self.Entity.UOwn)
		ownerFound = true
	end

	-- FPP owner
	if not ownerFound and FPPEntity and FPPEntity:IsValid () and FPPEntity:EntIndex () == self.Entity:EntIndex () then
		if FPPOwner then
			self.EntityOwnerName = FPPOwner
			ownerFound = true
		end
	end

	-- ASSMod owner
	if not ownerFound then
		local ASSOwner = self.Entity:GetNetworkedEntity ("ASS_Owner")
		if not ASSOwner or not ASSOwner:IsValid () then
			if self.Entity.Player and self.Entity.Player:IsValid () and self.Entity.Player:GetClass () == "player" then
				ASSOwner = self.Entity.Player
			elseif self.Entity.GetPlayer then
				ASSOwner = self.Entity:GetPlayer ()
			end
		end
		if ASSOwner then
			if not ASSOwner:IsValid () or ASSOwner:GetClass () ~= "player" then
				ASSOwner = nil
			end
		end
		if ASSOwner then
			self.EntityOwner = ASSOwner
			self.EntityOwnerName = ASSOwner:Name ()
			ownerFound = true
		end
	end
end)

if CAdmin then
	CAdmin.Usermessages.AddInterceptHook ("FPP_Owner", "Helpers.Entity Info.FPPOwnerInfo", function (hookType, umsg)
		FPPEntity = umsg:ReadEntity ()
		local CanTouchLookingAt = umsg:ReadBool ()
		FPPOwner = umsg:ReadString ()
	end)
end