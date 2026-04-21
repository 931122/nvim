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
