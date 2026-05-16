"=============================================================================
"     FileName: authorinfo.vim
"         Desc:
"       Author: dantezhu
"        Email: zny2008@gmail.com
"     HomePage: http://www.vimer.cn
"      Created: 2012-10-18 10:59:43
"      Version: 2.1.0
"      Updater: marslo
"   LastChange: 2026-05-15 17:42:48
"      History:
"               1.0 | dantezhu | support bash's #!xxx
"               1.1 | dantezhu | fix bug for NerdComment's <leader>
"               1.6 | dantezhu | add created
"               1.7 | dantezhu | add history init
"               2.0 | marslo   | use &commentstring instead of <leader> mappings
"               2.1 | marslo   | creation timestamp will no be updated (fix diff-mode bug)
"=============================================================================

if exists('g:loaded_authorinfo')
    finish
endif
let g:loaded_authorinfo = 1

function! s:CheckFileType(type)
    return index(split(&filetype, '\.'), a:type) >= 0
endfunction

function! s:DetectFirstLine()
    let l:arrData = [
                \['sh',     ['^#!.*$', '^#\s*shellcheck\s.*$', '^#\s*vint:.*$']],
                \['python', ['^#!.*$', '^#.*coding:.*$', '^#\s*pylint:.*$', '^#\s*type:\s*ignore.*$']],
                \['php',    ['^<?.*']]
                \]
    let l:curr = 1
    let l:max = line('$')
    while l:curr <= l:max
        let l:line = getline(l:curr)
        let l:match = 0
        for [t, v] in l:arrData
            if s:CheckFileType(t)
                for it in v
                    if l:line =~# it | let l:match = 1 | break | endif
                endfor
            endif
        endfor
        if l:match != 1 | break | endif
        let l:curr += 1
    endwhile
    return l:curr - 1
endfunction

function! s:VerifyLastChange(expected)
    for l:n in range(1, min([line('$'), 20]))
        if getline(l:n) =~# 'LastChange\s*:.*' . a:expected
            return 1
        endif
    endfor
    return 0
endfunction

function! s:GetCommentPrefix()
    let l:cms = !empty(&commentstring) ? &commentstring : '# %s'
    let l:parts = split(l:cms, '%s', 1)
    let l:pre = substitute(get(l:parts, 0, '#'), '\s*$', '', '')
    return !empty(l:pre) ? l:pre . ' ' : ''
endfunction

function! s:GetBirthTime()
    if exists('b:authorinfo_birthtime') && !empty(b:authorinfo_birthtime)
        return b:authorinfo_birthtime
    endif

    let l:file = expand('%:p')
    if empty(l:file) || !filereadable(l:file)
        return strftime('%Y-%m-%d %H:%M:%S')
    endif

    let l:save_ei = &eventignore
    set eventignore=all

    let l:raw = ''
    " get `stat` version - GNU stat or BSD stat
    let l:stat_path = trim(system('which stat'))
    if l:stat_path =~# 'gnubin' || system('stat --version 2>/dev/null') =~# 'GNU'
        " GNU stat (Linux or macOS with GNU coreutils stat)
        let l:raw = trim(system("stat -c '%w' " . shellescape(l:file)))
        if empty(l:raw) || l:raw ==# '-'
            let l:raw = trim(system("stat -c '%y' " . shellescape(l:file)))
        endif
    else
        " BSD stat ( macOS default: `-f '%SB'` Output formatted time, `-t` specifies the time format )
        let l:raw = trim(system("stat -f '%SB' -t '%Y-%m-%d %H:%M:%S' " . shellescape(l:file)))
    endif

    let &eventignore = l:save_ei

    " data cleaning: extract only the date-time part in the format of YYYY-MM-DD HH:MM:SS
    let l:matched = matchstr(l:raw, '^\d\{4\}-\d\{2\}-\d\{2\}\s\d\{2\}:\d\{2\}:\d\{2\}')

    let b:authorinfo_birthtime = !empty(l:matched) ? l:matched : strftime('%Y-%m-%d %H:%M:%S')
    return b:authorinfo_birthtime
endfunction

