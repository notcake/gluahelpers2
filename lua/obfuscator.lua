function transfer(code)
	local encoded = E2Lib.encode (code)
	local length = encoded:len ()
	local chunks = math.ceil (length / 480)
	
	Expression2SetProgress (0)
	RunConsoleCommand ("wire_expression_upload_begin", code:len (), chunks)
	
	timer.Create ("wire_expression_upload", 1/60, chunks, transfer_callback, { encoded, 1, chunks })
end