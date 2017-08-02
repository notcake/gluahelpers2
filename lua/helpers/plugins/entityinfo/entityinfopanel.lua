local PANEL = {}

function PANEL:Init ()
	self:SetTitle ("Entity Info")
	self:SetZPos (-1)

	self:SetSize (ScrW () * 0.2, ScrH () * 0.3)
	self:SetPos (ScrW () - self:GetWide (), ScrH () * 0.6 / 2)
	self:SetDeleteOnClose (false)
	self:ShowCloseButton (false)
	self:SetAlpha (0)
end

local backgroundColor = Color (64, 64, 64, 192)
local headerColor     = Color (192, 255, 192, 255)
function PANEL:Paint ()
	self:RefreshData ()
	self.LinesDrawn = 0
	draw.RoundedBox (8, 0, 0, self:GetWide (), self:GetTall (), backgroundColor)
	if self.Entity and self.Entity:IsValid () and self.InfoLines then
		surface.SetFont("Default")
		draw.SimpleText (self.Entity:GetClass (), "Trebuchet24", self:GetDrawLeft (), 18, headerColor, 0, 0)
		self.LinesDrawn = self.LinesDrawn + 0.5
		for _, v in pairs (self.InfoLines) do
			if type (v) == "function" then
				v (self)
			else
				self:DrawLine (v)
			end
		end
	end
	return true
end

function PANEL:FadeOut ()
	if self:GetAlpha () < 0 then
		self:SetAlpha (0)
		return
	end
	if self:GetAlpha () == 0 then
		if self.Entity then
			local oldEntity = self.Entity
			self.Entity = nil
			self:OnEntityChanged (oldEntity, self.EntityClass, nil, nil)
			self.EntityClass = nil
		end
		return
	end
	if self.Entity and self.Entity:IsValid () then
		self:SetAlpha (self:GetAlpha () - 2.5)
	else
		self:SetAlpha (self:GetAlpha () - 10)
	end
end

function PANEL:DrawLine (text)
	self.LinesDrawn = self.LinesDrawn + 1
	draw.SimpleText (text, "Default", self:GetDrawLeft (), self:GetDrawTop (), Color (192, 192, 192, 255), 0, 0)
end

function PANEL:GetDrawLeft ()
	return 8
end

function PANEL:GetDrawTop ()
	return 25 + self.LinesDrawn * 14
end

function PANEL:GetLineDrawTop (line)
	return 25 + line * 14
end

function PANEL:GetDrawTall ()
	return 14
end

function PANEL:PerformLayout ()
	DFrame.PerformLayout(self)
end

function PANEL:AddLine (text)
	table.insert (self.InfoLines, text)
end

function PANEL:AddCustomLine (drawfunc)
	table.insert (self.InfoLines, drawfunc)
end

function PANEL:OnEntityChanged (oldEntity, oldEntityClass, newEntity, newEntityClass)
	if oldEntityClass and oldEntityClass:len () == 0 then
		oldEntityClass = nil
	end
	if newEntityClass and newEntityClass:len () == 0 then
		newEntityClass = nil
	end
	oldEntityClass = oldEntityClass or "<none>"
	newEntityClass = newEntityClass or "<none>"
	if oldEntity then
		Helpers:GetPlugin ("Entity Info").Data.Events:DispatchEvent ("EntityChanged", self, newEntity, oldEntity)
	end
end

function PANEL:DoEntityTrace ()
	local trace = util.GetPlayerTrace (LocalPlayer ())
	local delta = (trace.endpos - trace.start)
	trace.endpos = trace.start + (delta:GetNormalized ()) * ((32768 ^ 2 * 3) ^ 0.5)
	local tr = util.TraceLine (trace) or {}
	if tr.HitNonWorld then
		if not LocalPlayer ():InVehicle () then
			return tr.Entity
		end
	end
	return nil
end

