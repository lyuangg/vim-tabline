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
let g:buftabline_numbers          = get(g:, 'buftabline_numbers',         2)
let g:buftabline_indicators       = get(g:, 'buftabline_indicators',      1)
let g:buftabline_show             = get(g:, 'buftabline_show',            1)
let g:buftabline_ignore_filetype  = get(g:, 'buftabline_ignore_filetype', ['help', 'nerdtree'])
let g:buftabline_plug_max         = get(g:, 'buftabline_plug_max',       9)
let g:buftabline_key_mappings     = get(g:, 'buftabline_key_mappings',    1)
let g:buftabline_max_buffers      = get(g:, 'buftabline_max_buffers',    0)
let g:buftabline_max_label_length = get(g:, 'buftabline_max_label_length', 30)

" Click handlers {{{1
function! BufTabLineBufClick(id, clicks, button, mods) abort
  execute 'buffer' a:id
  " Force tabline redraw — Vim may not re-evaluate %! expression
  " fast enough after buffer switch from a tablineat click
  redrawtabline
endfunction

function! BufTabLineTabClick(id, clicks, button, mods) abort
  execute 'tabnext' a:id
endfunction

" Get filtered list of all listed buffers {{{1
" Returns list of dicts: [{'num': N, 'mod': 0|1}, ...]
function! BufTabLineCurrentTabBuffers() abort
  let result = []
  if exists('*getbufinfo')
    " Fast path (Vim 7.4.2231+): C-level buffer enumeration
    for info in getbufinfo({'buflisted': 1})
      if get(info, 'buftype', '') ==# 'quickfix' | continue | endif
      let ftype = get(info, 'filetype', '')
      if !empty(g:buftabline_ignore_filetype)
            \ && index(g:buftabline_ignore_filetype, ftype) >= 0
        continue
      endif
      call add(result, {'num': info.bufnr, 'mod': get(info, 'changed', 0)})
    endfor
  else
    " Fallback for older Vim: iterate buffer number range
    for bufnum in range(1, bufnr('$'))
      if !buflisted(bufnum) | continue | endif
      if getbufvar(bufnum, '&buftype') ==# 'quickfix' | continue | endif
      let ftype = getbufvar(bufnum, '&filetype')
      if !empty(g:buftabline_ignore_filetype)
            \ && index(g:buftabline_ignore_filetype, ftype) >= 0
        continue
      endif
      call add(result, {'num': bufnum, 'mod': getbufvar(bufnum, '&mod')})
    endfor
  endif
  return result
endfunction

" Truncate a label to maxlen characters, appending '…' when truncated {{{1
function! s:TruncateLabel(label, maxlen) abort
  if a:maxlen > 0 && len(a:label) > a:maxlen
    return a:label[: a:maxlen - 2] . '…'
  endif
  return a:label
endfunction

