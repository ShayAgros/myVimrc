local dap = require('dap')
local dapui = require('dapui')

-- Setup DAP UI
dapui.setup()

-- Configure DAP signs
vim.fn.sign_define('DapStopped', { text='→', texthl='DapStopped', linehl='CursorLine', numhl='DapStopped' })
vim.fn.sign_define('DapBreakpoint', { text='●', texthl='DapBreakpoint', linehl='', numhl='' })
vim.fn.sign_define('DapBreakpointCondition', { text='◆', texthl='DapBreakpoint', linehl='', numhl='' })
vim.fn.sign_define('DapBreakpointRejected', { text='○', texthl='DapBreakpoint', linehl='', numhl='' })
vim.fn.sign_define('DapLogPoint', { text='◎', texthl='DapLogPoint', linehl='', numhl='' })

-- Custom hover implementation
local function get_c_expression_at_cursor()
  local ts = vim.treesitter
  local node = ts.get_node()
  if not node then return vim.fn.expand('<cword>') end
  
  -- Walk up to find field_expression or call_expression
  while node do
    local type = node:type()
    if type == 'field_expression' or type == 'subscript_expression' or type == 'call_expression' then
      return vim.treesitter.get_node_text(node, 0)
    end
    node = node:parent()
  end
  
  return vim.fn.expand('<cword>')
end

local function debug_hover()
  local session = dap.session()
  if not session then
    vim.notify('No active debug session', vim.log.levels.WARN)
    return
  end
  
  local expr
  local mode = vim.fn.mode()
  if mode == 'v' or mode == 'V' then
    vim.cmd('normal! "vy')
    expr = vim.fn.getreg('v')
  else
    local default_expr = get_c_expression_at_cursor()
    expr = vim.fn.input('Expression: ', default_expr)
    if expr == '' then return end
  end
  
  -- Ensure we have a valid frame
  if not session.current_frame then
    session:_request_threads(function()
      if session.stopped_thread_id then
        session:request('stackTrace', { threadId = session.stopped_thread_id }, function(err, resp)
          if not err and resp and resp.stackFrames and #resp.stackFrames > 0 then
            session.current_frame = resp.stackFrames[1]
          end
        end)
      end
    end)
  end
  
  session:request('evaluate', {
    expression = 'print ' .. expr,
    context = 'repl',
    frameId = session.current_frame and session.current_frame.id
  }, function(err, resp)
    if err then
      vim.notify('Error: ' .. vim.inspect(err), vim.log.levels.ERROR)
      return
    end
    
    local result = resp.result or resp.body and resp.body.result or 'No result'
    local buf = vim.api.nvim_create_buf(false, true)
    local lines = vim.split(result, '\n')
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].modifiable = false
    vim.bo[buf].bufhidden = 'wipe'
    
    local width = math.min(80, vim.o.columns - 4)
    local height = math.min(#lines, 20)
    local win = vim.api.nvim_open_win(buf, false, {
      relative = 'cursor',
      row = 1,
      col = 0,
      width = width,
      height = height,
      style = 'minimal',
      border = 'rounded',
      focusable = false
    })
    
    -- Close on cursor move
    vim.api.nvim_create_autocmd({'CursorMoved', 'CursorMovedI', 'BufLeave'}, {
      callback = function()
        if vim.api.nvim_win_is_valid(win) then
          vim.api.nvim_win_close(win, true)
        end
        return true
      end,
      once = true
    })
  end)
end

-- Auto-open/close UI and set debug keymaps
dap.listeners.after.event_initialized['dapui_config'] = function()
  dapui.open()
  vim.keymap.set({'n', 'v'}, 'K', debug_hover, { buffer = 0, desc = 'Debug: Hover' })
  vim.keymap.set('n', '<Leader>df', function() require('dap.ui.widgets').centered_float(require('dap.ui.widgets').frames) end, { buffer = 0, desc = 'Debug: Frames' })
  vim.keymap.set('n', '<Leader>dv', function() require('dap.ui.widgets').centered_float(require('dap.ui.widgets').scopes) end, { buffer = 0, desc = 'Debug: Scopes' })
end
dap.listeners.before.event_terminated['dapui_config'] = function()
  dapui.close()
end
dap.listeners.before.event_exited['dapui_config'] = function()
  dapui.close()
end

-- Load language-specific DAP configurations
if vim.fn.executable('gdb') == 1 then
    require('addons.dap.c')
end

require('addons.dap.lua')

-- Keymaps for debugging
vim.keymap.set('n', '<F5>', function() require('dap').continue() end, { desc = 'Debug: Continue' })
vim.keymap.set('n', '<Leader><F5>', function()
  vim.ui.select({'c', 'cpp', 'lua'}, {
    prompt = 'Select language:',
  }, function(choice)
    if choice then
      require('dap').continue({filetype = choice})
    end
  end)
end, { desc = 'Debug: Select Language' })
vim.keymap.set('n', '<F10>', function() require('dap').step_over() end, { desc = 'Debug: Step Over' })
vim.keymap.set('n', '<F11>', function() require('dap').step_into() end, { desc = 'Debug: Step Into' })
vim.keymap.set('n', '<F12>', function() require('dap').step_out() end, { desc = 'Debug: Step Out' })
vim.keymap.set('n', '<Leader>b', function() require('dap').toggle_breakpoint() end, { desc = 'Debug: Toggle Breakpoint' })
vim.keymap.set('n', '<Leader>gr', function() require('dap').repl.open() end, { desc = 'Debug: Open REPL' })
vim.keymap.set('n', '<Leader>gc', function()
  local cmd = vim.fn.input('GDB command: ')
  if cmd ~= '' then
    require('dap').repl.execute('-exec ' .. cmd)
  end
end, { desc = 'Debug: GDB Command' })
vim.keymap.set('n', '<Leader>gu', function() require('dapui').toggle() end, { desc = 'Debug: Toggle UI' })

-- Start debug server and attach
vim.keymap.set('n', '<Leader>gs', function()
  require('osv').launch({port = 8086})
  vim.notify("Debug server started on port 8086", vim.log.levels.INFO)
end, { desc = 'Debug: Start Server' })

vim.keymap.set('n', '<Leader>ga', function()
  require('dap').continue()
  vim.notify("Attached to debug server", vim.log.levels.INFO)
end, { desc = 'Debug: Attach' })
