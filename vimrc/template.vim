let s:template_manager_dir = expand('<sfile>:p:h')

func s:GetTemplateMaintainerName() abort
	return TemplateManagerGetMaintainerName()
endfunc

func s:GetTemplateMaintainerEmail() abort
	return TemplateManagerGetMaintainerEmail()
endfunc

func s:GetTemplateRootDir() abort
	let l:override = get(g:, 'template_manager_dir', '')
	if l:override !=# ''
		return expand(l:override)
	endif
	return s:template_manager_dir . '/templates'
endfunc

func s:GetTemplateStateFile() abort
	let l:override = get(g:, 'template_manager_state_file', '')
	if l:override !=# ''
		return expand(l:override)
	endif
	if exists('*stdpath')
		return stdpath('state') . '/template_mode.txt'
	endif
	return expand('~/.local/state/nvim/template_mode.txt')
endfunc

func s:GetTemplateDateEn() abort
	let l:weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
	return l:weekdays[str2nr(strftime('%w'))] . strftime(' %Y-%m-%d %H:%M:%S')
endfunc

func s:ShowTemplateMessage(msg) abort
	echohl ModeMsg
	echo a:msg
	echohl None
endfunc

func s:ExtractTemplateModeName(stem) abort
	let l:name = a:stem
	for l:suffix in ['source', 'header', 'script', 'c', 'cc', 'cpp', 'cxx', 'h', 'hh', 'hpp', 'hxx', 'py', 'sh']
		if l:name =~# '\.' . l:suffix . '$'
			return substitute(l:name, '\.' . l:suffix . '$', '', '')
		endif
	endfor
	return l:name
endfunc

func s:ClearTemplateModeCache() abort
	unlet! s:template_mode_cache
endfunc

func s:GetTemplateModeNames() abort
	let l:root = s:GetTemplateRootDir()
	let l:names = []
	let l:files = isdirectory(l:root) ? sort(globpath(l:root, '*', 0, 1)) : []
	let l:cache_key = l:root . "\n" . join(l:files, "\n")

	if exists('s:template_mode_cache') && get(s:template_mode_cache, 'key', '') ==# l:cache_key
		return copy(get(s:template_mode_cache, 'names', ['builtin']))
	endif

	if !isdirectory(l:root)
		let s:template_mode_cache = { 'key': l:cache_key, 'names': ['builtin'] }
		return ['builtin']
	endif

	for l:file in l:files
		if !filereadable(l:file)
			continue
		endif
		let l:name = fnamemodify(l:file, ':t')
		if l:name =~? '^README\.'
			continue
		endif
		if l:name !~# '\.\%(tpl\|tmpl\|template\)$'
			continue
		endif
		let l:stem = substitute(l:name, '\.\%(tpl\|tmpl\|template\)$', '', '')
		let l:mode = s:ExtractTemplateModeName(l:stem)
		if l:mode !=# '' && index(l:names, l:mode) < 0
			call add(l:names, l:mode)
		endif
	endfor

	call sort(l:names)
	let s:template_mode_cache = { 'key': l:cache_key, 'names': ['builtin'] + l:names }
	return copy(s:template_mode_cache.names)
endfunc

func s:LoadTemplateMode() abort
	let l:modes = s:GetTemplateModeNames()
	let l:file = s:GetTemplateStateFile()

	if filereadable(l:file)
		let l:mode = trim(get(readfile(l:file, '', 1), 0, ''))
		if index(l:modes, l:mode) >= 0
			return l:mode
		endif
	endif
	return 'builtin'
endfunc

func s:GetCurrentTemplateMode() abort
	if !exists('s:current_template_mode') || s:current_template_mode ==# ''
		let s:current_template_mode = s:LoadTemplateMode()
	endif
	return s:current_template_mode
endfunc

func s:SaveTemplateMode(mode) abort
	let l:file = s:GetTemplateStateFile()
	try
		call mkdir(fnamemodify(l:file, ':h'), 'p')
		call writefile([a:mode], l:file)
	catch
		echohl WarningMsg
		echom 'failed to save template mode: ' . l:file
		echohl None
	endtry
endfunc

func s:GetCurrentBufferTemplateType() abort
	if &buftype !=# ''
		return ''
	endif
	let l:ext = tolower(expand('%:e'))
	if l:ext ==# 'c'
		return 'c'
	elseif index(['cc', 'cpp', 'cxx', 'h', 'hh', 'hpp', 'hxx'], l:ext) >= 0
		return 'cpp'
	elseif l:ext ==# 'sh'
		return 'sh'
	elseif l:ext ==# 'py'
		return 'py'
	endif
	return ''