" Render {{{1
function! BufTabLineRender() abort
  let show_num = g:buftabline_numbers == 1
  let show_ord = g:buftabline_numbers == 2
  let show_mod = g:buftabline_indicators
  let max_buf = g:buftabline_max_buffers
  let max_label = g:buftabline_max_label_length

  let curbuf = winbufnr(0)
  let curtab = tabpagenr()

  " ── Pre-compute all entries with widths ── {{{2
  let entries = []
  for e in BufTabLineCurrentTabBuffers()
    let bufnum = e.num
    let ordinal = len(entries) + 1

    " Label
    let bufpath = bufname(bufnum)
    if empty(bufpath)
      let label = '*'
    else
      let label = fnamemodify(bufpath, ':t')
      if empty(label) | let label = bufpath | endif
    endif
    let label = s:TruncateLabel(label, max_label)

    " Modified (pre-computed by BufTabLineCurrentTabBuffers)
    let mod = e.mod

    " Highlight
    let hl = bufnum == curbuf ? 'Current'
          \ : bufwinnr(bufnum) > 0 ? 'Active'
          \ : 'Hidden'
    if mod | let hl = 'Modified' . hl | endif

    " Prefix
    let prefix = ''
    if show_num
      let prefix = bufnum
    elseif show_ord
      let prefix = ordinal
    endif
    if mod && show_mod | let prefix = '+' . prefix | endif

    " Display text and visual width (spaces counted: " display ")
    let display = empty(prefix) ? label : prefix . ' ' . label
    let width = strwidth(display) + 2

    call add(entries, {
          \ 'num': bufnum,
          \ 'display': display,
          \ 'hl': hl,
          \ 'width': width,
          \ })
  endfor
  let total = len(entries)

  " ── Available width for buffer section ── {{{2
  let tabs_width = 0
  for tnr in range(1, tabpagenr('$'))
    let tabs_width += strwidth(gettabvar(tnr, 'title', 'Tab ' . tnr)) + 2
  endfor
  " &columns minus tab section, fill marker, and margin
  let avail = &columns - tabs_width - 4

  " ── Determine visible range ── {{{2
  let left_dots = 0
  let right_dots = 0
  let show_start = 0
  let show_end = total

  if total > 0
    " Calculate total width of all entries
    let total_w = 0
    for e in entries | let total_w += e.width | endfor

    " Truncate if width doesn't fit OR user set explicit limit
    if (max_buf > 0 && total > max_buf) || total_w > avail
      " Find current buffer index
      let cur_idx = 0
      for i in range(total)
        if entries[i].num == curbuf | let cur_idx = i | break | endif
      endfor

      " Estimate max entries that fit by available width
      let dot_w = strwidth(' … ')
      let eff_max = max_buf > 0 ? min([max_buf, total]) : total
      if total_w > avail
        let avg_w = total_w / total
        let eff_max = min([eff_max, (avail - dot_w * 2) / (avg_w + 1)])
        let eff_max = max([1, eff_max])
      endif

      " Apply centered truncation
      let half = eff_max / 2
      let show_start = max([0, cur_idx - half])
      let show_end = min([total, show_start + eff_max])
      if show_end - show_start < eff_max
        let show_start = max([0, show_end - eff_max])
        let show_end = min([total, show_start + eff_max])
      endif

      let left_dots = show_start > 0
      let right_dots = show_end < total
    endif
  endif

  " ── Render: buffers ── {{{2
  let tabline = ''
  if left_dots
    let tabline .= '%#BufTabLineHidden# … '
  endif
  for i in range(show_start, show_end - 1)
    let e = entries[i]
    let display = substitute(e.display, '%', '%%', 'g')
    let tabline .= '%#BufTabLine' . e.hl . '#'
    if has('tablineat')
      let tabline .= '%' . e.num . '@BufTabLineBufClick@ ' . display . ' '
    else
      let tabline .= ' ' . display . ' '
    endif
  endfor
  if right_dots
    let tabline .= '%#BufTabLineHidden# … '
  endif

  " ── Render: fill + tabs ── {{{2
  let tabline .= '%#BufTabLineFill#%=%#BufTabLineFill#'
  for tnr in range(1, tabpagenr('$'))
    let hl = tnr == curtab ? 'Current' : 'Active'
    let label = gettabvar(tnr, 'title', 'Tab ' . tnr)
    let label = substitute(label, '%', '%%', 'g')
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
    let bufs = filter(BufTabLineCurrentTabBuffers(), 'v:val.num != zombie')
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
  autocmd BufEnter   * call BufTabLineUpdate()
  autocmd BufAdd     * call BufTabLineUpdate()
  autocmd BufDelete  * call BufTabLineUpdate(str2nr(expand('<abuf>')))
  autocmd FileType qf call BufTabLineUpdate()
augroup END

" <Plug> mappings for keyboard access {{{1
for s:n in range(1, g:buftabline_plug_max) + (g:buftabline_plug_max > 0 ? [-1] : [])
  let s:b = s:n == -1 ? -1 : s:n - 1
  execute printf("noremap <silent> <Plug>BufTabLine.Go(%d) :<C-U>exe 'b'.get(get(BufTabLineCurrentTabBuffers(),%d,{}),'num','')<cr>", s:n, s:b)
endfor
unlet! s:n s:b

" Default key mappings {{{1
if g:buftabline_key_mappings
  for s:n in range(1, g:buftabline_plug_max)
    execute printf('nmap <leader>%d <Plug>BufTabLine.Go(%d)', s:n, s:n)
  endfor
  unlet! s:n
endif
