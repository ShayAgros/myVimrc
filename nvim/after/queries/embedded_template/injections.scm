;; extends

; Inject HTML into the template content
((content) @injection.content
 (#not-has-ancestor? @injection.content "code")
 (#set! injection.combined)
 (#set! injection.language "html"))

; Inject JavaScript into EJS code blocks
((code) @injection.content
 (#set! injection.language "javascript"))
