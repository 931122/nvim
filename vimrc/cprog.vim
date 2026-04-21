func! TemplateManagerGetMaintainerName() abort
	if !exists('g:template_manager_maintainer_name')
		let g:template_manager_maintainer_name = trim(system('git config user.name'))
	endif
	return (g:template_manager_maintainer_name !=# '') ? g:template_manager_maintainer_name : $USER
endfunc

func! TemplateManagerGetMaintainerEmail() abort
	if !exists('g:template_manager_maintainer_email')
		let g:template_manager_maintainer_email = trim(system('git config user.email'))
	endif
	return (g:template_manager_maintainer_email !=# '') ? g:template_manager_maintainer_email : 'unknown@example.com'
endfunc

func s:GetMaintainerName() abort
	return TemplateManagerGetMaintainerName()
endfunc

func s:GetMaintainerEmail() abort
	return TemplateManagerGetMaintainerEmail()
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

augroup cprog
	" Set some sensible defaults for editing C-files
	" Remove all cprog autocommands
	au!

	" When starting to edit a file:
	"   For *.c and *.h files set formatting of comments and set C-indenting on.
	"   For other files switch it off.
	"   Don't change the order, it's important that the line with * comes first.
	"autocmd BufRead *.cpp,*.c,*.h 1;/^{
	autocmd FileType c,cpp call <SID>SetupCprogBuffer()
	" autocmd BufLeave *.cpp,*.c,*.h unabbr _dtrace
augroup END

inoremap <silent> <F3> <C-R>=<SID>MaintainerStampComment()<CR><CR>
command! Dtr call <SID>RemoveDtrace()
command! DtraceClean call <SID>RemoveDtrace()
command! Pf call <SID>CPrintf()
command! Ma call <SID>MainAdd()
command! -nargs=1 Ko call <SID>KoAdd(<q-args>)
command! Dc call <SID>DeleteConditionalBlock()
command! Line call <SID>UnderlineCursorLine()
command! Rc call <SID>ReverseConditionalBlock()
command! -range Co call <SID>WrapWithMacroComment(<line1>, <line2>)
command! CC call <SID>ToggleDefineUndef()
command! PT call <SID>PTrace()

func s:CPrintf() abort
	let l:user = s:GetMaintainerName()
	if &filetype ==# 'cpp'
		call setline('.', 'std::cout << "===========[' . l:user . ' :" << __FILE__ << ":" << __LINE__ << "]" << std::endl;')
	elseif &filetype ==# 'c'
		call setline('.', 'printf("===========[' . l:user . ' :%s:%d]\\n", __FILE__ , __LINE__  );')
	endif
	normal! ==
endfunc

func s:MainAdd() abort
	let l:line = line('.')
	call append(l:line, [
				\ '#include <stdio.h>',
				\ '#include <stdlib.h>',
				\ '#include <string.h>',
				\ '#include <unistd.h>',
				\ 'int main(int argc, char *argv[])',
				\ '{',
				\ '',
				\ "\treturn 0;",
				\ '}',
				\ ])
	call cursor(l:line + 7, 1)
endfunc

func s:KoAdd(name, ...) abort
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
				\"MODULE_AUTHOR(\"" . s:GetMaintainerName() . "\");\r" .
				\"MODULE_DESCRIPTION(\"".a:name." driver\");\r" .
				\"MODULE_LICENSE(\"GPL\");\r"
endfunc

func s:DeleteConditionalBlock() abort
	normal! 1l
	let l:start = searchpair('^\s*#\s*if\s\+\d\+', '', '^\s*#\s*endif', 'Wb')
	if l:start < 1
		return
	endif
	normal! ]#
	if getline('.') =~# '^\s*#\s*else'
		return
	endif
	execute 'normal! dd' . l:start . 'Gdd'
endfunc

func s:UnderlineCursorLine() abort
	highlight CursorLine gui=underline cterm=underline
endfunc

func s:ReverseConditionalBlock() abort
	normal! 1l
	if searchpair('^\s*#\s*if\s\+\d\+', '', '^\s*#\s*endif', 'Wb') < 1
		return
	endif
	execute '.s#\d\+#\=submatch(0)==0 ? 1 : 0#'
endfunc

func s:WrapWithMacroComment(l1, l2) abort
	let l:comment_start = '#if 0     /* by ' . s:GetMaintainerName() . ' on ' . strftime('%Y-%m-%d') . ' */'
	let l:comment_end = '#endif'

	execute a:l2 + 1 . 's%^%' . l:comment_end . '\\r%'
	execute a:l1 . 's%^%' . l:comment_start . '\\r%'
endfunc

func s:ToggleDefineUndef() abort
	let l:line_nr = line('.')
	let l:line_text = getline('.')
	if l:line_text =~# '^\s*#\s*define'
		call setline(l:line_nr, substitute(l:line_text, 'define', 'undef', ''))
		execute l:line_nr
	elseif l:line_text =~# '^\s*#\s*undef'
		call setline(l:line_nr, substitute(l:line_text, 'undef', 'define', ''))
		execute l:line_nr
	endif
endfunc

func s:PTrace() abort
endfunc
