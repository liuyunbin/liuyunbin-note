
##################################
#
#             Linux 基础
#
##################################

文件名称建议: 大小写字母 数字 下划线 短横线 点

errno 是线程安全的, 如何检验

## 学习命令需要注意的问题
* 是否支持通配符, 基础正则表达式, 还是扩展正则表达式
* 如何处理符号链接

## 通配符
?      # 代表一个字符
*      # 代表零个或多个字符
[123]
[1-5]
[!a]
[^a]

## 基础正则表达式
^     # 开头
$     # 结尾
.     # 除换行符以外的任意字符
[]    # 中括号中      的任意字符
[^]   # 中括号中字符外的任意字符
?     # 前面字符出现 0 次 或 一次
*     # 前面字符出现 0 次 或 多次
<abc  # 单词以 abc 开头
abc>  # 单词以 abc 结尾

## 扩展正则表达式
+      # 前面字符出现 1 次 或 多次
{n}    # 前面字符出现 n 次
{n,}   # 前面字符出现 n 次 及以上
{n, m} # 前面字符出现 n 次 到 m 次
()     # 将括号内的内容看成一个整体
|      # 或

#### 查看 Linux 临时端口号的范围
```
cat /proc/sys/net/ipv4/ip_local_port_range
32768   60999
``

* [0, 1024) 公认端口号, 需要 root 启动, 比如 80
* [1024, 32768) 注册端口, 可以自己注册一些常用服务
* [32768, 60990) 动态端口, 进程未指定端口号时, 将从这个范围内获取一个端口号
* [60990, 65535)

# 查询 域名 对应 的 IP
* nslookup baidu.com

\command # 忽略别名

## 文件时间
atime # 内容读取时间, 更新可能不及时
mtime # 内容修改时间
ctime # 状态修改时间: 内容 名称 权限 所属者 所数组

## 文件权限
* 读, 写, 执行
* SUID:
    文件执行时, 拥有此文件所有者的权限
    只对二进制有效
* SGID:
    二进制文件: 文件执行时, 拥有此文件所属组的权限
          目录: 新增的文件所属的组是此目录所属的组
* SBIT: 此目录下的文件只有文件或目录所有者才可以删除
* 权限判断: 依次判断所属用户, 所属组和其他权限
                前者失败时, 不判断后者
            假如 1.cc 的权限为 0070,
                所属主无权限, 所属组有权限时,
                也将判断为无权限
* 在目录下新增或删除文件时, 至少拥有此目录的写和执行权限

##################################
#
#             常用命令
#
##################################

## 操作符号链接本身

## 操作符号链接所指的文件
chmod
chown

/proc/.../cmdline  # 完整的启动命令
/proc/.../comm     # 进程名称, 最多 15 位
/proc/.../cwd      # 当前目录

apt show    vim # 列出软件包的信息
apt install vim # 安装软件包
apt remove  vim # 卸载软件包
apt purge   vim # 卸载软件包, 删除数据和配置文件
apt update      # 更新软件源
apt upgrade     # 更新软件

awk 'BEGIN   { getline     } # 读取一行
     pattern { commands    }
     END     { print "end" }' 1.c
* awk 使用扩展的正则表达式
* BEGIN 和 END 都是可选的
* 只能用单引号
awk 'NR < 5'                 1.c # 行号 [1,4] 的行
awk 'NR==1,NR==4'            1.c # 行号 [1,4] 的行
awk '/linux/'                1.c #   包含 linux 的行
awk '!/linux/'               1.c # 不包含 linux 的行
awk '/start/,/end/'          1.c # [] 区间匹配
awk '$1  ~ /lyb.*/'          1.c #     字段匹配
awk '$1 !~ /lyb.*/'          1.c # 排除字段匹配
awk '$1 == 123'              1.c # $1 如果能转化为数字
                             1.c # 将使用数字匹配
awk -F:      '{print    $2}' 1.c # 输入字段分割符
awk -F123    '{print    $2}' 1.c # 字符串 123 作为分割符
awk -F[123]  '{print    $2}' 1.c # 字符 1 2 3 作为分割符
awk -v  FS=: '{print    $2}' 1.c # 定义变量
awk -v OFS=- '{print $1,$2}' 1.c # 输出字段分割符
awk -f 1.awk                 1.c # 从文件中读取操作
awk          '{print    NF}' 1.c # 字段数量
awk          '{print    NR}' 1.c # 所有文件中的行号
awk          '{print   FNR}' 1.c # 当前文件中的行号
awk          '{print    $0}' 1.c # 当前记录的内容
awk          '{print    $1}' 1.c # 第一个字段的内容
awk          '{print    $2}' 1.c # 第二个字段的内容
awk    '{printf "%s\n", $2}' 1.c # C 风格输出

bc <<< "scale=2; 10/2" # 设置使用两位小数, 输出: 5.00
bc <<< "ibase=2;  100" # 输入使用二进制, 输出: 4
bc <<< "obase=2;   10" # 输出使用二进制, 输出: 1010

cat -n 1.txt # 显示行号
cat -b 1.txt # 显示行号, 不包括空行
cat -s 1.txt # 去掉多余的连续的空行
cat -T 1.txt # 显示 TAB
cat -E 1.txt # 列出行尾标识

comm 1.c 2.c       | tr -d '\t' # 全集
comm 1.c 2.c -1 -2 | tr -d '\t' # 交集
comm 1.c 2.c -3    | tr -d '\t' # B - A 和 A - B
comm 1.c 2.c -1 -3              # B - A
comm 1.c 2.c -2 -3              # A - B

c++filt  a.out   # 可以解析动态库里的符号

bash file_name # 执行文件内的命令
bash -c "ls"   # 将字符串的内容交由 bash 执行, 字符串里可包含重定向和管道

* ls &> /dev/null # 重定向
* exec &>> 1.log  # 脚本内重定向

* (ls)            # 子shell执行命令, 输出到屏幕上
* lyb=$(ls)       # 子shell执行命令, 存入变量
* cat <(ls)       # 将命令或函数的输出做为 文件
* lyb=$((1+2))    # 数学计算, 变量不需要加 $
* [[ -a 1.c ]]    # 判断文件的各种状态
* [[ lyb =~ ^l ]] # 扩展的正则表达式
* {ls ... }       # 代码块
* {1..10..2}      # 获取字符序列

length=${#val}       # 输出字符串的长度
${val:起始位置:长度} # 获取子串
lyb=123
lyb=$lyb+123         # lyb 将变成 123+123

${v:-w} # v 不为空, 返回 $v, 否则, 返回 w
${v:=w} # v 不为空, 返回 $v, 否则, 令 v=w, 返回 w
${v:+w} # v 不为空, 返回  w, 否则, 返回空
${v:?w} # v 不为空, 返回 $v, 否则, 输出 w, 退出

lyb=123.456.txt
lyb=${lyb%.*}      # 后缀非贪婪匹配, lyb 为 123.456
lyb=${lyb%%.*}     # 后缀  贪婪匹配, lyb 为 123
lyb=${lyb#*.}      # 前缀非贪婪匹配, lyb 为 txt
lyb=${lyb##*.}     # 前缀  贪婪匹配, lyb 为 456.txt
lyb=${lyb/*./str}  # 全文  贪婪匹配, lyb 为 txt, 匹配一次 - TODO
lyb=${lyb//*./str} # 全文  贪婪匹配, lyb 为 txt, 匹配多次
lyb=${lyb^^}       # 变为大写
lyb=${lyb,,}       # 变为小写

v=(1 2 3) # 定义数组
${v[1]}   # 数组中指定元素的值
${v[@]}   # 数组中所有元素的值, "1" "2" "3"
${#v[@]}  # 数组中元素的个数
${!v[@]}  # 获取所有的 key

declare -A v # 关联数组, map
v[a]=a
v[b]=b

$0 # 脚本名称
$1 # 第一个参数
$@ # 参数序列
$# # 参数个数

## 脚本上重定向
cat << EOF
    $lyb
EOF

!!    # 上一条命令
!l    # 执行最近使用的以 l 打头的命令
!l:p  # 输出最近使用的以 l 打头的命令
!num  # 执行历史命令列表的第 num 条命令
!$    # 上一条命令的最后一个参数
^1^2  # 将前一条命令中的 1 变成 2

bg %jobspec # 后台暂停 --> 后台运行, 有无 % 都成

chattr +i 1.c # 设置文件不可修改
chattr -i 1.c # 取消文件不可修改

chmod  755    1.c # 设置权限, 不足四位时, 补前缀 0
chmod  644 -R 1.c # 递归
chmod 4755    1.c # 设置 SUID(4)
chmod 2755    1.c # 设置 SGID(2)
chmod 1755    1.c # 设置 SBIT(1)

chown lyb:lyb 1.c # 修改文件所属的组和用户

cp    123 456      # 拷贝文件时, 使用符号链接所指向的文件
                   # 拷贝目录时, 使用符号链接本身
                   # 456 只使用符合链接所指向的文件
cp -r 123 456      # 递归复制
cp -P 123 456      # 总是拷贝符号链接本身
cp -L 123 456      # 总是拷贝符号链接所指的文件
cp --parents a/b t # 全路径复制, 将生成 t/a/b

crontab -l # 查询任务表
crontab -e # 编辑任务表
crontab -r # 删除任务表
           # 格式为: 分钟 小时 日 月 星期 执行的程序
           # *     : 每分钟执行
           # 1-3   : 1 到 3分钟内执行
           # */3   : 每 3 分钟执行一次
           # 1-10/3: 1-10 分钟内, 每 3 分钟执行
           # 1,3,5 : 1,3,5 分钟执行
           # crontab 不会自动执行 .bashrc, 如果需要, 需要在脚本中手动执行

Ctrl+A      # TODO-将光标移到行首
Ctrl+B      # TODO-将光标向左移动一个字符
Ctrl+C      # TODO-向前台进程组发送 SIGINT, 默认终止进程
Ctrl+D      # TODO-删除光标前的字符 或 产生 EOF 或 退出终端
Ctrl+E      # TODO-将光标移到行尾
Ctrl+F      # TODO-将光标向右移动一个字符
Ctrl+G      # TODO-退出当前编辑
Ctrl+H      # TODO-删除光标前的一个字符
Ctrl+I      # TODO-删除光标前的一个字符
Ctrl+J      # TODO-删除光标前的一个字符
Ctrl+K      # TODO-删除光标处到行尾的字符
Ctrl+L      # TODO-清屏
Ctrl+M      # TODO-清屏
Ctrl+N      # TODO-查看历史命令中的下一条命令
Ctrl+O      # TODO-类似回车，但是会显示下一行历史
Ctrl+P      # TODO-查看历史命令中的上一条命令
Ctrl+Q      # TODO-解锁终端
Ctrl+R      # TODO-历史命令反向搜索, 使用 Ctrl+G 退出搜索
Ctrl+S      # TODO-锁定终端 或 历史命令正向搜索, 使用 Ctrl+G 退出搜索
Ctrl+T      # TODO-交换前后两个字符
Ctrl+U      # TODO-删除光标处到行首的字符
Ctrl+V        TODO-           # 输入字符字面量，先按 Ctrl+V 再按任意键 ?
Ctrl+W      # TODO-删除光标左边的一个单词
Ctrl+X        TODO-           # 列出可能的补全 ?
Ctrl+Y      # TODO-粘贴被删除的字符
Ctrl+Z  # 前台运行的程序 --> 后台暂停
Ctrl+/      # TODO-撤销之前的操作
Ctrl+\      # TODO-产生 SIGQUIT, 默认杀死进程, 并生成 core 文件

curl -I ... # 只打印头部信息

cut -f 1,2  # 按列切割
cut -d ":"  # 设置分割符

date "+%Y-%m-%d %H:%M:%S"   # 输出: 年-月-日 时-分-秒
date "+%Y-%m-%d %H:%M"      # 输出: 年-月-日 时-分
date "+%s"                  # 输出: 时间戳
date -d "20200202 01:01:01" # 使用: 指定输入日期
date -d "@...."             # 使用: 时间戳
date -r 1.c                 # 使用: 文件的 mtime
date -s "20200202 10:10:10" # 更新系统时间, 需要 root

dd if=/dev/zero of=junk.data bs=1M count=1

df -Th # 所挂载的系统的使用情况

diff    1.txt 2.txt              # 比较两个文件的不同
diff -u 1.txt 2.txt              # 一体化输出, 比较两个文件的不同
diff    1.txt 2.txt > diff.pathc # TODO

dirname $(readlink -f $0) # 获取脚本的名称

fg %jobspec   # 后台 --> 前台运行, 有无 % 都成

docker run ubuntu:15.10 -d --name "lyb"           # 启动 docker, 给起一个名字
docker run ubuntu:15.10 -d --net=host             # 主机和 docker 共享 IP 和 端口号
docker run ubuntu:15.10 -d -P                     # docke 内使用随机端口映射主机端口
docker run ubuntu:15.10 -d -p 2000:3000           # 本机:2000 绑定 docker:3000
docker run ubuntu:15.10 -d -v /home/123:/home/456 # 本机:/home/123 绑定 docker:/home/456

docker port     容器ID     # 查看端口号映射
docker ps                  # 列出当前运行的容器
docker ps -a               # 列出所有容器
docker start    容器ID     # 启动容器
docker stop     容器ID     # 停止容器
docker restart  容器ID     # 重新启动容器
docker rm -f    容器ID     # 删除容器
docker exec     容器ID ls  # 对于在后台运行的容器, 执行命令

dos2unix 1.txt # 换行符转换

dpkg -L vim        # 列出 vim 软件包安装的全部文件
dpkg --search /... # 查看该文件是哪个软件包安装的, 使用绝对路径

du                      # 列出目录大小
du -a                   # 列出目录和文件大小
du -d 1                 # 最大目录深度
du -sh                  # 只列出整体使用大小
du --exclude="*.txt"    # 忽略指定文件, 支持通配符

echo -n "123"                # 不换行
echo -e "\e[1;33m lyb \e[0m" # 文本黄色 加粗

exec ls      # 替换当前 shell, 执行后不再执行之后的命令
exec &>1.txt # 打开文件描述符, 然后继续执行之后的命令
env          # 设置环境变量, 然后执行程序

find . -name  lyb                     # 以文件名查找文件, 不包括路径, 可以使用通配符
find . -iname lyb                     # 同上, 忽略大小写
find . -path   "*/bash/*"             # 以全路径名查找文件, 可包括文件名, 可以使用通配符
find . -ipath  "*/bash/*"             # 同上, 忽略大小写
find . -regex ".*p+"                  # 同上, 使用正则表达式
find . -iregex ".*p+"                 # 同上, 忽略大小写
find . -maxdepth 5 –mindepth 2 -name lyb # 使用目录深度过滤
find . -L -name lyb                   # 是否跟着符号链接跳
find . -type  f                       # 以类型查找文件
find . -type f -atime -7              #     7天内访问过的文件
find . -type f -mtime  7              # 恰好7天前修改过的文件
find . -type f -ctime +7              #     7天前变化过的文件
find . -type f -newer file.txt        # 查找修改时间比 file.txt 新的文件
find . -type f -size +2G              # 以文件大小查找
find . -type f -perm 644              # 以权限查找
find . -type f -user lyb              # 以用户查找
find . -name '.git' -prune -o -type f # -prune 将前面匹配到的文件 或 目录 忽略掉
find . ! -type f -o   -name lyb       # ! 只否定最近的条件
find . \( -type f -and -name lyb \)   # 且, 多个条件必须同时成立
find . \( -type f -a   -name lyb \)   # 同上
find .    -type f      -name lyb      # 同上, 默认多个条件同时成立
find . \( -type f -or  -name lyb \)   # 或, 多个条件成立一个即可
find . \( -type f -o   -name lyb \)   # 同上

firewall-cmd --list-ports                       # 查看所有打开的端口
firewall-cmd --list-services                    # 查看所有打开的服务
firewall-cmd --get-services                     # 查看所有的服务
firewall-cmd --reload                           # 重新加载配置
firewall-cmd --complete-reload                  # 重启服务
firewall-cmd             --add-service=http     # 添加服务
firewall-cmd --permanent --add-service=http     # 添加服务, 永久生效, 需要重新加载配置
firewall-cmd             --remove-service=http  # 移除服务
firewall-cmd             --add-port=80/tcp      # 添加端口
firewall-cmd --permanent --add-port=80/tcp      # 添加端口, 永久生效, 需要重新加载配置
firewall-cmd             --remove-port=80/tcp   # 移除端口
firewall-cmd             --query-masquerade     # 检查是否允许伪装IP
firewall-cmd               --add-masquerade     # 允许防火墙伪装IP
firewall-cmd --permanent   --add-masquerade     # 允许防火墙伪装IP, 永久生效, 需要重新加载配置
firewall-cmd            --remove-masquerade     # 禁止防火墙伪装IP
firewall-cmd --add-forward-port=proto=80:proto=tcp:toaddr=192.168.0.1:toport=8080
                                                # 端口转发, 0.0.0.0:80 --> 192.168.0.1:8080
firewall-cmd --add-forward-port=proto=80:proto=tcp:toaddr=192.168.0.1:toport=8080 --permanent
                                                # 端口转发, 永久生效, 需要重新加载配置
firewall-cmd --runtime-to-permanent             # 将当前防火墙的规则永久保存

flock    1.c ls # 设置文件互斥锁 执行命令, 设置锁失败, 等待
flock -n 1.c ls # 设置文件互斥锁 执行命令, 设置锁失败, 退出

脚本内使用, 保证脚本最多执行一次
[[ "$FLOCKER" != "$0" ]] && exec env FLOCKER="$0" flock -en "$0" "$0" "$@" || :

解释:
1. 第一次进入脚本, 由于变量未设置, 会执行 exec
2. 调用 exec, 使用 env 设置 变量名
3. 执行 flock, 重新执行这个脚本, 执行完脚本后会退出, 不会执行之后的命令
    * 使用脚本名作为 文件锁, 脚本名使用绝对路径, 所以不会重复
4. 第二次进入脚本, 由于变量已设置, 直接往下执行就可以了
5. 在此期间, 如果, 有其他脚本进入, 文件锁获取失败, 就直接退出了

getconf NAME_MAX /
getconf PATH_MAX /

g++ -0g main.cc
g++ -01 main.cc
g++ -02 main.cc
g++ -03 main.cc
g++ main.cc -g     # 生成 gdb 的文件

gdb [a.out] [pid]         # 启动 gdb
gdb> file a.out           # 设置可执行文件
gdb> r   [arguments]      # 运行程序
gdb> attach pid           # gdb 正在运行的程序
gdb> info breakpoints     # 列出断点信息
gdb> b file:line          # 在指定行设置断点
gdb> b function           # 在制定函数设置断点
gdb> b function if b==0   # 根据条件设置断点
gdb> disable [num]        # 忽略断点 num
gdb>  enable [num]        # 使断点 num 生效
gdb>  delete [num]        # 删除断点 num
gdb> clear   line         # 清除指定行的断点
gdb> c       [num]        # 继续运行到指定断点
gdb> u       line         # 运行到指定行
gdb> n       [num]        # 继续运行多次
gdb> s                    # 进入函数
gdb> finish               # 退出函数
gdb> p v                  # 输出变量的值
gdb> p *pointer           # 输出指针指向的值
gdb> p/x var              # 按十六进制格式显示变量。
gdb> p/d var              # 按十进制格式显示变量。
gdb> p/u var              # 按十六进制格式显示无符号整型。
gdb> p/o var              # 按八进制格式显示变量。
gdb> p/t var              # 按二进制格式显示变量。
gdb> p/a var              # 按十六进制格式显示变量。
gdb> p/c var              # 按字符格式显示变量。
gdb> p/f var              # 按浮点数格式显示变量
gdb> x/8xb &v              # 输出 double 的二进制表示
gdb> x/nfu  v              # n 表示打印多少个内存单元
                           # f 打印格式, x d u o t a c f
                           # u 内存单元, b=1 h=2 w=4 g=8
gdb> l                     # 显示当前行之后的源程序
gdb> l -                   # 显示当前行之前的源程序
gdb> list 2,10             # 显示 2 - 10 行的源程序
gdb>  set listsize 20      # 设置列出源码的行数
gdb> show listsize         # 输出列出源码的行数
gdb> set  print elements 0 # 设置打印变量长度不受限制
gdb> show print elements
gdb> bt                    # 显示堆栈信息
gdb> f     n               # 查看指定层的堆栈信息

getopt  # a  无参数, a: 有参数
        # -- 表示可选参数的终止
        # 会重新排列参数
        # 可以解析 --bug
        # 可以区分无参数, 有参数, 可选参数的情况
        # -kval 可以当作 -k val 处理
        # 参数带空格可能出问题

getopts # -o 短选项, -l 长选项
        # a 无参数, a: 有参数, a:: 参数可选
        #  -- 表示可选参数的终止
        # 不会重排参数
        # 只能解析 -k, -k val, 不能解析 --bug, -kval
        # 只能区分有参数和无参数的情况
        # 参数带空格也能处理

git stash                             # 保存当前状态
git stash pop                         # 恢复保存的状态
git stash list                        # 查看已保存的状态
git push orign feature/test -f        # 强推本地分支
git rebase -i HEAD~6                  # 之后，使用 f 取消掉不需要的内容，合并提交
git rebase orign/develop              # 将 orign/develop 上的内容，变基到 当前分支
git push origin --delete feature/test # 删除远程分支
git blame  main.cc                    # 查看文件每行的最后变更
git log -p main.cc                    # 查看文件内容的变更记录

git config --global core.quotepath false # 引用路径不使用八进制, 中文名不再乱码

git config --global core.autocrlf true  # 提交时: CRLF --> LF, 检出时: LF --> CRLF
git config --global core.autocrlf input # 提交时: CRLF --> LF, 检出时: 不转换
git config --global core.autocrlf false # 提交时: 不转换,      检出时: 不转换

git config --global core.safecrlf true  # 拒绝提交包含混合换行符的文件
git config --global core.safecrlf false # 允许提交包含混合换行符的文件
git config --global core.safecrlf warn  # 提交包含混合换行符的文件时给出警告

grep -v                   # 输出不匹配的内容
grep -c                   # 输出匹配的行的次数, 同一行只输出一次
grep -o                   # 只输出匹配的内容
grep -n                   # 输出匹配的行号
grep -l                   # 输出匹配的文件
grep -f                   # 从文件中读取匹配模式
grep -i                   # 忽略大小写
grep -h                   # 不输出文件名
grep -q                   # 静默输出
grep -A 5                 # 输出之前的行
grep -B 5                 # 输出之后的行
grep -C 5                 # 输出之前之后的行
grep -e .. -e ..          # 多个模式取或
grep -E ..                # 使用扩展的正则表达式, 同 egrep
grep -W ..                # 单词匹配
grep -X ..                # 行匹配
grep ... --inclue "*.c"   # 指定文件
grep ... --exclue "*.c"   # 忽略文件
grep ... --exclue-dir src # 忽略目录

groupadd               # 添加组
groupdel               # 删除组
groupdel               # 修改组
groups                 # 查看所属的组

hd            1.c # 每组一个字节, 显示十六进制
hexdump -C    1.c # 每组一个字节, 显示十六进制
hexdump -c    1.c # 每组一个字节, 显示字符

history

iconv

IFS 默认值: " \t\n"
IFS 包含转义字符时, 需要在开头添加 $, IFS=$'\n'

ip addr
ip route

jobs          # 列出后台作业
jobs %jobspec # 作业号有无 % 都成
jobs -l       #   列出后台作业的 PID
jobs -p       # 只列出后台作业的 PID
jobs -n       # 只列出进程改变的作业
jobs -s       # 只列出停止的作业
jobs -r       # 只列出运行中的作业
              #
kill    %jobspec # 杀死作业
kill    PID      # 杀死进程
killall vim      # 进程名称

less
空格   : 下一页
ctrl+F : 下一页
b      : 上一页
ctrl+b : 上一页
回车   : 下一行
=      : 当前行号
y      : 上一行

ln -s target symbolic_link_name # 创建符号链接

ls -a        # 列出当前目录中的元素, 包括隐藏的文件
ls -S        # 使用 文件大小 排序, 大 --> 小
ls -v        # 使用 版本号 排序
ls -X        # 使用 扩展名 排序
ls -d        # 只列出目录本身，而不列出目录内元素
ls -l        # 列出当前目录中的元素的详细信息
ls -h        # 使用人类可读的形式
ls -F        # 在目录后添加 /，在可执行文件后添加 *
ls -r        # 逆序
ls -R        # 递归
ls -1        # 在每一行列出文件名
ls -L        # 符号链接所指向的文件, 而不是符号链接本身
ls -I "*.sh" # 忽略文件, 使用通配符
ls -clt      # 使用 ctime 排序和展示, 新 -> 旧
ls -tl       # 使用 mtime 排序和展示, 新 -> 旧
ls -ult      # 使用 atime 排序和展示, 新 -> 旧

                   # lsof -- sudo yum install lsof
lsof -iTCP         # 查看 TCP 信息
lsof -i :22        # 查看指定 端口号 的信息
lsof -i@1.2.3.4:22 # 查看是否连接到指定 IP 和 端口号上
lsof -p 1234       # 指定 进程号
lsof -d 0,1,2,3    # 指定 文件描述符
lsof -t            # 仅获取进程ID
lsof -a            # 参数取且

md5sum 1.txt # MD5 检验

mkdir    abc   # 创建目录
mkdir -p a/b/c # 递归创建目录, 目录已存在时不报错

mktemp         # 临时文件
mktemp -d      # 临时目录

## more
空格   : 下一页
ctrl+F : 下一页
b      : 上一页
ctrl+b : 上一页
回车   : 下一行
=      : 当前行号

mv a b # a 是符号链接时, 将使用符号链接本身
       # b 是指向目录  的符号链接时， 相当于 移到 b 本身
       # b 是指向目录  的符号链接时， 相当于 移到 b 最终所指向的目录下
       # b 是指向不存在的符号链接时， 相当于 重命名

nohup sleep 1000 & # 脱离终端, 在后台运行

ntpdate -s time-b.nist.gov # 使用时间服务器更新时间

patch     1.txt diff.pathc  # 恢复文件
patch -p1 1.txt diff.pathc  # 恢复文件, 忽略 diff.pathc 的第一个路径

passwd lyb # 修改密码

readlink    1.c.link  # 读取符号链接
readlink -f 1.c.link  # 读取符号链接, 递归

read name     # 读取, 如果参数值小于字段数, 多余的值放入最后一个字段

rm -r  a    # 递归删除
rm -rf a    # 强行删除, 文件不存在时, 忽略

od -Ax  -tx1z 1.c # 每组一个字节, 显示十六进制
od      -c    1.c # 每组一个字节, 显示字符

pgrep vim          # 列出 vim 的进程号
                   # 使用前缀匹配
                   # 使用扩展的正则表达式
                   # 进程名称只能使用前 15 位
pgrep -a           # 列出进程号和完整的进程名称
pgrep -c           # 列出进程数目
pgrep -l           # 列出进程号和进程名称
pgrep -u lyb       # 有效用户ID
pgrep -U lyb       # 实际用户ID

pkill    vim       # 杀死进程
pkill -9 vim       # 发送指定信号
                   # 其他参数同 pgrep

ps -ef             # 显示所有进程
ps -o pid,command  # 只显示进程 ID 和进程名称
ps -o fuser=       # 只显示实际用户
ps -o euser=       # 只显示有效用户
ps -o lstart,etime # 只显示启动时间, 耗时
ps -p 123          #   显示指定进程的信息
ps -u lyb          # 有效用户为 lyb 的进程
ps -U lyb          # 实际用户为 lyb 的进程
ps -ww             # 不限制输出宽度
                   # 显示完整进程名称

pwdx pid...        # 列出进程的当前工作目录

redis flushdb

rz          #  windows 向 虚拟机  发送数据

sed # 读取一行到模式空间 --> 执行操作 -- 循环
    # n 读取下一行到模式空间 N 将下一行添加到模式空间内容后
    # d 删除模式空间的内容   D 删除模式空间的第一行内容, 之后跳到开头
    # p 打印模式空间的内容   P 打印模式空间的第一行内容
    # h 将模式空间复制到保持空间
    # H 将模式空间附加到保持空间
    # g 将保持空间复制到模式空间
    # G 将保持空间附加到模式空间
    # x 交换模式空间和保持空间的内容
    # :abc 定义标签
    # b abc 跳到指定标签
    # t abc 前一个命令成功会跳转

sed  -e "p" -e "d"   1.txt # 指定多个命令
sed  -f 1.sed        1.txt # 从文件读取命令
sed  -n "1p"         1.txt #   打印第一行
sed  -n "1!p"        1.txt # 不打印第一行
sed  -n "1,5p"       1.txt #   打印 [1,5] 行
sed  -n "1,+4p"      1.txt #   使用相对位置
sed  -n "1,$p"       1.txt #   打印整个文件
sed  -n "p"          1.txt #   打印整个文件
sed  -n "/1/p"       1.txt #   打印 包含 1 的行
sed  -n "/1/,/2/p"   1.txt #   打印 [包含1, 包含2] 的行
                           #   包含1 和 包含2 的不能是同一行
sed  -n "/1/,+1p"    1.txt #   使用相对位置
sed -rn "/1+/p"  <<< "111" #   使用扩展的正则表达式
                           #   默认使用基础的正则表达式
sed  -n "/1/,+1p"    1.txt #   使用相对位置

sed  -n  "=;p"       1.txt # 输出行号

sed     "1l"         1.txt # 打印不可打印字符
sed     "1r1.c"      1.txt # 第一行后插入文件的内容
sed     "1w1.c"      1.txt # 第一行行保存到文件

sed     "1a..."      1.txt # 行后插入
sed     "1i..."      1.txt # 行前插入
sed     "1c..."      1.txt # 行替换
sed     "1d"         1.txt # 行删除

sed     "s/123/456/"   1.txt # 替换第一处
sed     "s/123/456/2"  1.txt # 替换第二处
sed     "s/123/456/2g" 1.txt # 替换第二处及以后
sed     "s/123/456/g"  1.txt # 替换所有
sed -i  "s/123/456/g"  1.txt # 直接在原文件上修改
sed -i  "s|123|456|g"  1.txt # 使用不同的分割符
sed -i  "s/.*/[&]/g"   1.txt # & 用于表示所匹配到的内容
sed -ir "s/(1)/[\1]/g" 1.txt # \1 表示第一个字串

sed     "y/123/456/"   1.txt # 字符替换

set -o nounset  # 使用未初始化的变量报错, 同 -u
set -o errexit  # 只要发生错误就退出, 同 -e
set -o pipefail # 只要管道发生错误就退出
set -o errtrace # 函数报错时, 也处理 trap ERR, 同 set -E
set -o  xtrace  # 执行前打印命令, 同 -x
set -o verbose  # 读取前打印命令, 同 -v
set -o vi       # 使用 vi 快捷键
set -- ....     # 重新排列参数

sleep 30   # 前台运行
sleep 30 & # 后台运行

sort            # 排序
sort -b         # 忽略前置空白
sort -c         # 检查是否已排序
sort -d         # 字典序排序
sort -f         # 忽略大小写
sort -k 4       # 指定排序的列字段
sort -k 4.1,4.2 # 指定排序的列字段
sort -h         # 以 K, M, G 排序
sort -i         # 忽略不可打印字符
sort -m         # 合并排序过的文件
sort -n         # 以数字进行排序
sort -r         # 逆序
sort -t :       # 指定列的分割符
sort -u         # 重复项只输出一次
sort -V         # 以版本号排序
sort lyb -o lyb # 排序并存入原文件

ss -ntp | grep 9100

ssh -N -D A_PORT B_IP
            # 功能:
            #   动态端口转发
            #   将本地到 A_PORT 的请求转发到 B_IP
            #   使用 SOCKS5 协议
ssh -N -L A_PORT:C_IP:C_PORT B_IP
            # 功能:
            #   本地端口转发
            # 目标:
            #    A_IP:A_PORT --> C_IP:C_PORT
            # 现状:
            #    A_IP --> C_IP 失败
            #    B_IP --> C_IP 成功
            #    A_IP --> B_IP 成功
            #    B_IP --> A_IP 成功 或 失败都行
            # 实现:
            #   * 在 A_IP 机器上执行: ssh -N -L A_PORT:C_IP:C_PORT B_IP
            #   * 发往 A_IP 机器的端口号 A_PORT 的请求, 经由 B_IP 机器, 转发到 C_IP 机器的 C_PORT 端口
            #   * 即: A_IP:A_PORT --> B_IP --> C_IP:C_PORT
ssh -N -R A_PORT:C_IP:C_PORT A_IP
            # 功能:
            #   远程端口转发
            # 目标:
            #    A_IP:A_PORT --> C_IP:C_PORT
            # 现状:
            #    A_IP --> C_IP 失败
            #    B_IP --> C_IP 成功
            #    A_IP --> B_IP 成功 或 失败都行
            #    B_IP --> A_IP 成功
            # 实现:
            #   * 在 B_IP 机器上执行: ssh -N -R A_PORT:C_IP:C_PORT A_IP
            #   * 发往 A_IP 机器的端口号 A_PORT 的请求, 经由 B_IP 机器, 转发到 C_IP 机器的 C_PORT 端口
            #   * 即: A_IP:A_PORT --> B_IP --> C_IP:C_PORT
            #   * 如果要支持其他主机通过 A_IP 访问 C_IP, 需要在 A_IP 的 ssh 配置 GatewayPorts
ssh -N             # 不登录 shell, 只用于端口转发
ssh -p port        # 指定服务器端口号
ssh -f             # 在后台运行
ssh -t             # 开启交互式 shell
ssh -C             # 压缩数据
ssh -F             # 指定配置文件
ssh -q             # 不输出任何警告信息
ssh -l lyb 1.2.3.4
ssh        1.2.3.4
ssh    lyb@1.2.3.4
ssh -i ~/.ssh/id_rsa lyb # 指定私钥文件名

ssh-keygen -t rsa              # 指定密钥算法, 默认就是 rsa
ssh-keygen -b 1024             # 指定密钥的二进制位数
ssh-keygen -C username@host    # 指定注释
ssh-keygen -f lyb              # 指定密钥的文件
ssh-keygen -R username@host    # 将 username@host 的公钥移出 known_hosts 文件

ssh-copy-id -i ~/id_rsa username@host # 添加公钥到服务器中的 ~/.ssh/authorized_keys
                                      # -i 未指定时, 将使用 ~/.ssh/id_rsa.pub

#### ssh 客户端的常见配置: ~/.ssh/config, /etc/ssh/ssh_config, man ssh_config
Host *                          # 对所有机器都生效, 使用 通配符, 配置直到下一个 host
Host 123                        # 可以起一个别名
HostName 1.2.3.4                # 远程主机
Port 2222                       # 远程端口号
BindAddress 192.168.10.235      # 本地 IP
User lyb                        # 用户名
IdentityFile ~/.ssh/id.rsa      # 密钥文件
                                # 此时, 使用 ssh 123 相当于使用 ssh -p 2222 lyb@1.2.3.4
DynamicForward 1080             # 指定动态转发端口
LocalForward  1234 1.2.3.4:5678 # 指定本地端口转发
RemoteForward 1234 1.2.3.4:5678 # 指定远程端口转发

#### ssh 服务端的常见配置: /etc/ssh/sshd_config, man sshd_config
AllowTcpForwarding yes     # 是否允许端口转发, 默认允许
ListenAddress 1.2.3.4      # 监听地址
PasswordAuthentication     # 指定是否允许密码登录，默认值为 yes
Port 22                    # 监听端口号
GatewayPorts no            # 远程转发时, 是否允许其他主机使改端口号, 默认不允许

stat    1.c # 列出 birth atime mtime ctime
stat -L 1.c # 符号链接所指向的文件, 而不是符号链接本身

sudo                                          # 权限管理文件: /etc/sudoers, 使用 visudo 编辑
                                              # 使用当前用户的密码
sudo -u USERNAME COMMAND                      # 指定用户执行命令
sudo -S date -s "20210722 10:10:10" <<< "123" # 脚本中免密码使用

su         # 切换 root, 输入 root 密码
su -       # 切换 root, 更新主目录, 环境变量等等
su - -c ls # 使用 root 执行命令 ls

systemctl start      nginx   # 启动 nginx
systemctl stop       nginx   # 停止 nginx
systemctl restart    nginx   # 重启 nginx
systemctl status     nginx   # 查看 nginx 状态
systemctl enable     nginx   # 开机自动启动 nginx
systemctl disable    nginx   # 开机禁止启动 nginx
systemctl is-active  nginx   # 查看 nginx 是否启动成功
systemctl is-failed  nginx   # 查看 nginx 是否启动失败
systemctl is-enabled nginx   # 查看 nginx 是否开机启动

sz          #  虚拟机  向 windows 发送数据

tail -f * # 动态查看新增内容

tar acf 1.tgz --exclude="*.o" 12 # 根据后缀压缩, 忽略指定文件
tar acf 1.tgz -X 1.c          12 # 根据后缀压缩, 忽略 1.c 内的文件
tar xvf 1.tgz -C                 # 根据后缀解压, 显示解压过程
tar xf  1.tgz -C /home/          # 根据后缀解压, 解压到指定目录
tar tf a.tgz                     # 列出压缩包中的文件和目录

tee    1.txt # 管道中把文件拷贝到文件
tee -a 1.txt # 管道中把文件添加到文件

top        # 使用 CPU 排序 -- TODO
top -u lyb # M 内存排序
           # P CPU 排序
           # T 时间排序
           # m 显示内存信息
           # t 显示进程 或 CPU状态信息
           # c 显示命令名称 或 完整命令行

touch        1.c # 修改 atime mtime ctime
touch -a     1.c # 修改 atime
touch -m     1.c # 修改       mtime ctime
touch -c     1.c # 文件不存在时, 不创建文件
touch -h     1.c # 改变符号链接本身, 而不是所指向的文件
touch -r 2.c 1.c # 以 2.c 的时间修改 1.c
touch -d ... 1.c # 指定时间, 格式同 date
touch -t ... 1.c # 指定时间
                 # 依次是: 时区-年-月-日-时-分-秒

trap ... ERR  # 发生错误退出时, 执行指定命令
trap ... EXIT # 任意情况退出时, 执行指定命令

tree -p "*.cc"       # 只显示  匹配到的文件
tree -I "*.cc"       # 只显示没匹配到的文件
tree -H . -o 1.html  # 指定目录生成 html 文件

tr    'a-z' 'A-Z' # 小写转大写
tr -d 'a-z'       # 删除字符
tr -s ' '         # 压缩字符

uniq    # 删除重复的行
uniq -c # 输出统计的次数
uniq -d # 只输出重复的行, 重复的项只输出一次
uniq -D # 只输出重复的行, 重复的项只输出多次
uniq -i # 忽略大小写
uniq -u # 只输出没重复的行

unix2doc 1.txt # \n --> \r\n

unzip -l a.zip # 列出 zip 的内容
unzip -j a.zip # 解压时, 不要路径

useradd               # 添加用户
userdel               # 删除用户
usermod               # 修改用户
usermod    -g lyb kds # 将 kds 的主组变为 lyb
usermod    -G lyb kds # 将 kds 的附组变为 lyb
usermod -a -G lyb kds # 将 kds 的附组添加 lyb

vim
Ctrl+F 下翻一屏
Ctrl+B 上翻一屏

#### 普通模式
h      # 左移一个字符
j      # 下移一行
k      # 上移一行
l      # 右移一个字符

x      # 删除当前光标所在位置的字符
dl     # 删除当前光标所在位置的字符
dw     # 删除当前光标所在位置到单词末尾的字符
daw    # 删除当前光标所在位置的单词
d2w    # 删除当前光标所在位置之后的两个单词
2dw    # 删除当前光标所在位置之后的两个单词
dd     # 删除当前光标所在行
5dd    # 删除当前光标所在行开始的五行
dap    # 删除当前光标所在段落
d$     # 删除当前光标所在位置至行尾的内容
d^     # 删除当前光标所在位置至行头的内容

J      # 删除光标所在行尾的换行符
u      # 撤销上一命令
a      # 在光标后追加数据
A      # 在光标所在行尾追加数据
r char # 使用 char 替换光标所在位置的单个字符
R text # 进入替换模式，直到按下ESC键
i      # 在当前光标后插入数据
I      # 在当前光标所在行行头插入数据

cl
cw
cap    # 删除内容并进入插入模式

yy     # 复制当前行
5y     # 复制包含当前行在内的 5 行

G      # 移到最后一行
gg     # 移到第一行
num gg # 移到第 num 行

/  #         向后查找指定字符串, n 查找下一个, N 查找上一个
?  #         向前查找指定字符串, n 查找上一个, N 查找下一个
f  # 在当前行向后查找指定字符  , ; 查找下一个, , 查找上一个
F  # 在当前行向前查找指定字符  , ; 查找上一个, , 查找下一个
t  # 在当前行向后查找指定字符  , ; 查找下一个, , 查找上一个, 光标将停在找到字符的前一个上
T  # 在当前行向前查找指定字符  , ; 查找上一个, , 查找下一个, 光标将停在找到字符的前一个上

Esc -- Ctrl+[ # 回到 普通模式

#### 插入模式

#### 普通-插入模式

例如: Ctrl+Ozz, 将当前行置于屏幕中间

1. 使用 Ctrl+O 进入普通模式
2. 执行命令 zz
3. 回到插入模式

#### 命令模式
:s/old/new/     # 替换光标所在行第一个的 old
:s/old/new/2g   # 替换光标所在行第二个以及之后的 old
:s/old/new/g    # 替换光标所在行所有的 old
:n,ms/old/new/g # 替换行号n和m之间所有的 old
:%s/old/new/g   # 替换整个文件中的所有的 old
:%s/old/new/gc  # 替换整个文件中的所有 old，但在每次出现时提示
:s/^old/new/    # 替换光标所在行的以 old 打头的
:s/old$/new/    # 替换光标所在行的以 old 结尾的
:s/^$//         # 删除空行

:q          #     退出
:q!         # 强制退出
:w filename # 保存为指定文件
:wq         # 保存并退出

:!ls        # 执行外部命令
:r !ls      # 将外部命令的执行结果插入到下一行
:1,5w !ls   # 将指定行作为命令的输入
:1,5  !ls   # 将指定行作为命令的输入, 删除这些行, 然后将外部命令的插入到这些行

:set nohlsearch # 去掉高亮

wc    # 输出 换行符数 字符串数 字节数
wc -l #   行数
wc -w # 字符串数
wc -c # 字节数
wc -m # 字符数

cat lyb | xargs -i vim {} # 以此编辑 lyb 中的每一个文件

xxd -g1 1.c # 每组一个字节, 显示十六进制
xxd -b  1.c # 每组一个字节, 显示  二进制

yum list installed       # 列出已安装的软件
yum list vim             # 列出某软件包的详细信息
yum list updates         # 列出可用更新
yum provides file_name   # 查看文件属于哪个软件包
yum update package_name  # 更新某个软件包
yum update               # 更新所有软件包
yum install package_name # 安装软件
yum remove  package_name # 卸载软件
yum erase   package_name # 卸载软件，删除数据和文件
yum provides /etc/vimrc  # 查看文件由哪个软件使用
yum repolist             # 列出使用的软件源

Esc+B              # 移动到当前单词的开头(左边)
Esc+F              # 移动到当前单词的结尾(右边)

Alt+B              # 向后（左边）移动一个单词
Alt+d              # 删除光标后（右边）一个单词
Alt+F              # 向前（右边）移动一个单词
Alt+t              # 交换字符 ?
Alt+BACKSPACE      # 删除光标前面一个单词，类似 Ctrl+W，但不影响剪贴板
Ctrl+X Ctrl+X      # 连续按两次 Ctrl+X，光标在当前位置和行首来回跳转
Ctrl+X Ctrl+E      # 用你指定的编辑器，编辑当前命令
Ctrl+insert        # 复制命令行内容
shift+insert       # 粘贴命令行内容

Esc+.              # 获取上一条命令的最后的部分
