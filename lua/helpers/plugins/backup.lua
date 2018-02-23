local self = Helpers:CreatePlugin ("File Backup")
self.CanDisable = false

function self:OnEnable ()
	self.Data.file = self.Data.file or {}
	self.Data.filex = self.Data.filex or {}
	self.Data.hook = {}
	
	self.Data.file.Append = file.Append
	self.Data.file.Delete = file.Delete
	self.Data.file.Write = file.Write
	
	if filex then
		self.Data.filex.Append = filex.Append
	end

	self.Data.hook.Append = function (fileName, fileContents, ...)
		file.Write = self.Data.file.Write
		self.Data.file.Append (fileName, fileContents, ...)
		file.Write = self.Data.hook.Write
	end
	
	self.Data.hook.Delete = function (fileName, ...)
		if file.Exists (fileName, "DATA", ...) and
		   self:ShouldBackup (fileName) then
			self:Backup (fileName, ...)
		end
		self.Data.file.Delete (fileName, ...)
	end

	self.Data.hook.Write = function (fileName, fileContents, ...)
		if file.Exists (fileName, "DATA", ...) and
		   self:ShouldBackup (fileName) then
			self:Backup (fileName, ...)
		end
		self.Data.file.Write (fileName, fileContents, ...)
	end
	
	file.Append = self.Data.hook.Append
	file.Delete = self.Data.hook.Delete
	file.Write = self.Data.hook.Write
	
	if filex then
		filex.Append = self.Data.hook.Append
	end
end

function self:OnDisable ()
	file.Append = self.Data.file.Append
	file.Delete = self.Data.file.Delete
	file.Write = self.Data.file.Write
	
	if filex then
		filex.Append = self.Data.filex.Append
	end
end

function self:Backup (filePath, ...)
	local fileContents = file.Read (filePath, "DATA", ...)
	if not fileContents or fileContents == 0 then return end
	
	local formattedDate = os.date ("%Y%m%d-%H%M%S")
	local backupDirectory = "backup/" .. string.GetPathFromFilename (filePath)
	file.CreateDir (backupDirectory)
	
	local fileName = string.GetFileFromFilename (filePath)
	if not fileName or fileName == "" then
		fileName = filePath
	end
	
	local backupPath = backupDirectory .. formattedDate .. "_" .. fileName
	self.Data.file.Write (backupPath, fileContents, ...)
end

function self:ShouldBackup (filePath)
	if string.find (filePath, "^pac3_cache/") then return false end
	
	return true
end
