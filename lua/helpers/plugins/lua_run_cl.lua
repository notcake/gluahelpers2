local self = Helpers:CreatePlugin ("lua_run_cl")

function self:OnEnable ()
	self.Code = ""

	concommand.Add ("lua_run_cl2",
		function ()
			local output = ""
			local _print = print
			local _Msg   = Msg
			function Msg (...)
				_Msg (...)
				output = output .. table.concat ({...}, "\t")
			end
			function print (...)
				_print (...)
				output = output .. table.concat ({...}, "\t") .. "\n"
			end
			pcall (CompileString (self.Code, "lua_run_cl"))
			print = _print
			Msg   = _Msg
			
			if output ~= "" and COH2 then
				COH2:ChatStart ()
				COH2:ChatUpdate ("lua_run_cl:\n\nCode:\n\t" .. self.Code:gsub ("\n", "\n\t") .. "\nOutput:\n\t" .. output:gsub ("\n", "\n\t"))
			end
		end,
		function (_, args)
			self.Code = args
		end
	)
end

function self:OnDisable ()
end