endfunc

func s:IsCurrentBufferBlank() abort
	for l:line in getline(1, '$')
		if l:line !=# ''
			return 0
		endif
	endfor
	return 1
endfunc

func s:CurrentBufferMatchesLastTemplate(type) abort
	if !exists('b:template_manager_state')
		return 0
	endif
	if !get(b:template_manager_state, 'generated', 0)
		return 0
	endif
	if get(b:template_manager_state, 'type', '') !=# a:type
		return 0
	endif
	return string(get(b:template_manager_state, 'lines', [])) ==# string(getline(1, '$'))
endfunc

func s:RenderCurrentModeTemplate(type, filename) abort
	let l:mode = s:GetCurrentTemplateMode()
	let l:template = {}

	if l:mode !=# 'builtin'
		let l:template = s:RenderExternalTemplate(l:mode, a:type, a:filename)
	endif
	if empty(l:template)
		let l:template = s:RenderBuiltinTemplate(a:type, a:filename)
	endif
	return l:template
endfunc

func s:ApplyTemplateToCurrentBuffer(type) abort
	let l:filename = expand('%:t')
	let l:template = s:RenderCurrentModeTemplate(a:type, l:filename)

	call setline(1, l:template.lines)
	if line('$') > len(l:template.lines)
		execute (len(l:template.lines) + 1) . ',$delete _'
	endif
	call cursor(l:template.cursor[0], l:template.cursor[1])
	let b:template_manager_state = {
				\ 'type': a:type,
				\ 'mode': s:GetCurrentTemplateMode(),
				\ 'generated': 1,
				\ 'lines': copy(l:template.lines),
				\ }
endfunc

func s:RefreshCurrentBufferTemplate(force) abort
	let l:type = s:GetCurrentBufferTemplateType()
	if l:type ==# '' || !&modifiable
		return ''
	endif
	if !a:force && !s:IsCurrentBufferBlank() && !s:CurrentBufferMatchesLastTemplate(l:type)
		return 'current file kept'
	endif
	call s:ApplyTemplateToCurrentBuffer(l:type)
	return 'current file updated'
endfunc

func s:SetTemplateMode(mode) abort
	let l:modes = s:GetTemplateModeNames()
	if index(l:modes, a:mode) < 0
		echohl WarningMsg
		echo 'template mode not found: ' . a:mode
		echohl None
		return
	endif
	let s:current_template_mode = a:mode
	call s:SaveTemplateMode(a:mode)
	let l:refresh = s:RefreshCurrentBufferTemplate(0)
	if l:refresh !=# ''
		call s:ShowTemplateMessage('template mode: ' . a:mode . ' (' . l:refresh . ')')
	else
		call s:ShowTemplateMessage('template mode: ' . a:mode)
	endif
endfunc

func s:CycleTemplateMode() abort
	let l:modes = s:GetTemplateModeNames()
	if len(l:modes) <= 1
		call s:ShowTemplateMessage('template mode: builtin (no external templates)')
		return
	endif
	let l:current = s:GetCurrentTemplateMode()
	let l:index = index(l:modes, l:current)
	if l:index < 0
		let l:index = 0
	endif
	call s:SetTemplateMode(l:modes[(l:index + 1) % len(l:modes)])
endfunc

func s:TemplateProfileCommand(...) abort
	if a:0 == 0 || a:1 ==# ''
		call s:ShowTemplateMessage('template mode: ' . s:GetCurrentTemplateMode())
		return
	endif
	call s:SetTemplateMode(a:1)
endfunc

func s:TemplateProfileList() abort
	call s:ShowTemplateMessage('template modes: ' . join(s:GetTemplateModeNames(), ', '))
endfunc

func s:TemplateProfileReload() abort
	call s:ClearTemplateModeCache()
	let l:modes = s:GetTemplateModeNames()
	if index(l:modes, s:GetCurrentTemplateMode()) < 0
		let s:current_template_mode = 'builtin'
		call s:SaveTemplateMode('builtin')
	endif
	call s:ShowTemplateMessage('template modes: ' . join(l:modes, ', '))
endfunc

func s:GetTemplateKind(type, filename) abort
	if a:filename =~# '\.\%(h\|hpp\|hh\|hxx\)$'
		return 'header'
	elseif a:type ==# 'sh' || a:type ==# 'py'
		return 'script'
	endif
	return 'source'
