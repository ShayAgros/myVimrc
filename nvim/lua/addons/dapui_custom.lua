local dap = require('dap')
local dapui = require('dapui')

local custom_watches = {}

local function update_custom_watches()
  local session = dap.session()
  if not session then return end
  
  for _, watch in ipairs(custom_watches) do
    session:request('evaluate', {
      expression = watch.expr,
      context = 'repl',
      frameId = session.current_frame and session.current_frame.id
    }, function(err, resp)
      if not err and resp then
        watch.value = resp.result or 'No result'
      end
    end)
  end
end

local custom_element = {
  render = function(view)
    local lines = {}
    for i, watch in ipairs(custom_watches) do
      table.insert(lines, string.format("[%d] %s = %s", i, watch.expr, watch.value or "..."))
    end
    if #lines == 0 then
      table.insert(lines, "No watches (press 'a' to add)")
    end
    vim.api.nvim_buf_set_lines(view.buf(), 0, -1, false, lines)
  end,
  
  mappings = {
    a = function() 
      local expr = vim.fn.input('Watch: ')
      if expr ~= '' then
        table.insert(custom_watches, {expr = expr, value = nil})
        update_custom_watches()
      end
    end,
    d = function()
      local line = vim.fn.line('.')
      table.remove(custom_watches, line)
    end,
  }
}

dapui.setup({
  elements = {
    { id = "scopes", size = 0.25 },
    { id = "breakpoints", size = 0.25 },
    { id = "stacks", size = 0.25 },
    { id = custom_element, size = 0.25 },
  },
})

dap.listeners.after.event_stopped['custom_watches'] = update_custom_watches
