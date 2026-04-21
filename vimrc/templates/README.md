# Templates

Put your template files directly in this directory.

The switch list is built from filenames here, plus one builtin mode:

- `builtin`
- `xxxx`

Example file names:

- `sync_clock.tpl`
- `module.tpl`
- `module.header.tpl`
- `module.script.tpl`
- `module.c.tpl`
- `module.py.tpl`

Search order for the current mode:

1. `<name>.<ext>.tpl`
2. `<name>.<kind>.tpl`
3. `<name>.tpl`

Kinds:

- `source`
- `header`
- `script`

Supported placeholders:

- `{{FILENAME}}`
- `{{BASENAME}}`
- `{{EXT}}`
- `{{KIND}}`
- `{{MODE}}`
- `{{TEMPLATE}}`
- `{{AUTHOR}}`
- `{{EMAIL}}`
- `{{DATE}}`
- `{{TIME}}`
- `{{DATETIME}}`
- `{{DATE_EN}}`
- `{{YEAR}}`
- `{{HEADER_GUARD}}`
- `{{COMMENT_LINE}}`
- `{{CURSOR}}`

Supported block placeholders:

- `{{FILE_BEFORE_HEADER}}`
- `{{COMMENT_HEADER_START}}`
- `{{COMMENT_HEADER_END}}`
- `{{FILE_AFTER_HEADER}}`
- `{{FILE_FOOTER}}`

`{{CURSOR}}` will be removed after expansion and the cursor will jump there.

Example generic template:

```text
{{FILE_BEFORE_HEADER}}
{{COMMENT_HEADER_START}}
{{COMMENT_LINE}} file: {{FILENAME}}
{{COMMENT_LINE}} date: {{DATE_EN}}
{{COMMENT_LINE}} author: {{AUTHOR}} <{{EMAIL}}>
{{COMMENT_LINE}} template: {{MODE}}
{{COMMENT_LINE}} brief:
{{COMMENT_HEADER_END}}

{{FILE_AFTER_HEADER}}
{{CURSOR}}
{{FILE_FOOTER}}
```
