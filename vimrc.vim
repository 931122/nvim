let s:git_username = trim(system('git config user.name'))
let s:git_email = trim(system('git config user.email'))

func s:GetMaintainerName() abort
	return (s:git_username != "") ? s:git_username : $USER
endfunc

func s:GetMaintainerEmail() abort
	return (s:git_email != "") ? s:git_email : 'unknown@example.com'
endfunc

func s:EnglishHeaderDate() abort
	let l:weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
	return 'date: ' . l:weekdays[str2nr(strftime('%w'))] . strftime(' %Y-%m-%d %H:%M:%S')
endfunc

func s:MaintainerStampComment() abort
	return '/* ' . s:GetMaintainerEmail() . ' ' . strftime('%Y-%m-%d %H:%M') . ' */'
endfunc

func s:DtraceAbbr() abort
	return join([
				\ '#define dtrace  do { fprintf(stdout, "\033[36mTRACE" \',
				\ ' "\033[1;34m==>\033[33m%16s" \',
				\ ' "\033[36m: \033[32m%4d\033[36m: " \',
				\ ' "\033[35m%-24s \033[34m" \',
				\ ' "[\033[0;37m%s\033[1;34m," \',
				\ ' " \033[0;36m%s\033[1;34m]" \',
				\ ' "\033[0m\n", __FILE__, __LINE__, \',
				\ ' __FUNCTION__ /* __func__ */, \',
				\ ' __TIME__, __DATE__); \',
				\ '} while (0)          /* defined by ' . s:GetMaintainerName() . '*/',
				\ ], "\<CR>")
endfunc

func s:CprogSpace() abort
	let l:prefix = getline('.')[0 : col('.') - 2]
	let l:word = matchstr(l:prefix, '\k*$')
	if l:word ==# '_dtrace'
		return repeat("\<BS>", strlen(l:word)) . s:DtraceAbbr()
	endif
	return ' '
endfunc

func s:SetupCprogBuffer() abort
	silent! iunmap <buffer> _dtrace
	silent! iunabbrev <buffer> _dtrace
	silent! iunmap <buffer> <Space>
	inoremap <buffer> <expr> <Space> <SID>CprogSpace()
endfunc

func s:RemoveDtrace() abort
	let l:view = winsaveview()
	let l:macro_removed = 0
	let l:call_removed = 0

	let l:macro_start = search('^\s*#define\s\+dtrace\>', 'nw')
	if l:macro_start > 0
		call cursor(l:macro_start, 1)
		let l:macro_end = search('^\s*}\s*while\s*(0).*defined by', 'nW')
		if l:macro_end >= l:macro_start
			execute l:macro_start . ',' . l:macro_end . 'delete _'
			let l:macro_removed = 1
		endif
	endif

	let l:call_removed = len(filter(getline(1, '$'), 'v:val =~# ''^\s*dtrace\s*;\?\s*$'''))
	if l:call_removed > 0
		silent! keeppatterns g/^\s*dtrace\s*;\?\s*$/delete _
	endif

	call winrestview(l:view)
	echo 'dtrace cleaned: macro=' . l:macro_removed . ', calls=' . l:call_removed
endfunc

func s:GetTemplateStyle(type) abort
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

func s:MakeHeaderGuard(filename) abort
	let l:guard = toupper(substitute(a:filename, '[^A-Za-z0-9]', '_', 'g'))
	let l:guard = substitute(l:guard, '_\+', '_', 'g')
	return '__' . trim(l:guard, '_') . '__'
endfunc

func s:GetTemplateBounds(type, filename) abort
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

