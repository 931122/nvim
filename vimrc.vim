let g:git_username = system('git config user.name')
let g:git_email = system('git config user.email')
let g:git_username = substitute(g:git_username, '\n', '', 'g')
let g:git_email = substitute(g:git_email, '\n', '', 'g')
augroup cprog
	" Set some sensible defaults for editing C-files
	" Remove all cprog autocommands
	au!

	" When starting to edit a file:
	"   For *.c and *.h files set formatting of comments and set C-indenting on.
	"   For other files switch it off.
	"   Don't change the order, it's important that the line with * comes first.
	"autocmd BufRead *.cpp,*.c,*.h 1;/^{
	autocmd BufNewFile *.cc,*.cpp,*.cxx,*.h,*.hpp  call Lcpp()
	autocmd BufNewFile *.sh  call Lsh()
	autocmd BufNewFile *.c  call Lc()
	autocmd BufNewFile *.py  call Lpy()

	autocmd BufEnter *.cpp,*.c,*.h execute 'abbr _dtrace' . 
			  \ ' #define dtrace  do { fprintf(stdout, "\033[36mTRACE"      \<CR>' .
			  \ ' "\033[1;34m==>\033[33m%16s"       \<CR>' .
			  \ ' "\033[36m: \033[32m%4d\033[36m: " \<CR>' .
			  \ ' "\033[35m%-24s \033[34m"          \<CR>' .
			  \ ' "[\033[0;37m%s\033[1;34m,"        \<CR>' .
			  \ ' " \033[0;36m%s\033[1;34m]"        \<CR>' .
			  \ ' "\033[0m\n", __FILE__, __LINE__,  \<CR>' .
			  \ '__FUNCTION__ /* __func__ */,      \<CR>' .
			  \ '__TIME__, __DATE__);              \<CR>' .
			  \ '} while (0)          /* defined by ' . g:git_username . '*/'
	" autocmd BufLeave *.cpp,*.c,*.h unabbr _dtrace
	imap <F3> <C-R>=strftime("/* yinxianglu1993@gmail.com %Y-%m-%d %H:%M */")<CR><CR>

	command Pf : call C_printf()
	func C_printf() " add main info
		let l=line(".")
		if &filetype == 'cpp'
			call setline(line("."), "std::cout << \"===========[yxl :\"<< __FILE__ << \":\"_<< __LINE__ << \"]\" << std::endl;")
		elseif &filetype == 'c'
			call setline(line("."), "printf(\"===========[yxl :%s:%d]\\n\", __FILE__ , __LINE__  );")
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
            \"#include <linux\\/moduleh>\r" .
            \"#include <linux\\/inith>\r" .
            \"\r" .
            \"static int __init ".a:name."_init(void)\r" .
            \"{\r" .
            \"    return 0\r" .
            \"}\r" .
            \"\r" .
            \"static int __exit ".a:name."_exit(void)\r" .
            \"{\r" .
            \"    return 0\r" .
            \"}\r" .
            \"\r" .
            \"module_init(".a:name."_init);\r" .
            \"module_exit(".a:name."_exit);\r" .
            \"\r" .
            \"MODULE_AUTHOR(\"" .g:git_username. "\");\r" .
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
        if searchpair('^\s*#\s*if\s\+\d\+', '', '^\s*#\s*enif', 'Wb') < 1
            return
        endif
        exec '.s#\d\+#\=submatch(0)==0 ? 1 : 0#'
	endfunc

	command -range Co : call  COMM(<line1>,<line2>)
	func COMM(l1, l2) " add the MACRO comment around the block of C/Cpp code.
		"exec a:l2+1 . \"s%^%#endif    /* comment by yinxianglu */\<CR>%\"
		"exec a:l2+1 . "s%^%#endif\<CR>%"
		"exec a:l1 .   "s%^%#if 0     /* by .g:git_username. on ".strftime("%Y-%m-%d")." */\<CR>%"
		let comment_start = '#if 0     /* by ' . g:git_username . ' on ' . strftime('%Y-%m-%d') . ' */'
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
            exec setline(iLn, strNew)
            exec iLn
        elseif strLn =~ '^\s*#\s*undef'
            let strNew=substitute(strLn, "undef", "define", "")
            exec setline(iLn, strNew)
            exec iLn
        endif
	endfunc

	command PT :call PTRACE()
	func PTRACE() " ptrace func for cursor
    endf

    func Lcpp()
        call Title("cpp")         " diff commect char
    endfun

    func Lsh()
        call Title("sh")        " comment char
    endfun

    func Lc()
        call Title("c")        " comment char
    endfun

    func Lpy()
        call Title("py")        " comment char
    endfun

    func Title(type)
		let ctype=a:type
        if strridx(ctype, "sh") == 0
          let fch="#! \\/bin\\/bash\\r#"
          let cch="#"
        elseif strridx(ctype, "py") == 0
          let fch="#!\\/usr\\/bin\\/env python\r# coding=utf-8\r#"
          let cch="#"
        else
          let fch="\\/"
          let cch="*"
        endif

		let fn = strpart(@%, strridx(@%, "/") + 1)
		if strridx(fn,"\.h") > 0
			let defn = substitute(toupper(fn), "\\.H", "_DEF_H__", "")
			let defh = "#ifndef  __" . defn . "\r#define  __" . defn . "\r"
		elseif strridx(fn,"\.c") > 0
			let defh = "#ifdef __cplusplus\rextern \"C\" {\r#endif\r"
		else
			let defh = "\r\r"
		endif

		let maintainer_name = (g:git_username != "") ? g:git_username : $USER
		let maintainer_email = (g:git_email != "") ? g:git_email : 'unknown@example.com'
		" 计算填充的空格，保持与第一行一致
		let rspace = "                                      "
		let maintainer_line = " Maintainer: " . maintainer_name . "  <" . maintainer_email . ">"

		" 动态计算空格长度
		let maintainer_padding = strpart(rspace, 0, 66 - len(maintainer_line))

		" 使用动态的 Maintainer 信息和调整过的空格
		let header =
                \ fch . "********************************************************************\r" .
                \ cch . " file: " . fn . strpart(rspace, 0, 35 - len(fn) - len($USER)) .
                \ strftime("date: %a %Y-%m-%d %H:%M:%S") . "*\r" .
                \ cch . "                                                                   *\r" .
                \ cch . " Description:                                                      *\r" .
                \ cch . "                                                                   *\r" .
                \ cch . "                                                                   *\r" .
                \ cch .  maintainer_line . maintainer_padding . " *\r" .
                \ cch . "                                                                   *\r" .
                \ cch . " This file is free software;                                       *\r" .
                \ cch . "   you are free to modify and\\/or redistribute it                   *\r".
                \ cch . "   under the terms of the GNU General Public Licence (GPL).        *\r" .
                \ cch . "                                                                   *\r" .
                \ cch . " Last modified:                                                    *\r" .
                \ cch . "                                                                   *\r" .
                \ cch . " No warranty, no liability, use this at your own risk!             *\r" .
                \ cch . "*******************************************************************\\/\r".
                \ defh

		" 执行替换命令
		execute "1g/^/s//" . header

		if strridx(fn,"\.h") > 0
			let defh="\r\r\r#endif\\/* __" . defn . " *\\/\r"
		elseif strridx(fn,"\.c") > 0
			let defh = "\r\r\r\r\r\r#ifdef __cplusplus\r};\r#endif\r"
		else
			let defh = "\r\r"
		endif

		if strridx(ctype, "sh") == 0
			let fch="#"
		elseif strridx(ctype, "py") == 0
			let fch="#"
		else
			let fch="\\/"
		endif

		let rspace = "****************************"
		execute "$g/$/s//" . defh . fch .
                \ strpart(rspace, 0, 24-strlen(fn)/2) . " End Of File: " . fn . " " .
                \ strpart(rspace, 0, 24-strlen(fn)/2) . '\/'
		execut 21
	endfun
augroup END
