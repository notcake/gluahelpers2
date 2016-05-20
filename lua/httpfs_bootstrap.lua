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

function httpfs.endofqueue () end

function httpfs.runentity (path, classname)
	local _ENT = ENT
	ENT = {}
	httpfs.run (path)
	scripted_ents.Register (ENT, classname, true)
	ENT = _ENT
end

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

local dropbox = "http://cakesaddons.googlecode.com/svn/trunk/gooey/lua"
local files =
{
	"autorun/sh_gooey.lua",
	"gooey/sh_eventprovider.lua",
	"gooey/sh_init.lua",
	"gooey/sh_oop.lua",
	"gooey/sh_resources.lua",
	"gooey/sh_unicode.lua",
	"gooey/ui/cl_controls.lua",
	"gooey/ui/cl_imagecache.lua",
	"gooey/ui/cl_imagecacheentry.lua",
	"gooey/ui/cl_selectioncontroller.lua",
	"gooey/ui/controls/gbutton.lua",
	"gooey/ui/controls/gcheckbox.lua",
	"gooey/ui/controls/gcodeeditor.lua",
	"gooey/ui/controls/gcombobox.lua",
	"gooey/ui/controls/gcomboboxitem.lua",
	"gooey/ui/controls/geditablelabel.lua",
	"gooey/ui/controls/ggroupbox.lua",
	"gooey/ui/controls/gimage.lua",
	"gooey/ui/controls/glistview.lua",
	"gooey/ui/controls/glistviewcolumn.lua",
	"gooey/ui/controls/glistviewitem.lua",
	"gooey/ui/controls/gmenu.lua",
	"gooey/ui/controls/gmenuitem.lua",
	"gooey/ui/controls/gmodelchoice.lua",
	"gooey/ui/controls/gmultichoice.lua",
	"gooey/ui/controls/gmultichoicex.lua",
	"gooey/ui/controls/gpanel.lua",
	"gooey/ui/controls/gpanellist.lua",
	"gooey/ui/controls/gtoolbar.lua",
	"gooey/ui/controls/gtoolbarbutton.lua",
	"gooey/ui/controls/gtoolbaritem.lua",
	"gooey/ui/controls/gtoolbarseparator.lua",
	"gooey/ui/controls/gtreeview.lua",
	"gooey/ui/controls/gtreeviewnode.lua",
	"gooey/ui/controls/gvpanel.lua",
	"gooey/ui/controls/gworldview.lua"
}
for _, v in pairs (files) do
	httpfs.dl (v, dropbox .. "/" .. v)
