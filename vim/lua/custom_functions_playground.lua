-- These functions are from subjects I studied

do return end

function my_get_symbol_info()
	local buffer_number = vim.api.nvim_get_current_buf()
	local parameter = vim.lsp.util.make_position_params()
	local buffer_clients = vim.lsp.get_active_clients()

	local all_locations = {}

	for _, client in ipairs(buffer_clients) do
		local response = client.request_sync("textDocument/definition", parameter, nil, buffer_number)
		table.insert(all_locations, response.result)
	end

	print("queried " .. tostring(#buffer_clients) .. " clients in buffer number " .. tostring(buffer_number))
	print("there are", #vim.lsp.get_active_clients(), "client in this buffer")
	print(vim.inspect(parameter))

	if #all_locations > 0 then
		print("Got a response")
		print(vim.inspect(all_locations))
	end
end

function my_resolve_symbol_info()
	-- take the visual selection range
	local params = vim.lsp.util.make_given_range_params(nil, nil, 0, "utf-8")
--	local params = vim.lsp.util.make_position_params(nil, "utf-8")
	vim.pretty_print(params)

	local res = vim.lsp.buf_request_sync(0, "textDocument/ast", params, 1000)
	if res then
		vim.pretty_print(res)
		return
	end
	print("Didn't get response from server")
end
