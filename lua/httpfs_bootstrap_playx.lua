httpfs = httpfs or {}
httpfs.root = httpfs.root or {}
httpfs.queue = {}
httpfs.pathstack = {""}

-- File access
function httpfs.write (path, data)
	local parts = httpfs.normalizepath (path):Split ("/")
	local folder = httpfs.root
	for i = 1, #parts - 1 do
		-- create subfolder
		folder [parts [i]] = folder [parts [i]] or {}
		folder = folder [parts [i]]
	end
	folder [parts [#parts]] = data
end

function httpfs.read (path)
	local parts = httpfs.normalizepath (path):Split ("/")
	local folder = httpfs.root
	for i = 1, #parts do
		folder = folder [parts [i]]
		if not folder then return nil end
	end
	return tostring (folder)
end

function httpfs.getfolder (path)
	local parts = httpfs.normalizepath (path):Split ("/")
	local folder = httpfs.root
	for i = 1, #parts do
		folder = folder [parts [i]]
		if not folder then return nil end
	end
	return folder
end

-- Paths
function httpfs.normalizepath (path)
	path = path:lower ()
	path = path:gsub ("\\", "/")
	path = path:gsub ("/+", "/")
	if path:sub (1, 1) == "/" then path = path:sub (2) end
	return path
end

function httpfs.poppath ()
	httpfs.pathstack [#httpfs.pathstack] = nil
end

function httpfs.pushpath (path)
	httpfs.pathstack [#httpfs.pathstack + 1] = path
end

function httpfs.toppath ()
	return httpfs.pathstack [#httpfs.pathstack]
end

function httpfs.dl (path, url)
	httpfs.queueaction (
		function ()
			print ("HTTPFS: " .. path .. " = " .. url)
			http.Get (url, "",
				function (contents, size)
					if contents:len () == 0 then
						ErrorNoHalt ("HTTPFS: " .. url .. ": Failed to load.\n")
					end
					httpfs.write (path, contents)
					httpfs.nextaction ()
				end
			)
		end
	)
end

-- file library override
function httpfs.AddCSLuaFile () end

function httpfs.FindInLua (path)
	print ("HTTPFS: FindInLua " .. path)
	local parts = httpfs.normalizepath (path):Split ("/")
	parts [#parts] = nil
	path = table.concat (parts, "/")
	local folder = httpfs.getfolder (path)
	local result = {}
	for k, _ in pairs (folder or {}) do
		result [#result + 1] = k
	end
	return result
end

function httpfs.include (codepath)
	local _AddCSLuaFile = AddCSLuaFile
	AddCSLuaFile = httpfs.AddCSLuaFile
	local _FindInLua = file.FindInLua
	file.FindInLua = httpfs.FindInLua

	local realpath = httpfs.toppath () .. "/" .. codepath
	local code = httpfs.read (httpfs.toppath () .. "/" .. codepath)
	if code then
		print ("HTTPFS: Run " .. httpfs.toppath () .. "/" .. codepath)
	else
		realpath = codepath
		code = httpfs.read (codepath)
		if code then
			print ("HTTPFS: Run " .. codepath)
		else
			ErrorNoHalt ("HTTPFS: Run " .. codepath .. ": File not found.\n")
		end
	end
	
	local parts = httpfs.normalizepath (realpath):Split ("/")
	parts [#parts] = nil
	httpfs.pushpath (table.concat (parts, "/"))
	if code then
		code = code:gsub ("include%(", "include (")
		code = code:gsub ("include %(", "httpfs.include (")
		code = code:gsub ("g_silkicons", "silkicons")
		local func = CompileString (code, httpfs.normalizepath (realpath))
		if func then pcall (func) end
	end
	httpfs.poppath ()
	
	AddCSLuaFile = _AddCSLuaFile
	file.FindInLua = _FindInLua
end

function httpfs.run (path)
	httpfs.include (path)
end

function httpfs.runentity (path, classname)
	local _ENT = ENT
	ENT = {}
	httpfs.run (path)
	scripted_ents.Register (ENT, classname, true)
	ENT = _ENT
end

function httpfs.endofqueue () end

function httpfs.nextaction ()
	if #httpfs.queue == 0 then
		httpfs.endofqueue ()
		return
	end
	local action = httpfs.queue [1]
	table.remove (httpfs.queue, 1)
	action ()
end

function httpfs.queueaction (action)
	httpfs.queue [#httpfs.queue + 1] = action
end

function httpfs.setendofqueue (func)
	httpfs.endofqueue = func or httpfs.endofqueue
end

local dropbox = "http://playx.googlecode.com/svn/branches/latest-stable/PlayX/lua"
local files =
{
	"playxlib.lua",
	"autorun/client/playx_init.lua",
	"autorun/server/playx_init.lua",
	"autorun/server/playx_media_query.lua",
	"entities/gmod_playx/cl_init.lua",
	"entities/gmod_playx/init.lua",
	"entities/gmod_playx/shared.lua",
	"entities/gmod_playx_repeater/cl_init.lua",
	"entities/gmod_playx_repeater/init.lua",
	"entities/gmod_playx_repeater/shared.lua",
	"playx/playx.lua",
	"playx/client/bookmarks.lua",
	"playx/client/panel.lua",
	"playx/client/playx.lua",
	"playx/client/handlers/default.lua",
	"playx/client/handlers/sites.lua",
	"playx/client/vgui/PlayXBrowser.lua",
	"playx/providers/filetypes.lua",
	"playx/providers/flash.lua",
	"playx/providers/hulu.lua",
	"playx/providers/justin.tv.lua",
	"playx/providers/livestream.lua",
	"playx/providers/vimeo.lua",
	"playx/providers/web.lua",
	"playx/providers/youtube.lua"
}
for _, v in pairs (files) do
	httpfs.dl (v, dropbox .. "/" .. v)
end

httpfs.queueaction (
	function ()
		if CLIENT then httpfs.run ("autorun/client/playx_init.lua") end
		if SERVER then httpfs.run ("autorun/server/playx_init.lua") end
		if SERVER then httpfs.run ("autorun/server/playx_media_query.lua") end
		if CLIENT then httpfs.runentity ("entities/gmod_playx/cl_init.lua", "gmod_playx") end
		if SERVER then httpfs.runentity ("entities/gmod_playx/init.lua", "gmod_playx") end
		if CLIENT then httpfs.runentity ("entities/gmod_playx_repeater/cl_init.lua", "gmod_playx_repeater") end
		if SERVER then httpfs.runentity ("entities/gmod_playx_repeater/init.lua", "gmod_playx_repeater") end
		
		if SERVER then
			--BroadcastLua ([[chat.AddText("HTTPFS initialized.")]])
		else
			--RunConsoleCommand ("say", "HTTPFS initialized.")
		end
		httpfs.nextaction ()
	end
)

httpfs.nextaction ()