X86 = {}
X86.ChunkSize = 64 * 1024
X86.ChunkCount = 20
X86.HexToDec = 
{
	["0"] = 0,
	["1"] = 1,
	["2"] = 2,
	["3"] = 3,
	["4"] = 4,
	["5"] = 5,
	["6"] = 6,
	["7"] = 7,
	["8"] = 8,
	["9"] = 9,
	["a"] = 10,
	["b"] = 11,
	["c"] = 12,
	["d"] = 13,
	["e"] = 14,
	["f"] = 15,
}

RunConsoleCommand ("wire_expression2_quotahard", "1000000")
RunConsoleCommand ("wire_expression2_quotasoft", "50000")
RunConsoleCommand ("wire_expression2_quotatick", "250000")

function X86.LoadChunk (filename, array, startIndex)
	local endIndex = startIndex + X86.ChunkSize - 1
	local str = file.Read (filename)
	for i = startIndex, endIndex do
		local byte = str:sub ((i - startIndex) * 2 + 1, (i - startIndex) * 2 + 2)
		local num = X86.HexToDec [byte:sub (1, 1)] * 16 + X86.HexToDec [byte:sub (2, 2)]
		array [-i] = num
	end
end

function X86.SaveChunk (filename, array, startIndex)
	local endIndex = startIndex + X86.ChunkSize - 1
	local str = ""
	for i = startIndex, endIndex do
		str = str .. string.format ("%.2x", array [-i] or 0)
	end
	file.Write (filename, str)
end

function X86.LoadRAM ()
	local ram = {}
	for i = 0, X86.ChunkCount - 1 do
		X86.LoadChunk ("x86_ram_" .. i .. ".txt", ram, i * X86.ChunkSize)
	end
	return ram
end

function X86.SaveRAM (ram)
	for i = 0, X86.ChunkCount - 1 do
		X86.SaveChunk ("x86_ram_" .. i .. ".txt", ram, i * X86.ChunkSize)
	end
end