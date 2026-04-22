# LSP References Filter - Assignment Detection

## Overview
Added functionality to filter LSP references to show only assignments to a symbol using treesitter AST analysis.

## Implementation

### Location
`nvim/lua/addons/lsp_references_filter.lua`

### Key Functions

1. **`is_assignment(file_path, line_num, symbol_name)`**
   - Returns `true` if the line contains an assignment TO the symbol
   - Uses treesitter to parse C/C++ AST
   - Distinguishes between:
     - Assignment: `symbol = value` ✓
     - Field access: `obj->symbol` ✗
     - Comparison: `symbol == value` ✗
     - Usage: `func(symbol)` ✗

2. **`lsp_references_with_filter()`**
   - Fetches LSP references for symbol under cursor
   - Pre-computes assignment status for each reference
   - Opens Snacks picker with filtering support
   - Type `=` in picker to show only assignments

### Commands

- `:LspReferencesFilter` - Open filtered references picker
- `:TestIsAssignment <file> <line> <symbol>` - Test assignment detection

### Keybinding

- `glR` - Automatically uses filtered picker when Snacks is available

## Usage

1. Place cursor on a symbol
2. Press `glR` or run `:LspReferencesFilter`
3. In the picker, type `=` to filter for assignments only
4. All references where the symbol is assigned will be shown

## Testing

Verified with:
- `subquery = parent_join->query_expression()->item;` → Assignment ✓
- `if (subquery == nullptr)` → Not assignment ✓

## Limitations

- Currently only supports C/C++ (treesitter cpp parser)
- Requires LSP server to be attached
- Requires treesitter parser for the language
