; Tree-sitter highlights for GDB backtrace / thread dump files.

; The dump-tool line-number prefix ("38: ")
(line_prefix (prefix) @comment)

; Thread section header — make it stand out (it's the anchor for context)
(thread_header) @markup.heading
(thread_header
  "Thread " @keyword)
(thread_header
  thread_id: (thread_id) @number)
(thread_header
  details: (thread_details) @string)

; Stack frames
(frame
  number: (frame_number) @label)
(frame
  body: (frame_body) @none)

; Registers
(register_line
  register: (register_name) @variable.builtin)
(register_line
  value: (hex_value) @number)
(register_line
  (register_extra) @comment)

; Local variable / struct dumps (indented)
(var_binding
  name: (var_name) @variable.member)
(var_binding
  value: (var_value) @none)
(storage_class) @keyword
(members_header) @comment
(variable_content) @none

; GDB info lines
(no_symbols) @comment
(no_locals) @comment
(signal_handler) @keyword.exception

; Redacted content markers
(redacted_content) @comment.error

; Shared library table
(shared_library
  from: (hex_value) @number)
(shared_library
  to: (hex_value) @number)
(shared_library
  (shared_library_info) @string.special.path)

; Catch-all
(other_content) @none
