" tabline.vim - Show all buffers on the left, all tabs on the right
" License: The MIT License (MIT)

if exists('g:tabline_plugin_loaded') || v:version < 700
  finish
endif
let g:tabline_plugin_loaded = 1

scriptencoding utf-8

" Highlight groups {{{1
hi default link BufTabLineCurrent         TabLineSel
hi default link BufTabLineActive          PmenuSel
hi default link BufTabLineHidden          TabLine
hi default link BufTabLineFill            TabLineFill
hi default link BufTabLineModifiedCurrent BufTabLineCurrent
hi default link BufTabLineModifiedActive  BufTabLineActive
hi default link BufTabLineModifiedHidden  BufTabLineHidden

" Options {{{1
let g:buftabline_numbers         = get(g:, 'buftabline_numbers',    0)
let g:buftabline_indicators      = get(g:, 'buftabline_indicators', 0)
let g:buftabline_show            = get(g:, 'buftabline_show',       2)
let g:buftabline_ignore_filetype = get(g:, 'buftabline_ignore_filetype', [])
let g:buftabline_plug_max        = get(g:, 'buftabline_plug_max',  9)

" Click handlers {{{1
function! BufTabLineBufClick(id, clicks, button, mods) abort
  execute 'buffer' a:id
endfunction

function! BufTabLineTabClick(id, clicks, button, mods) abort
  execute 'tabnext' a:id
endfunction

" Get filtered list of all listed buffers {{{1
function! BufTabLineCurrentTabBuffers() abort
  let result = []
  for bufnum in range(1, bufnr('$'))
    if !buflisted(bufnum) | continue | endif
    if getbufvar(bufnum, '&buftype') == 'quickfix' | continue | endif
    let ftype = getbufvar(bufnum, '&filetype')
    if !empty(g:buftabline_ignore_filetype)
          \ && index(g:buftabline_ignore_filetype, ftype) >= 0
      continue
    endif
    call add(result, bufnum)
  endfor
  return result
endfunction

" Render {{{1
function! BufTabLineRender() abort
  let show_num = g:buftabline_numbers == 1
  let show_ord = g:buftabline_numbers == 2
  let show_mod = g:buftabline_indicators

  let curbuf = winbufnr(0)
  let curtab = tabpagenr()

  let tabline = ''
  let ordinal = 0

  " Left side: current tab's buffers
  for bufnum in BufTabLineCurrentTabBuffers()
    let ordinal += 1

    " Highlight: current vs visible in this tab vs hidden
    let hl = bufnum == curbuf ? 'Current'
          \ : bufwinnr(bufnum) > 0 ? 'Active'
          \ : 'Hidden'

    " Label
    let bufpath = bufname(bufnum)
    if empty(bufpath)
      let label = '*'
    else
      let label = fnamemodify(bufpath, ':t')
      if empty(label)
        let label = bufpath
      endif
    endif

    " Modified highlight
    if getbufvar(bufnum, '&mod')
      let hl = 'Modified' . hl
    endif

    " Prefix: number or indicator
    let prefix = ''
    if show_num
      let prefix = bufnum
    elseif show_ord
      let prefix = ordinal
    endif
    if getbufvar(bufnum, '&mod') && show_mod
      let prefix = '+' . prefix
    endif

    " Assemble display text
    let display = empty(prefix) ? label : prefix . ' ' . label
    let display = substitute(display, '%', '%%', 'g')

    let tabline .= '%#BufTabLine' . hl . '#'
    if has('tablineat')
      let tabline .= '%' . bufnum . '@BufTabLineBufClick@ ' . display . ' '
    else
      let tabline .= ' ' . display . ' '
    endif
  endfor

  " Explicitly set fill highlight before right-aligned tab section
  let tabline .= '%#BufTabLineFill#%=%#BufTabLineFill#'
  for tnr in range(1, tabpagenr('$'))
    let hl = tnr == curtab ? 'Current' : 'Active'
    let label = gettabvar(tnr, 'title', 'Tab ' . tnr)
    let tabline .= '%#BufTabLine' . hl . '#'
    if has('tablineat')
      let tabline .= '%' . tnr . '@BufTabLineTabClick@ ' . label . ' '
    else
      let tabline .= ' ' . label . ' '
    endif
  endfor

  return tabline
endfunction

" Update tabline {{{1
function! BufTabLineUpdate(...) abort
  let zombie = a:0 ? a:1 : 0
  set tabline=%!BufTabLineRender()
  if g:buftabline_show == 0
    set showtabline=1
  elseif g:buftabline_show == 1
    let bufs = filter(BufTabLineCurrentTabBuffers(), 'v:val != zombie')
    let &g:showtabline = 1 + (len(bufs) > 1)
  else
    set showtabline=2
  endif
endfunction

" Autocommands {{{1
augroup BufTabLinePlugin
  autocmd!
  autocmd VimEnter   * call BufTabLineUpdate()
  autocmd TabEnter   * call BufTabLineUpdate()
  autocmd BufAdd     * call BufTabLineUpdate()
  autocmd BufDelete  * call BufTabLineUpdate(str2nr(expand('<abuf>')))
  autocmd FileType qf call BufTabLineUpdate()
augroup END

" <Plug> mappings for keyboard access {{{1
for s:n in range(1, g:buftabline_plug_max) + (g:buftabline_plug_max > 0 ? [-1] : [])
  let s:b = s:n == -1 ? -1 : s:n - 1
  execute printf("noremap <silent> <Plug>BufTabLine.Go(%d) :<C-U>exe 'b'.get(BufTabLineCurrentTabBuffers(),%d,'')<cr>", s:n, s:b)
endfor
unlet! s:n s:b
