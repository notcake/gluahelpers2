local self = Helpers:CreatePlugin ("E2Hash")

function self:OnEnable ()
	self.I = 0
	self.Hash = "4027713119"
	self.StartTime = 0
	self.Rate = 0
end

function self:OnDisable ()
	timer.Destroy ("E2Hash")
end

function self:Crack (hash)
	self.Hash = tostring (hash or self.Hash)
	self.I = 0
	self.StartTime = SysTime ()
	timer.Create ("E2Hash", 0, 0, self.DoCrack, self)
end

self.Code =
[[
@name E2 test
G = gTableSafe()
]]

function self:DoCrack ()
	local I = self.I
	local baseCode = self.Code .. "\r\nZZZZZZ = "
	local targetHash = self.Hash
	local testCode = ""
	local testCodeHash = ""
	
	for i = 1, 5000 do
		testCode = baseCode .. I
		testCodeHash = util.CRC (testCode)
		if testCodeHash == targetHash then
			self.NewCode = testCode
			timer.Destroy ("E2Hash")
			ErrorNoHalt ("Cracked.")
		end
		I = I + 1
	end
	
	self.I = I
	self.Rate = self.I / (SysTime () - self.StartTime)
	self.TimeRemaining = (4294967295 - self.I) / self.Rate
end