endfunc

func s:GetTemplateCommentStyle(type, filename) abort
	if s:GetTemplateKind(a:type, a:filename) ==# 'script'
		return {
					\ 'start': '####################################################################',
					\ 'line': '#',
					\ 'end': '####################################################################',
					\ }
	endif
	return {
				\ 'start': '/********************************************************************',
				\ 'line': ' *',
				\ 'end': ' ********************************************************************/',
				\ }
endfunc

func s:MakeHeaderGuard(filename) abort
	let l:guard = toupper(substitute(a:filename, '[^A-Za-z0-9]', '_', 'g'))
	let l:guard = substitute(l:guard, '_\+', '_', 'g')
	return '__' . trim(l:guard, '_') . '__'
endfunc

func s:GetTemplatePlaceholderValues(type, filename, mode) abort
	let l:basename = fnamemodify(a:filename, ':r')
	let l:ext = tolower(fnamemodify(a:filename, ':e'))
	let l:kind = s:GetTemplateKind(a:type, a:filename)
	let l:style = s:GetTemplateCommentStyle(a:type, a:filename)

	return {
				\ 'FILENAME': a:filename,
				\ 'BASENAME': l:basename,
				\ 'EXT': l:ext,
				\ 'KIND': l:kind,
				\ 'MODE': a:mode,
				\ 'TEMPLATE': a:mode,
				\ 'AUTHOR': s:GetTemplateMaintainerName(),
				\ 'EMAIL': s:GetTemplateMaintainerEmail(),
				\ 'DATE': strftime('%Y-%m-%d'),
				\ 'TIME': strftime('%H:%M:%S'),
				\ 'DATETIME': strftime('%Y-%m-%d %H:%M:%S'),
				\ 'DATE_EN': s:GetTemplateDateEn(),
				\ 'YEAR': strftime('%Y'),
				\ 'HEADER_GUARD': s:MakeHeaderGuard(a:filename),
				\ 'COMMENT_LINE': l:style.line,
				\ }
endfunc

func s:GetTemplateBlockValues(type, filename) abort
	let l:blocks = {}
	let l:kind = s:GetTemplateKind(a:type, a:filename)
	let l:style = s:GetTemplateCommentStyle(a:type, a:filename)
	let l:guard = s:MakeHeaderGuard(a:filename)

	let l:blocks['COMMENT_HEADER_START'] = [l:style.start]
	let l:blocks['COMMENT_HEADER_END'] = [l:style.end]

	if a:type ==# 'sh'
		let l:blocks['FILE_BEFORE_HEADER'] = ['#!/usr/bin/env bash']
	elseif a:type ==# 'py'
		let l:blocks['FILE_BEFORE_HEADER'] = ['#!/usr/bin/env python', '# coding=utf-8']
	else
		let l:blocks['FILE_BEFORE_HEADER'] = []
	endif

	if l:kind ==# 'header'
		let l:blocks['FILE_AFTER_HEADER'] = ['#ifndef  ' . l:guard, '#define  ' . l:guard, '']
		if a:filename =~# '\.h$'
			call extend(l:blocks['FILE_AFTER_HEADER'], ['#ifdef __cplusplus', 'extern "C" {', '#endif', ''])
			let l:blocks['FILE_FOOTER'] = ['', '#ifdef __cplusplus', '}', '#endif', '', '#endif/* ' . l:guard . ' */']
		else
			let l:blocks['FILE_FOOTER'] = ['', '#endif/* ' . l:guard . ' */']
		endif
	elseif a:type ==# 'c'
		let l:blocks['FILE_AFTER_HEADER'] = ['#ifdef __cplusplus', 'extern "C" {', '#endif', '']
		let l:blocks['FILE_FOOTER'] = ['', '#ifdef __cplusplus', '}', '#endif']
	else
		let l:blocks['FILE_AFTER_HEADER'] = []
		let l:blocks['FILE_FOOTER'] = []
	endif

	return l:blocks
endfunc

