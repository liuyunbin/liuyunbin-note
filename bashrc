
PS1='\[\e[32m\]$(date "+%Y-%m-%d %H:%M:%S %z") \[\e[0m\]'

note=~/github/note

PATH="$PATH:$note:$note/bin"

alias lsa="ls --time-style='+%Y-%m-%d %H:%M:%S %z' -lhrtu" # 以 文件访问时间     排序, 不准确
alias lsc="ls --time-style='+%Y-%m-%d %H:%M:%S %z' -lhrtc" # 以 文件属性修改时间 排序
alias lsm="ls --time-style='+%Y-%m-%d %H:%M:%S %z' -lhrt"  # 以 文件内容修改时间 排序
alias lsd="ls --time-style='+%Y-%m-%d %H:%M:%S %z' -lhrtd" # 以 文件内容修改时间 排序, 只列出目录本身
alias lss="ls --time-style='+%Y-%m-%d %H:%M:%S %z' -lhrS"  # 以 文件大小         排序
alias lsv="ls --time-style='+%Y-%m-%d %H:%M:%S %z' -lhrv"  # 以 文件名为版本号   排序

alias b="cd $note; tool.sh build > /dev/null; cd - > /dev/null"
alias c="cd $note; pwd"
alias g="g++ -g -std=c++11 "
alias i="tool.sh install_command" # 安装命令
alias lastlog="tool.sh lastlog"   # 列出用户的最后一次登录
alias l="lsm"
#alias p="tool.sh ps"            # 列出进程的常用信息
alias p="git push gitlab master; git push github master"
alias t="g test.cc && ./a.out"
alias v='vim -c "e ++enc=utf-8" -c "set nobomb"'
alias x='tar zxf'
alias z='tar zcf'

alias addeol="vim -c 'set eol'       -c 'wq!'"  # 文件末尾 无换行符 => 有换行符
alias deleol="vim -c 'set bin noeol' -c 'wq!'"  # 文件末尾 有换行符 => 无换行符

