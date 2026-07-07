# vim-tabline

Show all listed buffers on the left side of the tabline and all tabs on the right side. Click or use keyboard shortcuts to switch.

![screenshot](https://raw.githubusercontent.com/lyuangg/vim-tabline/main/screenshot.png)

## Features

- Left side: all listed buffers with current/active/hidden highlighting
- Right side: all tab pages (clickable to switch)
- Buffer number or ordinal number display
- Modified buffer indicator (`+` prefix and `Modified*` highlight)
- **Smart truncation**: when buffer count or filenames overflow the tabline, buffers are centered on the current one with `…` indicators
- Configurable show/hide behavior
- Click-to-switch via `tablineat` (when available)
- Keyboard mappings via `<Plug>BufTabLine.Go(N)`
- Compatible with [gcmt/taboo.vim](https://github.com/gcmt/taboo.vim) tab titles

## Requirements

- Vim 7.0+
- For click-to-switch: Vim compiled with `+tablineat` feature (`:echo has('tablineat')`)

## Installation

### vim-plug

```vim
Plug 'lyuangg/vim-tabline'
```

### Manual

Copy `plugin/tabline.vim` to `~/.vim/plugin/`.

## Configuration

```vim
" Show behavior: 0=never, 1=when >1 buffer, 2=always (default: 1)
let g:buftabline_show = 1

" Number display: 0=none, 1=buffer number, 2=ordinal number (default: 2)
let g:buftabline_numbers = 2

" Show modified indicator (+ prefix) (default: 1)
let g:buftabline_indicators = 1

" Ignore buffers with these filetypes (default: ['help', 'nerdtree'])
let g:buftabline_ignore_filetype = ['help', 'nerdtree']

" Max number of <Plug>BufTabLine.Go(N) mappings (default: 9)
let g:buftabline_plug_max = 9

" Enable default <leader>1~9 key mappings (default: 1)
let g:buftabline_key_mappings = 1

" Max buffer entries to show. 0 = auto (truncate by available width).
" When truncation occurs, buffers are centered on the current one with … indicators. (default: 0)
let g:buftabline_max_buffers = 0

" Max label length for buffer names. 0 = unlimited. (default: 30)
let g:buftabline_max_label_length = 30
```

## Key Mappings

The plugin defines these `<Plug>` mappings for keyboard access:

| Mapping | Action |
|---------|--------|
| `<Plug>BufTabLine.Go(1)` ~ `<Plug>BufTabLine.Go(N)` | Go to Nth buffer |
| `<Plug>BufTabLine.Go(-1)` | Go to last buffer |

By default, `<leader>1` to `<leader>9` are mapped automatically. To disable:

```vim
let g:buftabline_key_mappings = 0
```

To customize:

```vim
let g:buftabline_key_mappings = 0
nmap <leader>1 <Plug>BufTabLine.Go(1)
nmap <leader>2 <Plug>BufTabLine.Go(2)
" ...
nmap <leader>0 <Plug>BufTabLine.Go(-1)
```

## Highlight Groups

| Group | Links to | Usage |
|-------|----------|-------|
| `BufTabLineCurrent` | `TabLineSel` | Current buffer / tab |
| `BufTabLineActive` | `PmenuSel` | Buffer visible in window |
| `BufTabLineHidden` | `TabLine` | Loaded but not visible |
| `BufTabLineFill` | `TabLineFill` | Tabline filler |
| `BufTabLineModifiedCurrent` | `BufTabLineCurrent` | Modified current buffer |
| `BufTabLineModifiedActive` | `BufTabLineActive` | Modified active buffer |
| `BufTabLineModifiedHidden` | `BufTabLineHidden` | Modified hidden buffer |

## License

MIT License. Based on [ap/vim-buftabline](https://github.com/ap/vim-buftabline).