func s:BuildTemplateHeader(type, filename) abort
	let l:style = s:GetTemplateStyle(a:type)
	let l:bounds = s:GetTemplateBounds(a:type, a:filename)
	let l:rspace = "                                      "
	let l:maintainer_line = " Maintainer: " . s:GetMaintainerName() . "  <" . s:GetMaintainerEmail() . ">"
	let l:maintainer_padding = strpart(l:rspace, 0, max([0, 66 - len(l:maintainer_line)]))
	let l:file_padding = strpart(l:rspace, 0, max([0, 34 - len(a:filename) - len($USER)]))
	let l:lines = copy(l:style.prefix_lines)

	call extend(l:lines, [
				\ l:style.banner_open,
				\ l:style.comment . " file: " . a:filename . l:file_padding . s:EnglishHeaderDate() . "*",
				\ l:style.comment . "                                                                   *",
				\ l:style.comment . " Description:                                                      *",
				\ l:style.comment . "                                                                   *",
				\ l:style.comment . "                                                                   *",
				\ l:style.comment . l:maintainer_line . l:maintainer_padding . " *",
				\ l:style.comment . "                                                                   *",
				\ l:style.comment . " This file is free software;                                       *",
				\ l:style.comment . "   you are free to modify and/or redistribute it                   *",
				\ l:style.comment . "   under the terms of the GNU General Public Licence (GPL).        *",
				\ l:style.comment . "                                                                   *",
				\ l:style.comment . " Last modified:                                                    *",
				\ l:style.comment . "                                                                   *",
				\ l:style.comment . " No warranty, no liability, use this at your own risk!             *",
				\ l:style.banner_close,
				\ ])
	call extend(l:lines, l:bounds.top)
	return l:lines
endfunc

func s:BuildTemplateFooter(type, filename) abort
	let l:style = s:GetTemplateStyle(a:type)
	let l:bounds = s:GetTemplateBounds(a:type, a:filename)
	let l:tail = repeat('*', max([0, 24 - (strlen(a:filename) / 2)]))
	let l:lines = copy(l:bounds.bottom)

	call add(l:lines, l:style.footer_open . l:tail . " End Of File: " . a:filename . " " . l:tail . l:style.footer_close)
	return l:lines
endfunc

func s:InsertTemplate(type) abort
	let l:filename = expand('%:t')
	let l:template = s:BuildTemplateHeader(a:type, l:filename) + ['', '', ''] + s:BuildTemplateFooter(a:type, l:filename)

	call setline(1, l:template)
	if line('$') > len(l:template)
		execute (len(l:template) + 1) . ',$delete _'
	endif
	call cursor(min([21, line('$')]), 1)
endfunc

