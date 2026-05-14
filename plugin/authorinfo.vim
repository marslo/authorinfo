"=============================================================================
"     FileName: authorinfo.vim
"         Desc:
"       Author: dantezhu
"        Email: zny2008@gmail.com
"     HomePage: http://www.vimer.cn
"      Created: 2012-10-18 10:59:43
"      Version: 2.0
"   LastChange: 2026-05-14 02:12:00
"      History:
"               1.0 | dantezhu | support bash's #!xxx
"               1.1 | dantezhu | fix bug for NerdComment's <leader>
"               1.6 | dantezhu | add created
"               1.7 | dantezhu | add history init
"               2.0 | marslo  | use &commentstring instead of <leader> mappings
"=============================================================================

if exists('g:loaded_authorinfo')
    finish
endif
let g:loaded_authorinfo = 1

function s:CheckFileType(type)
    return index(split(&filetype, '\.'), a:type) >= 0
endfunction
function s:DetectFirstLine()
    "跳转到指定区域的第一行，开始操作
    exe 'normal 1G'
    let arrData = [
                \['sh',     ['^#!.*$', '^#\s*shellcheck\s.*$', '^#\s*vint:.*$']],
                \['python', ['^#!.*$', '^#.*coding:.*$', '^#\s*pylint:.*$', '^#\s*type:\s*ignore.*$']],
                \['php',    ['^<?.*']]
                \]
    let oldNum = line('.')
    while 1
        let line = getline('.')
        let findMatch = 0
        for [t, v] in arrData
            if s:CheckFileType(t)
                for it in v
                    if line =~ it
                        let findMatch = 1
                        break
                    endif
                endfor
            endif
        endfor
        if findMatch != 1
            break
        endif
        normal j
        "到了最后一行了，所以直接o就可以了
        if oldNum == line('.')
            normal o
            return
        endif
        let oldNum = line('.')
    endwhile
    normal O
endfunction
function s:GetCommentPrefix()
    let l:cms = !empty(&commentstring) ? &commentstring : '# %s'
    let l:parts = split(l:cms, '%s', 1)
    let l:pre = substitute(get(l:parts, 0, '#'), '\s*$', '', '')
    return !empty(l:pre) ? l:pre . ' ' : ''
endfunction
" requires GNU coreutils `stat`; falls back to strftime() on BSD-only systems
function s:GetBirthTime()
    let l:file = expand('%:p')
    if empty(l:file) || !filereadable(l:file)
        return strftime('%Y-%m-%d %H:%M:%S')
    endif
    let l:epoch = trim(system('stat -c ''%W'' ' . shellescape(l:file)))
    if v:shell_error || l:epoch !~# '^\d\+$' || l:epoch ==# '0'
        return strftime('%Y-%m-%d %H:%M:%S')
    endif
    if has('mac') || has('macunix')
        let l:result = trim(system('date -r ' . l:epoch . " '+%Y-%m-%d %H:%M:%S'"))
    else
        let l:result = trim(system('date -d @' . l:epoch . " '+%Y-%m-%d %H:%M:%S'"))
    endif
    return v:shell_error ? strftime('%Y-%m-%d %H:%M:%S') : l:result
endfunction
function s:AddTitle()
    let saved_ei = &eventignore
    set eventignore=CursorHold,CursorHoldI,TextChanged,TextChangedI,BufWritePre
    call s:DetectFirstLine()

    let l:pre = s:GetCommentPrefix()


    let firstLine = line('.')
    call setline('.', l:pre . '=============================================================================')
    normal o
    call setline('.', l:pre . '     FileName : ' . expand('%:t'))
    normal o
    call setline('.', l:pre . '       Author : ' . g:vimrc_author)
    normal o
    call setline('.', l:pre . '      Created : ' . s:GetBirthTime())
    normal o
    call setline('.', l:pre . '   LastChange : ' . strftime('%Y-%m-%d %H:%M:%S'))
    normal o
    call setline('.', l:pre . '=============================================================================')


    exe 'normal ' . firstLine . 'G'
    "恢复事件忽略设置
    let &eventignore = saved_ei
    echohl WarningMsg | echo 'Succ to add the copyright.' | echohl None
endf
function s:TitleDet()
    silent! normal ms
    let updated = 0
    let n = 1
    while n < 20
        let line = getline(n)
        if line =~ '^.*FileName\s*:\S*.*$'
            let newline = substitute(line, ':\(\s*\)\(\S.*$\)$', ':\1' . expand('%:t'), 'g')
            call setline(n, newline)
            let updated = 1
        endif
        if line =~ '^.*LastChange\s*:\S*.*$'
            let newline = substitute(line, ':\(\s*\)\(\S.*$\)$', ':\1' . strftime('%Y-%m-%d %H:%M:%S'), 'g')
            call setline(n, newline)
            let updated = 1
        endif
        let n = n + 1
    endwhile
    if updated == 1
        silent! normal 's
        echohl WarningMsg | echo 'Succ to update the copyright.' | echohl None
        return
    endif
    call s:AddTitle()
endfunction
command! -nargs=0 AuthorInfoDetect :call s:TitleDet()
