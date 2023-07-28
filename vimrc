
set cindent                           " 使用 C 风格的自动缩进
set expandtab                         " 自动扩展 Tab
set hlsearch                          " 高亮
set number                            " 默认显示行号
set shiftwidth=4                      " 自动缩进使用的空格数量
set softtabstop=4                     " 调整 缩进的 表现, 开启 expandtab 的时候, 此选项没用
set tabstop=4                         " 设置 Tab 所占的宽度
autocmd FileType make set noexpandtab " Makefile 不扩展 Tab

"对行末的空格标红
highlight WhitespaceEOL ctermbg=red guibg=red
match WhitespaceEOL /\s\+$/

autocmd BufWritePre * :%s/\s\+$//e " 自动去除行尾的空格

"vim 保存时，自动格式化 C/C++ 代码
function! Formatonsave()
  let l:lines = "all"
  py3f /usr/share/vim/addons/syntax/clang-format.py
endfunction

autocmd BufWritePre *.h,*.cc,*.cpp,*.c call Formatonsave()

set fileencodings=ucs-bom,utf-8,gbk,big5,gb18030,latin1