end
local dropbox = "http://cakesaddons.googlecode.com/svn/trunk/vfs/lua"
local files =
{
	"autorun/gauth.lua",
	"autorun/vfs.lua",
	"glib/eventprovider.lua",
	"glib/glib.lua",
	"glib/playermonitor.lua",
	"glib/utf8.lua",
	"glib/net/concommanddispatcher.lua",
	"glib/net/concommandinbuffer.lua",
	"glib/net/datastreaminbuffer.lua",
	"glib/net/datatype.lua",
	"glib/net/net.lua",
	"glib/net/outbuffer.lua",
	"glib/net/stringtable.lua",
	"glib/net/usermessagedispatcher.lua",
	"glib/net/usermessageinbuffer.lua",
	"glib/protocol/channel.lua",
	"glib/protocol/endpoint.lua",
	"glib/protocol/endpointmanager.lua",
	"glib/protocol/protocol.lua",
	"glib/protocol/session.lua",
	"gauth/access.lua",
	"gauth/gauth.lua",
	"gauth/group.lua",
	"gauth/grouptree.lua",
	"gauth/grouptreenode.lua",
	"gauth/grouptreesender.lua",
	"gauth/permissionblock.lua",
	"gauth/permissionblocknetworker.lua",
	"gauth/permissionblocknetworkermanager.lua",
	"gauth/permissiondictionary.lua",
	"gauth/returncode.lua",
	"gauth/protocol/endpoint.lua",
	"gauth/protocol/endpointmanager.lua",
	"gauth/protocol/initialsyncrequest.lua",
	"gauth/protocol/nodeadditionnotification.lua",
	"gauth/protocol/nodeadditionrequest.lua",
	"gauth/protocol/nodeadditionresponse.lua",
	"gauth/protocol/noderemovalnotification.lua",
	"gauth/protocol/noderemovalrequest.lua",
	"gauth/protocol/noderemovalresponse.lua",
	"gauth/protocol/permissionblocknotification.lua",
	"gauth/protocol/permissionblockrequest.lua",
	"gauth/protocol/permissionblockresponse.lua",
	"gauth/protocol/protocol.lua",
	"gauth/protocol/session.lua",
	"gauth/protocol/useradditionnotification.lua",
	"gauth/protocol/useradditionrequest.lua",
	"gauth/protocol/useradditionresponse.lua",
	"gauth/protocol/userremovalnotification.lua",
	"gauth/protocol/userremovalrequest.lua",
	"gauth/protocol/userremovalresponse.lua",
	"gauth/protocol/permissionblock/groupentryadditionnotification.lua",
	"gauth/protocol/permissionblock/groupentryadditionrequest.lua",
	"gauth/protocol/permissionblock/groupentryadditionresponse.lua",
	"gauth/protocol/permissionblock/groupentryremovalnotification.lua",
	"gauth/protocol/permissionblock/groupentryremovalrequest.lua",
	"gauth/protocol/permissionblock/groupentryremovalresponse.lua",
	"gauth/protocol/permissionblock/grouppermissionchangenotification.lua",
	"gauth/protocol/permissionblock/grouppermissionchangerequest.lua",
	"gauth/protocol/permissionblock/grouppermissionchangeresponse.lua",
	"gauth/protocol/permissionblock/inheritownerchangenotification.lua",
	"gauth/protocol/permissionblock/inheritownerchangerequest.lua",
	"gauth/protocol/permissionblock/inheritownerchangeresponse.lua",
	"gauth/protocol/permissionblock/inheritpermissionschangenotification.lua",
	"gauth/protocol/permissionblock/inheritpermissionschangerequest.lua",
	"gauth/protocol/permissionblock/inheritpermissionschangeresponse.lua",
	"gauth/protocol/permissionblock/ownerchangenotification.lua",
	"gauth/protocol/permissionblock/ownerchangerequest.lua",
	"gauth/protocol/permissionblock/ownerchangeresponse.lua",
	"gauth/ui/groupbrowser.lua",
	"gauth/ui/groupbrowser_frame.lua",
	"gauth/ui/grouplistview.lua",
	"gauth/ui/groupselectiondialog.lua",
	"gauth/ui/grouptreeview.lua",
	"gauth/ui/permissions.lua",
	"gauth/ui/userlistview.lua",
	"gauth/ui/userselectiondialog.lua",
	"vfs/openflags.lua",
	"vfs/path.lua",
	"vfs/returncode.lua",
	"vfs/seektype.lua",
	"vfs/updateflags.lua",
	"vfs/vfs.lua",
	-- "vfs/adaptors/expression2_editor.lua",
	-- "vfs/adaptors/expression2_files.lua",
	-- "vfs/adaptors/expression2_upload.lua",
	"vfs/filesystem/ifile.lua",
	"vfs/filesystem/ifilestream.lua",
	"vfs/filesystem/ifolder.lua",
	"vfs/filesystem/inode.lua",
	"vfs/filesystem/mountedfile.lua",
	"vfs/filesystem/mountedfilestream.lua",
	"vfs/filesystem/mountedfolder.lua",
	"vfs/filesystem/mountednode.lua",
	"vfs/filesystem/netfile.lua",
	"vfs/filesystem/netfilestream.lua",
	"vfs/filesystem/netfolder.lua",
	"vfs/filesystem/netnode.lua",
	"vfs/filesystem/nodetype.lua",
	"vfs/filesystem/realfile.lua",
	"vfs/filesystem/realfilestream.lua",
	"vfs/filesystem/realfolder.lua",
	"vfs/filesystem/realnode.lua",
	"vfs/filesystem/vfile.lua",
	"vfs/filesystem/vfilestream.lua",
	"vfs/filesystem/vfolder.lua",
	"vfs/filesystem/vnode.lua",
	"vfs/protocol/endpoint.lua",
	"vfs/protocol/endpointmanager.lua",
	"vfs/protocol/fileopenrequest.lua",
	"vfs/protocol/fileopenresponse.lua",
	"vfs/protocol/folderchildrequest.lua",
	"vfs/protocol/folderchildresponse.lua",
	"vfs/protocol/folderlistingrequest.lua",
	"vfs/protocol/folderlistingresponse.lua",
	"vfs/protocol/nodecreationnotification.lua",
	"vfs/protocol/nodecreationrequest.lua",
	"vfs/protocol/nodecreationresponse.lua",
	"vfs/protocol/nodedeletionnotification.lua",
	"vfs/protocol/nodedeletionrequest.lua",
	"vfs/protocol/nodedeletionresponse.lua",
	"vfs/protocol/noderenamenotification.lua",
	"vfs/protocol/noderenamerequest.lua",
	"vfs/protocol/noderenameresponse.lua",
	"vfs/protocol/nodeupdatenotification.lua",
	"vfs/protocol/protocol.lua",
	"vfs/protocol/session.lua",
	"vfs/ui/editor.lua",
	"vfs/ui/editor_frame.lua",
	"vfs/ui/folderlistview.lua",
	"vfs/ui/foldertreeview.lua",
	"vfs/ui/fsbrowser.lua",
	"vfs/ui/fsbrowser_frame.lua",
	"vfs/ui/savefiledialog.lua"
}
for _, v in pairs (files) do
	httpfs.dl (v, dropbox .. "/" .. v)
end

httpfs.queueaction (
	function ()
		httpfs.run ("autorun/sh_gooey.lua")
		httpfs.run ("autorun/gauth.lua")
		httpfs.run ("autorun/vfs.lua")
		
		if SERVER then
			--BroadcastLua ([[chat.AddText("HTTPFS initialized.")]])
		else
			--RunConsoleCommand ("say", "HTTPFS initialized.")
		end
		httpfs.nextaction ()
	end
)

httpfs.nextaction ()