function PANEL:RefreshData ()
	local oldEntity = self.Entity
	local oldEntityClass = self.EntityClass
	local newEntity = nil
	local newEntityClass = nil
	self.TraceEntity = self:DoEntityTrace ()
	if self.LockedEntity and self.LockedEntity:IsValid () then
		newEntity = self.LockedEntity
	else
		if self.TraceEntity and self.TraceEntity:IsValid () then
			newEntity = self.TraceEntity
		else
			newEntity = oldEntity
		end
	end
	if oldEntity and not oldEntity:IsValid () then
		oldEntity = nil
	end
	if newEntity and not newEntity:IsValid () then
		newEntity = nil
	end
	if newEntity and newEntity:IsValid () then
		newEntityClass = newEntity:GetClass ()
	else
		self.EntityClass = nil
	end
	self.Entity = newEntity
	self.EntityClass = newEntityClass
	if (!oldEntity and newEntity) or
	   (oldEntity and !newEntity) or
	   (oldEntity and newEntity and oldEntity:EntIndex () != newEntity:EntIndex ()) or
	   (!oldEntity and !newEntity and oldEntityClass) then
		self:OnEntityChanged (oldEntity, oldEntityClass, newEntity, newEntityClass)
	end
	if self.Entity and self.Entity:IsValid () then
		self:PopulateLines ()
		self:SetTall (self:GetLineDrawTop (#self.InfoLines + 2))
	end
	if (self.TraceEntity and self.TraceEntity:IsValid ()) or
	   (self.LockedEntity and self.LockedEntity:IsValid ()) then
		self:SetAlpha (255)
	else
		self:FadeOut ()
	end
end

function PANEL:PopulateLines ()
	self.InfoLines = {}
	if self.Entity:GetClass () == "player" then
		self:AddLine ("Name: " .. self.Entity:Name ())
		self:AddCustomLine (function ()
			self:DrawLine ("Team: ")
			local w = surface.GetTextSize ("Team: ")
			draw.SimpleText (team.GetName (self.Entity:Team ()), "Default", self:GetDrawLeft () + w, self:GetDrawTop (), team.GetColor (self.Entity:Team ()), 0, 0)
		end)
		self:AddLine ("SteamID: " .. self.Entity:SteamID ())
		self:AddLine ("Ping: " .. tostring (self.Entity:Ping ()))
		if self.Entity:GetActiveWeapon ():IsValid () then
			if self.Entity:GetActiveWeapon ():GetClass () == "gmod_tool" and self.Entity:GetActiveWeapon ():GetMode () then
				self:AddLine ("Tool: " .. self.Entity:GetActiveWeapon ():GetMode ())
			else
				self:AddLine ("Weapon: " .. self.Entity:GetActiveWeapon ():GetClass ())
			end
			
			Helpers:GetPlugin ("Entity Info").Data.Events:DispatchEvent ("PopulateWeaponLines", self, self.Entity, self.Entity:GetActiveWeapon ())
		end
		self:AddLine ("")
	end
	self:AddLine ("Index: " .. tostring (self.Entity:EntIndex ()))
	if self.EntityOwnerName and string.len (self.EntityOwnerName) > 0 then
		self:AddLine ("Owner: " .. self.EntityOwnerName)
	end
	self:AddLine ("Model: " .. self.Entity:GetModel ())
	if self.Entity:GetMaterial ():len () > 0 then
		self:AddLine ("Material: " .. self.Entity:GetMaterial ())
	end
	if self.Entity:SkinCount () and self.Entity:SkinCount () > 1 then
		self:AddLine ("Skin: " .. tostring (self.Entity:GetSkin () + 1) .. " (of " .. tostring (self.Entity:SkinCount()) .. ")")
	end
	if self.Entity:Health () > 0 then
		self:AddLine ("Health: " .. tostring (self.Entity:Health ()))
	end
	if self.Entity.Armor and self.Entity:Armor () > 0 then
		self:AddLine ("Armor: " .. tostring (self.Entity:Armor ()))
	end
	local entityColor = self.Entity:GetColor ()
	if entityColor.r ~= 255 or entityColor.g ~= 255 or entityColor.b ~= 255 then
		self:AddCustomLine (function ()
			self:DrawLine ("Color: " .. tostring (entityColor.r) .. ", " .. tostring (entityColor.g) .. ", " .. tostring (entityColor.b))
			local entityColor = self.Entity:GetColor ()
			draw.RoundedBox (4, self:GetWide () - self:GetDrawLeft () - self:GetDrawTall (), self:GetDrawTop (), self:GetDrawTall (), self:GetDrawTall(), Color (0, 0, 0, 255), 0, 0)
			draw.RoundedBox (4, self:GetWide () - self:GetDrawLeft () - self:GetDrawTall () + 1, self:GetDrawTop () + 1, self:GetDrawTall () - 2, self:GetDrawTall () - 2, Color (entityColor.r, entityColor.g, entityColor.b, 255), 0, 0)
		end)
	end
	if entityColor.a ~= 255 then
		self:AddLine ("Alpha: " .. tostring (entityColor.a))
	end
	self:AddLine ("Distance: " .. string.format ("%.2f", (LocalPlayer ():GetPos () - self.Entity:GetPos ()):Length ()))
	
	local angles = self.Entity:GetAngles ()
	self:AddLine ("Angles: " .. string.format ("%.4f", angles.p) .. ", " ..string.format ("%.4f", angles.y) .. ", " .. string.format ("%.4f", angles.r))

	Helpers:GetPlugin ("Entity Info").Data.Events:DispatchEvent ("PopulateLines", self, self.Entity)
end

vgui.Register ("EntityInfoPanel", PANEL, "DFrame")