function! s:AddTitle( exist_created, now )
    let l:pre = s:GetCommentPrefix()
    let l:insert_pos = s:DetectFirstLine()
    let l:birth = !empty( a:exist_created ) ? a:exist_created : s:GetBirthTime()

    let l:lines = []
    call add( l:lines, l:pre . '=============================================================================' )
    call add( l:lines, l:pre . '     FileName : ' . expand('%:t') )
    if exists('g:vimrc_author') | call add( l:lines, l:pre . '       Author : ' . g:vimrc_author ) | endif
    if exists('g:vimrc_email')  | call add( l:lines, l:pre . '        Email : ' . g:vimrc_email )  | endif
    call add( l:lines, l:pre . '      Created : ' . l:birth )
    call add( l:lines, l:pre . '   LastChange : ' . a:now )
    call add( l:lines, l:pre . '============================================================================='  )

    lockmarks call append( l:insert_pos, l:lines )
endfunction

function! s:UpdateAuthorInfo()
    let l:save_ar = &autoread
    setlocal autoread

    " extremely strict event ignoring ( especially for neovim)
    let l:save_ei = &eventignore
    set eventignore=all

    let l:view = winsaveview()
    let l:has_header = 0
    let l:exist_created = ''
    let l:max = min([line('$'), 20])

    " --- 纯内存扫描 (不要在这里调用任何 system() 或 s:GetBirthTime) ---
    let l:header_lines = getline(1, l:max)
    for l:line in l:header_lines
        if l:line =~# 'Created\s*:'
            let l:has_header = 1
            let l:exist_created = matchstr(l:line, 'Created\s*:\s*\zs.*$')
            let b:authorinfo_birthtime = l:exist_created " 缓存起来，防止之后触发 system
        elseif l:line =~# 'FileName\s*:'
            let l:has_header = 1
        endif
    endfor

    " --- 修改逻辑 ---
    let l:now = strftime('%Y-%m-%d %H:%M:%S')
    if !l:has_header
        " 只有真正没有 Header 时才去调用 stat (s:GetBirthTime)
        call s:AddTitle('', l:now)
        let l:action = 'add'
    else
        let l:n = 1
        while l:n <= l:max
            let l:line = getline(l:n)
            let l:newline = l:line

            if l:line =~# 'FileName\s*:'
                let l:newline = substitute(l:line, ':\(\s*\)\(\S.*$\)$', ':\1' . expand('%:t'), 'g')
            elseif exists('g:vimrc_author') && l:line =~# 'Author\s*:'
                let l:newline = substitute(l:line, ':\(\s*\)\(\S.*$\)$', ':\1' . g:vimrc_author, 'g')
            elseif exists('g:vimrc_email') && l:line =~# 'Email\s*:'
                let l:newline = substitute(l:line, ':\(\s*\)\(\S.*$\)$', ':\1' . g:vimrc_email, 'g')
            elseif l:line =~# 'LastChange\s*:'
                let l:newline = substitute(l:line, ':\(\s*\)\(\S.*$\)$', ':\1' . l:now, 'g')
            endif

            if l:newline != l:line
                silent! undojoin
                keepjumps lockmarks call setline(l:n, l:newline)
            endif
            let l:n += 1
        endwhile
        let l:action = 'update'
    endif

    " --- 清理并强制同步状态 ---
    " 在恢复环境前，告诉 Neovim 缓冲区是权威的 - 这是一个狠招：如果还在报错，尝试在 diffupdate 前静默写入一次
    if has('nvim')
        silent! noautocmd write!
    endif

    call winrestview(l:view)
    let &eventignore = l:save_ei
    let &l:autoread = l:save_ar

    " call `diffupdate` automatically if in diff mode
    if &diff | diffupdate | endif

    if s:VerifyLastChange(l:now)
        echohl WarningMsg | echo 'Succ to ' . l:action . ' the author info.'   | echohl None
    else
        echohl ErrorMsg   | echo 'Failed to ' . l:action . ' the author info!' | echohl None
    endif
endfunction

command! -nargs=0 AuthorInfoDetect :call s:UpdateAuthorInfo()
