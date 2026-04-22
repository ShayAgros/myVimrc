#!/bin/bash

# Test file and position
FILE="/local/home/shayagr/workspace/brazil/dev-kermit/src/OscarMysql80/sql/sql_optimizer.cc"
LINE=480
COL=0

# Find running nvim instance
SOCKET=$(ls -t /tmp/nvim-*.sock 2>/dev/null | head -1)

if [ -z "$SOCKET" ]; then
    echo "No running Neovim instance found. Starting one..."
    nvim --headless --listen /tmp/nvim-test-$$.sock -c "lua require('test_lsp_references').test_references('$FILE', $LINE, $COL)" &
    NVIM_PID=$!
    sleep 5
    kill $NVIM_PID 2>/dev/null
else
    echo "Using existing Neovim instance: $SOCKET"
    nvim --server "$SOCKET" --remote-send "<Esc>:lua require('test_lsp_references').test_references('$FILE', $LINE, $COL)<CR>"
fi