func s:ReplaceTemplateTokens(line, values) abort
	let l:line = a:line
	for l:key in keys(a:values)
		let l:token = '{{' . l:key . '}}'
		let l:line = substitute(l:line, '\V' . escape(l:token, '\'), escape(a:values[l:key], '\&'), 'g')
	endfor
	return l:line
endfunc

func s:ExpandTemplateLines(lines, values, blocks) abort
	let l:out = []
	for l:line in a:lines
		let l:expanded = 0
		for l:key in keys(a:blocks)
			if l:line ==# '{{' . l:key . '}}'
				call extend(l:out, a:blocks[l:key])
				let l:expanded = 1
				break
			endif
		endfor
		if !l:expanded
			call add(l:out, s:ReplaceTemplateTokens(l:line, a:values))
		endif
	endfor
	return l:out
endfunc

func s:ExtractTemplateCursor(lines) abort
	for l:index in range(len(a:lines))
		let l:col = match(a:lines[l:index], '{{CURSOR}}')
		if l:col >= 0
			let a:lines[l:index] = substitute(a:lines[l:index], '{{CURSOR}}', '', '')
			return [l:index + 1, l:col + 1]
		endif
	endfor
	return [0, 0]
endfunc

func s:AddTemplateCandidates(list, seen, base) abort
	if a:base ==# ''
		return
	endif
	for l:suffix in ['.tpl', '.tmpl', '.template']
		let l:path = a:base . l:suffix
		if !has_key(a:seen, l:path)
			let a:seen[l:path] = 1
			call add(a:list, l:path)
		endif
	endfor
endfunc

func s:FindTemplateFile(mode, type, filename) abort
	let l:root = s:GetTemplateRootDir()
	let l:kind = s:GetTemplateKind(a:type, a:filename)
	let l:ext = tolower(fnamemodify(a:filename, ':e'))
	let l:candidates = []
	let l:seen = {}

	if a:mode ==# 'builtin' || !isdirectory(l:root)
		return ''
	endif

	if l:ext !=# ''
		call s:AddTemplateCandidates(l:candidates, l:seen, l:root . '/' . a:mode . '.' . l:ext)
	endif
	call s:AddTemplateCandidates(l:candidates, l:seen, l:root . '/' . a:mode . '.' . l:kind)
	call s:AddTemplateCandidates(l:candidates, l:seen, l:root . '/' . a:mode)

	for l:candidate in l:candidates
		if filereadable(l:candidate)
			return l:candidate
		endif
	endfor
	return ''
endfunc

func s:RenderExternalTemplate(mode, type, filename) abort
	let l:file = s:FindTemplateFile(a:mode, a:type, a:filename)
	if l:file ==# ''
		return {}
	endif

	let l:lines = readfile(l:file)
	if empty(l:lines)
		let l:lines = ['']
	endif

	let l:values = s:GetTemplatePlaceholderValues(a:type, a:filename, a:mode)
	let l:blocks = s:GetTemplateBlockValues(a:type, a:filename)
	let l:lines = s:ExpandTemplateLines(l:lines, l:values, l:blocks)
	let l:cursor = s:ExtractTemplateCursor(l:lines)

	return {
				\ 'file': l:file,
				\ 'lines': l:lines,
				\ 'cursor': l:cursor,
				\ }
endfunc

func s:GetBuiltinTemplateStyle(type) abort
	if a:type ==# 'sh'
		return {
					\ 'prefix_lines': ['#!/usr/bin/env bash'],
					\ 'banner_open': '#********************************************************************',
					\ 'comment': '#',
					\ 'banner_close': '#*******************************************************************/',
					\ 'footer_open': '#',
					\ 'footer_close': '#',
					\ }
	elseif a:type ==# 'py'
		return {
					\ 'prefix_lines': ['#!/usr/bin/env python', '# coding=utf-8'],
					\ 'banner_open': '#********************************************************************',
					\ 'comment': '#',
					\ 'banner_close': '#*******************************************************************/',
					\ 'footer_open': '#',
					\ 'footer_close': '#',
					\ }
	endif
	return {
				\ 'prefix_lines': [],
				\ 'banner_open': '/********************************************************************',
				\ 'comment': '*',
				\ 'banner_close': '********************************************************************/',
				\ 'footer_open': '/*',
				\ 'footer_close': '*/',
				\ }
endfunc

func s:GetBuiltinTemplateBounds(type, filename) abort
	if a:filename =~# '\.\%(h\|hpp\)$'
		let l:defn = s:MakeHeaderGuard(a:filename)
		return {
					\ 'top': ['#ifndef  ' . l:defn, '#define  ' . l:defn],
					\ 'bottom': ['#endif/* ' . l:defn . ' */'],
					\ }
	elseif a:type ==# 'c'
		return {
					\ 'top': ['#ifdef __cplusplus', 'extern "C" {', '#endif'],
					\ 'bottom': ['#ifdef __cplusplus', '}', '#endif'],
					\ }
	endif
	return { 'top': [], 'bottom': [] }
endfunc

func s:BuildBuiltinTemplateHeader(type, filename) abort
	let l:style = s:GetBuiltinTemplateStyle(a:type)
	let l:bounds = s:GetBuiltinTemplateBounds(a:type, a:filename)
	let l:rspace = '                                      '
	let l:maintainer_line = ' Maintainer: ' . s:GetTemplateMaintainerName() . '  <' . s:GetTemplateMaintainerEmail() . '>'
	let l:maintainer_padding = strpart(l:rspace, 0, max([0, 66 - len(l:maintainer_line)]))
	let l:file_padding = strpart(l:rspace, 0, max([0, 31 - len(a:filename)]))
	let l:lines = copy(l:style.prefix_lines)

	call extend(l:lines, [
				\ l:style.banner_open,
				\ l:style.comment . ' file: ' . a:filename . l:file_padding . 'date: ' . s:GetTemplateDateEn() . '*',
				\ l:style.comment . '                                                                   *',
				\ l:style.comment . ' Description:                                                      *',
				\ l:style.comment . '                                                                   *',
				\ l:style.comment . '                                                                   *',
				\ l:style.comment . l:maintainer_line . l:maintainer_padding . ' *',
				\ l:style.comment . '                                                                   *',
				\ l:style.comment . ' This file is free software;                                       *',
				\ l:style.comment . '   you are free to modify and/or redistribute it                   *',
				\ l:style.comment . '   under the terms of the GNU General Public Licence (GPL).        *',
				\ l:style.comment . '                                                                   *',
				\ l:style.comment . ' Last modified:                                                    *',
				\ l:style.comment . '                                                                   *',
				\ l:style.comment . ' No warranty, no liability, use this at your own risk!             *',
				\ l:style.banner_close,
				\ ])
	call extend(l:lines, l:bounds.top)
	return l:lines
endfunc

func s:BuildBuiltinTemplateFooter(type, filename) abort
	let l:style = s:GetBuiltinTemplateStyle(a:type)
	let l:bounds = s:GetBuiltinTemplateBounds(a:type, a:filename)
	let l:tail = repeat('*', max([0, 24 - (strlen(a:filename) / 2)]))
	let l:lines = copy(l:bounds.bottom)

	call add(l:lines, l:style.footer_open . l:tail . ' end of file: ' . a:filename . ' ' . l:tail . l:style.footer_close)
	return l:lines
endfunc

func s:RenderBuiltinTemplate(type, filename) abort
	let l:lines = s:BuildBuiltinTemplateHeader(a:type, a:filename) + ['', '', ''] + s:BuildBuiltinTemplateFooter(a:type, a:filename)
	return {
				\ 'lines': l:lines,
				\ 'cursor': [min([21, len(l:lines)]), 1],
				\ }
endfunc

func s:InsertTemplate(type) abort
	call s:ApplyTemplateToCurrentBuffer(a:type)
endfunc

func s:TemplateApplyCommand() abort
	let l:refresh = s:RefreshCurrentBufferTemplate(1)
	if l:refresh ==# ''
		echohl WarningMsg
		echo 'template apply skipped: unsupported filetype'
		echohl None
		return
	endif
	call s:ShowTemplateMessage('template mode: ' . s:GetCurrentTemplateMode() . ' (' . l:refresh . ')')
endfunc

func s:BindTemplateKeymaps() abort
	nnoremap <silent> <F9> :TemplateProfileNext<CR>
	inoremap <silent> <F9> <C-o>:TemplateProfileNext<CR>
endfunc

augroup template_manager
	au!
	autocmd BufNewFile *.cc,*.cpp,*.cxx,*.h,*.hpp call <SID>InsertTemplate('cpp')
	autocmd BufNewFile *.sh call <SID>InsertTemplate('sh')
	autocmd BufNewFile *.c call <SID>InsertTemplate('c')
	autocmd BufNewFile *.py call <SID>InsertTemplate('py')
augroup END

call s:BindTemplateKeymaps()
command! -nargs=? TemplateProfile call <SID>TemplateProfileCommand(<f-args>)
command! TemplateProfileNext call <SID>CycleTemplateMode()
command! TemplateProfileList call <SID>TemplateProfileList()
command! TemplateProfileReload call <SID>TemplateProfileReload()
command! TemplateApply call <SID>TemplateApplyCommand()
