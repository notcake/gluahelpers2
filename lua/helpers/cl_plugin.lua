local self = {}
Helpers.Plugin = Helpers.MakeConstructor (self)

function self:ctor (name)
	self.Name = name
	self.Enabled = false
	self.CanDisable = true
	
	self.Data = {}
end

function self:Enable ()
	if self.Enabled then return end
	self.Enabled = true
	
	self:OnEnable ()
end

function self:Disable ()
	if not self.Enabled then return end
	if not self.CanDisable then return end
	self.Enabled = false
	
	self:OnDisable ()
end