augroup cprog
	" Set some sensible defaults for editing C-files
	" Remove all cprog autocommands
	au!

	" When starting to edit a file:
	"   For *.c and *.h files set formatting of comments and set C-indenting on.
	"   For other files switch it off.
	"   Don't change the order, it's important that the line with * comes first.
	"autocmd BufRead *.cpp,*.c,*.h 1;/^{
	autocmd BufNewFile *.cc,*.cpp,*.cxx,*.h,*.hpp  call <SID>InsertTemplate('cpp')
	autocmd BufNewFile *.sh  call <SID>InsertTemplate('sh')
	autocmd BufNewFile *.c  call <SID>InsertTemplate('c')
	autocmd BufNewFile *.py  call <SID>InsertTemplate('py')

		autocmd FileType c,cpp call s:SetupCprogBuffer()
	" autocmd BufLeave *.cpp,*.c,*.h unabbr _dtrace
	imap <F3> <C-R>=<SID>MaintainerStampComment()<CR><CR>
	command! Dtr call s:RemoveDtrace()
	command! DtraceClean call s:RemoveDtrace()

	command Pf : call C_printf()
	func C_printf() " add main info
		let l=line(".")
		let l:user = s:GetMaintainerName()
		if &filetype == 'cpp'
			call setline(line("."), 'std::cout << "===========[' . l:user . ' :" << __FILE__ << ":" << __LINE__ << "]" << std::endl;')
		elseif &filetype == 'c'
			call setline(line("."), 'printf("===========[' . l:user . ' :%s:%d]\\n", __FILE__ , __LINE__  );')
		endif
		exec "normal =="
	endfunc

	command Ma : call Main_Add()
	func Main_Add() " add main info
		let l=line(".")
		call append(l+0, "#include <stdio.h>")
		call append(l+1, "#include <stdlib.h>")
		call append(l+2, "#include <string.h>")
		call append(l+3, "#include <unistd.h>")
		call append(l+4, "int main(int argc, char *argv[])")
		call append(l+5, "{")
		call append(l+6, "")
		call append(l+7, "\treturn 0;")
		call append(l+8, "}")
		exec l+7 .   ""
	endfunc

    command -nargs=1 Ko : call s:Ko_Add(<q-args>)
    func s:Ko_Add(name,...)
        execute ".g/^/s//" .
            \"#include <linux\\/module.h>\r" .
            \"#include <linux\\/init.h>\r" .
            \"\r" .
            \"static int __init ".a:name."_init(void)\r" .
            \"{\r" .
            \"    return 0;\r" .
            \"}\r" .
            \"\r" .
            \"static void __exit ".a:name."_exit(void)\r" .
            \"{\r" .
            \"}\r" .
            \"\r" .
            \"module_init(".a:name."_init);\r" .
            \"module_exit(".a:name."_exit);\r" .
            \"\r" .
            \"MODULE_AUTHOR(\"" .s:GetMaintainerName(). "\");\r" .
            \"MODULE_DESCRIPTION(\"".a:name." driver\");\r" .
            \"MODULE_LICENSE(\"GPL\");\r"
	endfunc

    command Dc : call DCOMM()
    func DCOMM()  " delete the block comment macro lines.
        exec "normal 1l"
        let l1 = searchpair('^\s*#\s*if\s\+\d\+', '', '^\s*#\s*endif', 'Wb')
        if l1 < 1
            return
        endif
        exec "normal ]#"
        if getline(".") =~ '^\s*#\s*else'
            return
        endif
        exec "normal dd" . l1 . "Gdd"
	endfunc

    command Line : call Underline()
    func Underline()  " delete the block comment macro lines.
        hi CursorLine gui=underline cterm=underline "显示下划线
	endfunc

    command Rc :call RCOMM()
    func RCOMM()  " reverse the block comment.
        exec "normal 1l"
        if searchpair('^\s*#\s*if\s\+\d\+', '', '^\s*#\s*endif', 'Wb') < 1
            return
        endif
        exec '.s#\d\+#\=submatch(0)==0 ? 1 : 0#'
	endfunc

	command -range Co : call  COMM(<line1>,<line2>)
	func COMM(l1, l2) " add the MACRO comment around the block of C/Cpp code.
		"exec a:l2+1 . \"s%^%#endif    /* comment by yinxianglu */\<CR>%\"
		"exec a:l2+1 . "s%^%#endif\<CR>%"
		"exec a:l1 .   "s%^%#if 0     /* by .s:GetMaintainerName(). on ".strftime("%Y-%m-%d")." */\<CR>%"
		let comment_start = '#if 0     /* by ' . s:GetMaintainerName() . ' on ' . strftime('%Y-%m-%d') . ' */'
		let comment_end = '#endif'

		" 执行替换命令，将宏注释添加到指定的行
		execute a:l2 + 1 . "s%^%".comment_end."\\r%"
		execute a:l1 . "s%^%".comment_start."\\r%"
	endfunc

    command CC :call CCOMM()
    func CCOMM()  " convert #define <<-->> #undef
        let iLn=line(".")
        let strLn=getline(".")
        if strLn =~ '^\s*#\s*define'
            let strNew=substitute(strLn, "define", "undef", "")
            call setline(iLn, strNew)
            exec iLn
        elseif strLn =~ '^\s*#\s*undef'
            let strNew=substitute(strLn, "undef", "define", "")
            call setline(iLn, strNew)
            exec iLn
        endif
	endfunc

	command PT :call PTRACE()
	func PTRACE() " ptrace func for cursor
    endf

augroup END
