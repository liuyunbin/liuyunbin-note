# 编译
```
./tool.sh install_dependency
./tool.sh build
```

# 目录
* [计算机操作系统](#计算机操作系统)
    * [信号管理](#信号管理)
        * [信号基础](#信号基础)
        * [常见信号](#常见信号)
        * [相关函数](#相关函数)
    * [进程管理](#进程管理)
        * [进程](#进程)
        * [会话](#会话)
        * [控制终端](#控制终端)
        * [守护进程](#守护进程)
        * [进程间通信](#进程间通信)
    * [文件管理](#文件管理)
    * [IO管理](#IO管理)
* [计算机组成原理](#计算机组成原理)
* [计算机网络](#计算机网络)
* [常用命令](#常用命令)

# 计算机操作系统
## 信号管理
### 信号基础
* 信号产生
    * 终端相关(由 0 号进程发送)
    * 硬件异常
    * 资源就绪或资源受限(由 0 号进程发送)
    * 自身或其他进程发送
* 信号-阻塞
    * `SIGKILL` 和 `SIGSTOP` 无法被阻塞
    * `SIGCONT` 可以被阻塞, 但好像没啥用
* 信号-优先级
    * 有多个信号处于未决状态(信号发送后, 处理前)时, 进程处理的顺序
    * 04-SIGILL
    * 05-SIGTRAP
    * 07-SIGBUS
    * 08-SIGFPE
    * 11-SIGSEGV
    * 31-SIGSYS
    * 其他信号按数字的从小到大顺序处理
* 信号-不可靠
    * 相同的信号处于待决状态时, 只记录一个, 其他信号会丢失
    * 信号处理后, 信号处理函数可能会被重置
* 信号-信号处理
    * 忽略信号
    * 默认处理(忽略, 退出, 退出产生core, 暂停, 继续)
    * 捕获信号
        * 信号处理过程中, 相同的信号来了会被阻塞, 此时, 如果再来相同的信号将被抛弃
        * 信号处理过程中, 不同的信号来了会被直接执行, 执行完之后, 再继续执行之前的信号处理
        * 使用 sigaction() 可以选择信号处理时阻塞的信号集
* 慢系统调用: 被信号中断时, 需要重新启动
* 不可重入函数: 需要阻塞某些信号

### 常见信号
|  信号      |处理|类型    |说明                                               |
|------------|----|--------|---------------------------------------------------|
| 1-SIGHUP   |term|终端    |发送给会话首进程(终端断开)                         |
|            |    |        |发送给其所有作业(会话首进程退出)                   |
|            |    |        |发送给守护进程(重新读取其配置文件)                 |
| 2-SIGINT   |term|终端    |键盘中断, 由 ctrl+c 产生                           |
| 3-SIGQUIT  |core|终端    |键盘退出, 由 ctrl+\ 产生                           |
| 4-SIGILL   |core|硬件故障|非法的硬件指令                                     |
| 5-SIGTRAP  |core|硬件故障|硬件故障                                           |
| 6-SIGABRT  |core|程序异常|异常终止, 由 abort() 产生                          |
|            |    |        |只有捕获信号且不从信号处理函数返回, 进程才不会退出 |
|            |    |        |默认处理将刷新标准IO                               |
| 7-SIGBUS   |core|硬件故障|硬件故障, 内存故障                                 |
| 8-SIGFPE   |core|程序异常|算术异常, 比如除以0                                |
|            |    |        |只有捕获信号且不从信号处理函数返回                 |
|            |    |        |    否则将反复触发此信号或退出                     |
| 9-SIGKILL  |term|进程控制|退出, 不能被阻塞, 捕获, 忽略                       |
|10-SIGUSR1  |term|自定义  |用户自定义信号                                     |
|11-SIGSEGV  |core|程序异常|无效内存引用, 比如访问未初始化的指针               |
|12-SIGUSR2  |term|自定义  |用户自定义信号                                     |
|13-SIGPIPE  |term|资源受限|写文件描述符时, 对方已退出, 比如 socket, 管道      |
|14-SIGALRM  |term|资源就绪|定时器超时, 由 alarm() 或 setitimer() 产生         |
|15-SIGTERM  |term|进程控制|退出信号, kill 默认信号                            |
|16-SIGSTKFLT|term|未使用  |栈错误, 未使用                                     |
|17-SIGCHLD  |ign |进程控制|子进程暂停或继续或退出时, 会向父进程发送此信号     |
|18-SIGCONT  |cont|进程控制|继续, 待决的暂停信号将被丢弃, 此信号阻塞没用       |
|19-SIGSTOP  |stop|进程控制|暂停, 不能被阻塞 捕获 忽略, 待决的继续信号将被丢弃 |
|20-SIGTSTP  |stop|终端    |暂停, 由 ctrl+z 产生, 待决的继续信号将被丢弃       |
|21-SIGTTIN  |stop|终端    |后台进程读取终端输入, 待决的继续信号将被丢弃       |
|22-SIGTTOU  |stop|终端    |后台进程输出到终端, 待决的继续信号将被丢弃         |
|23-SIGURG   |ign |资源就绪|带外数据就绪                                       |
|24-SIGXCPU  |core|资源受限|cpu 使用超出限制                                   |
|25-SIGXFSZ  |core|资源受限|文件大小超出限制                                   |
|26-SIGVTALRM|term|资源就绪|setitimer() 产生的虚拟的超时信号                   |
|27-SIGPROF  |term|资源就绪|setitimer() 产生的虚拟的超时信号                   |
|28-SIGWINCH |ign |终端    |终端大小发生变化                                   |
|29-SIGIO    |term|资源就绪|异步IO就绪                                         |
|30-SIGPWR   |term|硬件故障|电池问题                                           |
|31-SIGSYS   |core|硬件故障|非法的系统调用                                     |

### 相关函数
|函数           |说明                                                       |
|---------------|-----------------------------------------------------------|
| abort()       | 解锁信号 SIGABRT, 然后向自身发送 SIGABRT                  |
| alarm()       | 指定时间后, 收到信号 SIGALRM                              |
|               | 如果以前未设置且此次参数不为0                             |
|               |     设置为新值, 返回 0                                    |
|               | 如果以前已设置且此次参数不为0                             |
|               |     设置为新值, 返回上一次的剩余的时间                    |
|               | 如果以前已设置且此次参数为0                               |
|               |     取消上一次的设置的值, 并返回上一次剩余的时间          |
| exec()        | 设置捕获的信号处理函数恢复为默认处理                      |
| fork()        | 信号处理函数也被复制, 信号处理不变                        |
| kill()        | 发送信号, 向某一进程 或 进程组                            |
|               | root 可以向任何进程发送                                   |
|               | 其他用户需要与目标进程的实际或有效用户相同                |
| pause()       | 休眠, 直到不被忽略的信号发生                              |
| raise()       | 向自己发送信号                                            |
| sleep()       | 休眠n秒, 或者一个未被忽略的信号到达                       |
| signal()      | 设置信号处理函数                                          |
|               | 信号处理函数不会被重置                                    |
|               | 被中断系统调用会自动重启                                  |
|               | 信号处理时, 自身会被阻塞, 其他信号不会                    |
| sigaction()   | 设置信号处理函数                                          |
|               | 可以选择是否自动重启被中断的系统调用                      |
|               | 可以选择第一次调用以后, 信号处理函数是否恢复成默认处理    |
|               | 可以选择信号处理过程中, 是否阻塞自身或指定信号集          |
|               | 可以指明对子进程状态变化的处理                            |
|               | 可以获取到发送信号一端的一些信息                          |
| sigemptyset() | 将信号集置空                                              |
| sigfillset()  | 填充所有信号                                              |
| sigaddset()   | 添加信号到信号集                                          |
| sigdelset()   | 从信号集删除信号                                          |
| sigismember() | 判断信号是否处于信号集                                    |
| sigprocmask() | 阻塞 或 解阻塞 或 查看信号                                |
| sigpending()  | 查看处于待决状态的信号                                    |
| sigsetjmp()   | 跨函数跳转, 自动恢复信号                                  |
| siglongjmp()  | 跨函数跳转, 自动恢复信号                                  |
| sigsuspend()  | 解阻塞一些信号, 然后等待, 原子操作                        |
|               |                                                           |
| system()      | 1. 阻塞 SIGCHLD, 否则无法知道是不是自己创建的子进程退出了 |
|               | 2. 忽略 SIGINT 和 SIGQUIT                                 |
|               | 3. 子进程恢复 SIGINT 和 SIGQUIT 的处理                    |
|               | 4. 父进程 waitpid() 子程序                                |
|               | 5. 父进程恢复 SIGCHLD SIGINT 和 SIGQUIT 的处理            |

## 进程管理
### 进程
* 存储布局
    * 正文段(text):
        * 存储程序本身, 只读, 可共享
        * 内存中只存储一份, 磁盘中需要存储
    * 数据段(data)
        * 存储初始化的全局变量或静态变量
        * 内存中每个进程一份, 磁盘中需要存储
    * bss
        * 存储未初始化的全局变量或静态变量
        * 内存中每个进程一份, 磁盘中不需要存储
        * 程序启动时初始化为 0
    * 栈: 磁盘中不需要存储
    * 堆: 磁盘中不需要存储
        * malloc(): 存储空间分配, 未初始化
        * calloc(): 存储空间分配, 初始化为 0
        * realloc(): 重新存储空间分配
        * free(): 释放内存
    * 使用 size 可以查看各个部分的大小
* 共享库
    * 静态库: 编译到可执行文件
    * 动态库: 启动或运行时, 加载到可执行文件
        * g++ -fPIC -shared test.cc -o libtest.so
* 进程启动
    * fork()
        * 产生子进程, 父子进程使用各自的空间
        * 父子进程的执行顺序不确定
        * 进程数太多或者超出自己的限制会报错
        * 实际用户, 有效用户, 保存的 UID, 进程组, 会话, 信号处理等保持不变
        * 文件锁, 未处理的信号集, 进程时间将被清空
    * vfork()
        * 产生子进程, 父子进程共享空间
        * 子进程退出或调用 exec 前, 父进程处于不可被信号打断的休眠状态
    * exec()
        * 执行命令
        * 实际用户, 实际组不变
        * 设置了用户ID, 有效用户变为文件所有者, 否则不变
* 启动命令:
    * 完整的启动命令, 包括路径和参数
    * 如果是符号链接, 只会记录和展示符号本身
    * /proc/PID/cmdline
* 进程名称:
    * 启动名称去掉路径和参数
    * 查找或输出时, 只会使用前 15 位(一般使用15位足够了)
    * 如果以符号链接启动, 将存储符号链接本身
    * /proc/PID/comm
* 进程状态
    * 就绪
    * 运行(R)
    * 休眠(S)(可被信号打断)(指被捕获的信号)
    * 休眠(D)(不可被信号打断)(指被捕获的信号)
        * SIGSTOP 也会被阻塞
        * SIGKILL 不会被阻塞
    * 暂停(T)(作业控制)
        * 收到信号 SIGSTOP 或 SIGTSTP 或 SIGTTIN 或 SIGTTOT
    * 暂停(t)(由于 DEBUG 产生)
    * 空闲(I): 处于不可被打断的休眠状态时, 有时 CPU 是空闲的
    * 僵尸(Z)
    * 退出(X)
* 进程退出
    * 正常终止
        * main() 返回
        * 调用 exit(): 调用 atexit() 登记的函数, 调用析构函数, 刷新标准IO流, 关闭文件描述符
        * 调用 _exit(): 直接进入内核, 关闭文件描述符
        * 调用 _Exit(): 直接进入内核, 关闭文件描述符
        * 最后一个线程返回
        * 最后一个线程调用 pthread_exit()
    * 异常中止
        * 调用 abort(): 默认刷新标准IO流, 关闭文件描述符
        * 收到信号中止
        * 取消最后一个线程
    * 向父进程发送 SIGCHLD, 内核会保存退出状态
* 环境变量
    * getenv(): 获取环境变量
    * putenv(): 设置环境变量
* 跨函数跳转
    * longjmp()
    * setjmp()
* 资源使用的限制
    * getrlimit(): 获取资源使用的限制
    * setrlimit(): 设置资源使用的限制
        * 软限制值可以任意修改, 只要小于等于硬限制值即可
        * 硬限制值可以降低, 只要大于等于软限制值即可
        * 只有超级用户才可以提高硬限制值
    * ulimit -c ------------ 查看 core 文件大小的软限制
    * ulimit -c -H --------- 查看 core 文件大小的硬限制
    * ulimit -c unlimited -- 设置 core 文件大小的软限制不受限制
* core 不能生成的原因
    * 设置了 SUID, 进程的实际用户不是可执行文件的所有者
    * 设置了 SGID, 进程的实际组不是可执行文件组的所有者
    * 没有写当前目录的权限
    * 文件已存在, 但无权限修改
    * 文件太大, 受 ulimit 的限制
* ubuntu 生产 core
    1. ulimit -c unlimited -- 设置 core 文件大小的软限制不受限制
    2. /etc/sysctl.conf 添加 `kernel.core_pattern=%e.%p` -- 文件名, 进程号
    3. sudo sysctl -p -- 配置生效
* 获取子进程的状态变化的信息 -- waitpid(&status)
    * WIFEXITED() -- 正常终止
        * WEXITSTATUS() -- 正常退出的状态
    * WIFSIGNALED() -- 信号导致退出
        * WTERMSIG() --  导致退出的信号
        * WCOREDUMP() -- 导致产生 core 的信号
    * WIFSTOPPED() -- 暂停
        * WSTOPSIG() -- 导致暂停的信号
    * WIFCONTINUED() -- 继续
    * WNOHANG -- 没有子进程退出时, 立刻返回
    * WUNTRACED -- 子进程暂停时, 也检测
    * WCONTINUED -- 子进程继续时, 也检测
* 进程优先级
    * nice() -- 值越小, 优先级越高
* 进程时间 -- time 命令
    * 墙上时钟时间
    * 用户 CPU 时间
    * 相同 CPU 时间
* 进程ID:
    * 无法改变
    * getpid()
* 父进程
    * 一个进程只能属于一个父进程
    * 一个父进程可以有多个子进程
    * getppid()
* getuid()
* geteuid()
* setuid(uid)
    * root 用户:
        * 实际, 有效, 保存的用户ID 都改成 uid
    * 普通用户:
        * 如果 uid == 实际ID 或 保存的用户ID, 则, 将有效的用户ID 改为 uid
* setreuid(): 设置实际和有效用户ID
* seteuid(): 设置有效用户ID
* 解释器文件
    * 第一行以 `#!` 开头
    * 等价于: 解释器文件第一行(不包括 #!) + 解释器文件 + 其他参数
* 系统文件
    * /proc/loadavg: 系统负载
    * /proc/cpuinfo: cpu 信息
    * /proc/uptime: 运行时间
    * /proc/PID/cwd: 进程当前的目录
    * /proc/PID/exe: 符号链接, 指向运行的进程
    * /proc/PID/environ: 进程使用的环境变量
    * /proc/PID/fd: 进程所打开的文件描述符
    * /proc/PID/limits: 进程对各种资源的限制
    * /proc/PID/task: 进程使用的线程情况

### 会话
* 一个进程组只能属于一个会话
* 一个会话能有多个进程组
* 一个会话最多和一个终端绑定
* getsid(): 获取会话ID
* setsid(): 新建会话ID
    * 新的会话ID是当前进程的ID, 新的进程组ID也是当前进程的ID
    * 新会话和新进程组里将只包含当前进程
    * 新的会话将脱离终端的控制
    * 当前进程是进程组的首进程时, 不能新建会话, 避免出现同一进程组的进程属于不同的会话的情况
    * 当前进程不能是进程组的首进程时, 可以新建会话
* 销毁(会话不和终端绑定): 会话首进程退出时, 不会对会话内的其他进程有影响

### 控制终端
* 用户登录时, 系统将一个会话与终端绑定, 此会话进程即为控制进程
* 终端退出时
    * 控制进程: 内核将发送的信号 SIGHUP
    * 前台进程组: 控制进程(bash)将发送 SIGHUP, 如果进程没有退出, 内核将发送 SIGCONT
    * 后台进程组(暂停):  控制进程(Bash)将发送 SIGCONT SIGTERM SIGHUP
    * 后台进程组(运行):  控制进程(Bash)将发送 SIGHUP
* 此会话有且只有一个前台进程组, 有零个或多个后台进程组
* 终端的输入将发送到前台进程组, 前台和后台进程组的输出都将发送到终端
* 新建会话可以脱离终端
* 脱离终端的进程的父进程不一定是 1, 也可能是其他脱离终端的进程
* 脱离终端可以忽略 SIGHUP 或 新建会话
* tcgetpgrp() -- 查看当前会话所关联的控制终端的前台进程组
* tcsetpgrp() -- 设置当前会话所关联的控制终端的前台进程组
    * 后台进程组的进程调用时, 该进程组的所有成员将被发送 SIGTTOU

### 守护进程
1. 产生子进程, 然后父进程退出, 保证子进程不是进程组的首进程
2. 新建会话, 保证子进程脱离终端的控制
3. 关闭所有的文件描述符, 避免受到父进程文件描述符的影响
4. 设置权限掩码, 避免受到父进程掩码的影响
5. 切换到根目录, 因为当前目录可能会被卸载或删除
6. 参见开源项目: https://github.com/lighttpd/spawn-fcgi

### 进程间通信
* 管道(pipe)
    * 一般是半双工的
    * 需要有公共的父进程
    * popen() pclose()
        * 新建管道
        * fork() 子进程
        * 执行命令
        * 单方向
    * 协同进程:
        * 两个方向
* 命名管道
    * 任意进程都可以
    * 无需拷入磁盘, 提高效率
* 消息队列
* 信号量
    * 命名信号量
        * `sem_open()` -- 打开或创建信号量
        * `sem_close()` -- 关闭信号量
        * `sem_unlink()` -- 销毁信号量
        * `sem_wait()` -- 信号量减一
        * `sem_post()` -- 信号量加一
    * 匿名信号量
        * `sem_init()` -- 初始化
        * `sem_destroy()` -- 删除
        * `sem_getvalue()` -- 获取信号量的值
* 共享内存
* 网络套接字
* 域套接字

## 文件管理
* 文件信息(stat)
* 文件类型
* 文件所属的用户和组(chown)
* 文件权限(chmod)
    * 读, 写, 执行
    * 在目录下新增或删除文件时, 至少拥有此目录的写和执行权限
    * SUID
        * 二进制文件: 程序的执行者拥有程序所有者的权限
        * 其他文件没意义
    * SGID
        * 二进制文件: 程序的执行者拥有程序所属组的权限
        * 目录: 新增的文件所属的组是此目录所属的组
        * 其他文件没意义
    * SBIT
        * 目录: 此目录下的内容只有文件所有者 或 目录所有者 或 root 用户才能删除
        * 其他文件没意义
    * 权限判断:
        * 依次判断所属用户, 所属组和其他权限
        * 前者失败时, 不判断后者
        * 假如 1.cc 的权限为 0070,
        * 所属主无权限, 所属组有权限时,
        * 对所属主也将判断为无权限
* 文件时间(touch)
    * atime: 内容访问时间, 更新可能不及时
    * mtime: 内容修改时间
    * ctime: 状态修改时间, 包括 内容 名称 权限 所属者 所属组
    * utimes(): 修改内容访问时间, 内容修改时间; 状态修改时间不能修改
* 新建目录
    * mkdir ...... 创建单层目录, 存在时报错
    * mkdir -p ... 递归创建目录, 存在时不报错
* 删除目录
    * rm -r ...... 递归删除
    * rm -rf ..... 强行删除, 文件不存在时, 忽略
* 新建临时文件(mktemp)
* 新建临时目录(mktemp -d)
* 查看目录
    * opendir() ---- 打开目录(文件名称)
    * fdopendir() -- 打开目录(文件描述符)
    * readdir() ---- 读目录
    * closedir() --- 关闭目录
    * chdir() ------ 修改当前目录(目录名称)
    * fchdir() ----- 修改当前目录(文件描述符)
    * getcwd() ----- 获取当前目录
    * ls --time-style='+%Y-%m-%d %H:%M:%S %z' -lhrtu ... 文件访问时间     逆序
    * ls --time-style='+%Y-%m-%d %H:%M:%S %z' -lhrtc ... 文件属性修改时间 逆序
    * ls --time-style='+%Y-%m-%d %H:%M:%S %z' -lhrt .... 文件内容修改时间 逆序
    * ls --time-style='+%Y-%m-%d %H:%M:%S %z' -lhrtd ... 文件内容修改时间 逆序, 只列出目录本身
    * ls --time-style='+%Y-%m-%d %H:%M:%S %z' -lhrS .... 文件大小         逆序
    * ls --time-style='+%Y-%m-%d %H:%M:%S %z' -lhrv .... 文件版本号       逆序
    * ls --time-style='+%Y-%m-%d %H:%M:%S %z' -lhrX .... 文件扩展名       逆序
    * ls -R ... 递归
    * ls -1 ... 每一行列出文件名
    * ls -L ... 符号链接所指向的文件, 而不是符号链接本身
    * ls -I ... 忽略文件, 使用通配符
    * pwd ..... 列出当前目录
    * cd ...... 修改当前目录, 需要在当前的 shell 中
* link()  -- 增加硬链接的引用计数
* unlink() -- 减少硬链接的引用计数, 有进程打开该文件时, 不会删除
* symlink() -- 新建符号链接
* readlink() -- 读取符号链接
* ln -s target symbolic_link_name # 创建符号链接

* access() -- 以实际用户测试权限, 一般以有效用户测试
* umask() --- 新建文件时, 权限的屏蔽位
* truncate() -- 文件截断
* remove() -- 删除硬链接 或 目录
* rename() -- 重命名

## IO管理
### 不带缓冲的IO
* open() --- 打开文件, 原子操作
* close() -- 关闭文件, 原子操作
* read() --- 读文件
* write() -- 写文件
* lseek() -- 移动文件偏移量, 可能生产空洞, 空洞不占磁盘空间
* dup2() --- 复制文件描述符
* fcntl()
    * 复制文件描述符(包括 exec 时, 是否关闭)
    * 查看和设置文件描述符(exec 时, 是否关闭)
    * 查看和设置文件状态标志(读写添加等等)
    * 异步属性
    * 文件锁
* ioctl() -- 主要处理终端

### 标准IO
* 打开文件
    * fopen() ---- 使用文件名
    * freopen() -- 重新打开
    * fdopen() --- 使用文件描述符
* 关闭文件: fclose()
* 读写数据(字符)
    * getc() ----- 读取字符, 可能是宏
    * fgetc() ---- 读取字符
    * getchar() -- 读取字符
    * ungetc() --- 压回字符
    * putc() ----- 输出字符, 可能是宏
    * fputc() ---- 输出字符
    * putchar() -- 输出字符
* 读写数据(行)
    * gets() ----- 读取, 不建议使用
    * puts() ----- 输出字符串, 然后输出换行符, 不建议使用
    * fgets() ---- 换行符也会被读取, 不一定能读取完整的行
    * fputs() ---- 输出字符串
* 读写数据(二进制)
    * fread() ---- 读数据
    * fwrite() --- 写数据
    * ftell() ---- 获取流位置
    * fseek() ---- 设置流位置
    * rewind() --- 重置流位置
* 格式化 IO
    * printf() --- 输出到标准输出
    * fprintf() -- 输出到标准IO
    * dprintf() -- 输出到文件描述符
    * sprintf() -- 输出到字符串
    * snprintf() -- 输出到字符串
    * vprintf() -- 使用可变参数 va
    * vfprintf() -- 使用可变参数 va
    * vdprintf() -- 使用可变参数 va
    * vsprintf() -- 使用可变参数 va
    * vsnprintf() -- 使用可变参数 va
    * scanf() ------ 输入(标准输入)
    * fscanf() ----- 输入(流)
    * sscanf() ----- 输入(字符串)
    * vscanf() ----- 使用可变参数 va
    * vfscanf() ---- 使用可变参数 va
    * vsscanf() ---- 使用可变参数 va
* 错误
    * ferror()
    * feof()
    * clearerr()
* fileno 流 --> 文件描述符

mktemp
mkdtemp

内存流: fmemopen()


* 临时文件
* 缓冲
    * 全缓冲(磁盘)
        * 填满缓冲区才缓冲
    * 行缓冲(终端)
        * 要到换行符或填满缓冲区才缓冲
        * 遇到读操作(从内核)
    * 不缓冲
        * 输出错误
    * setvbuf() -- 设置缓冲类型
    * fflush() -- 强行刷新缓冲



    getpwuid() 获取用户信息(uid)
    getpwnam() 获取用户信息(name)
    getpwent() 打开口令文件
    setpwent() 口令文件定位到文件开头
    endpwent() 关闭口令文件


    pthread_equal()
    pthread_self()
    pthread_create()
    pthread_exit()
    pthread_join() -- 等待线程终止
    pthread_cancel() -- 取消线程
    pthread_cleanup_push() -- 线程正常退出或被取消时执行
    pthread_cleanup_pop() ---
    pthread_detach() -- 线程设置为游离态

    pthread_mutex_init()
    pthread_mutex_destroy()
    pthread_mutex_lock()
    pthread_mutex_trylock()
    pthread_mutex_unlock()
    pthread_mutex_timedlock()

    pthread_rwlock_init()
    pthread_rwlock_destroy()
    pthread_rwlock_rdlock()
    pthread_rwlock_tryrdlock()
    pthread_rwlock_wrlock()
    pthread_rwlock_trywrlock()
    pthread_rwlock_unlock()
    pthread_rwlock_timedrdlock()
    pthread_rwlock_timewrdlock()

    pthread_cond_init()
    pthread_cond_destroy()
    pthread_cond_timedwait()
    pthread_cond_wait()
    pthread_cond_signal()
    pthread_cond_broadcast()

    pthread_spin_init()
    pthread_spin_destroy()
    pthread_spin_lock()
    pthread_spin_trylock()
    pthread_spin_unlock()

    pthread_barrierattr_init
    pthread_barrier_destroy
    pthread_barrier_wait

    select
    pselect
    poll
    epoll
    异步IO

    readv
    writev
    readn
    writen

    mmap
    munmap

    socket
    shutdown
    htonl
    htons
    ntohl
    ntohs
    bind
    listen
    connect
    accept
    send
    sendto
    sendmsg
    recv
    recvfrom
    recvmsg
    setsockopt

    socketpair

### 终端 IO
* 规范模式: 行缓存
* 非规范模式:

tcgetattr
tcsetaddr
stty
isatty
ttyname

## 日期和时间
* localtime() -- 获取本地时间
* system()    -- 执行命令, 输出到终端?
* strftime()  -- 格式化时间
* time()      -- 获取当前的时间戳

## 相关命令
```
basename $(readlink -f $0) # 获取脚本的名称
dirname  $(readlink -f $0) # 获取脚本的目录

bc <<< "scale=2; 10/2" # 使用两位小数, 输出: 5.00
bc <<< "ibase=2;  100" # 输入使用二进制, 输出: 4
bc <<< "obase=2;   10" # 输出使用二进制, 输出: 1010

                  # 文件如果是符号链接, 将使用符号链接对应的文件
cat               # 输出 标准输入 的内容
cat          -    # 输出 标准输入 的内容
cat    1.txt      # 输出 1.txt 的内容, 文件支持多个
cat    1.txt -    # 输出 1.txt 和 标准输入 的内容
cat -n 1.txt      # 显示行号
cat -b 1.txt      # 显示行号, 行号不包括空行, 将覆盖参数 -n
cat -s 1.txt      # 去掉多余的连续的空行
cat -T 1.txt      # 显示 TAB
cat -E 1.txt      # 使用 $ 标明行结束的位置

tac               # 最后一行 => 第一行

chattr +i 1.c # 设置文件不可修改
chattr -i 1.c # 取消文件不可修改

column -t # 列对齐

                                                       # 文件如果是符号链接, 将使用符号链接对应的文件
comm                        1.c 2.c                    # 要求文件已排序, 以行比较
comm --check-order          1.c 2.c                    #   检测文件是否已排序
comm --nocheck-order        1.c 2.c                    # 不检测文件是否已排序
comm --output-delimiter=... 1.c 2.c                    # 指定列分割, 默认是 TAB
comm                        1.c 2.c       | tr -d '\t' # 全集
comm                        1.c 2.c -1 -2 | tr -d '\t' # 交集
comm                        1.c 2.c -3    | tr -d '\t' # B - A 和 A - B
comm                        1.c 2.c -1 -3              # B - A
comm                        1.c 2.c -2 -3              # A - B

cp    123 456      # 拷贝文件时, 使用符号链接所指向的文件
                   # 拷贝目录时, 目录中的符号链接将使用符号链接本身
                   # 456 只使用符号链接所指向的文件
cp -r 123 456      # 递归复制
cp -P 123 456      # 总是拷贝符号链接本身
cp -L 123 456      # 总是拷贝符号链接所指的文件
cp --parents a/b t # 全路径复制, 将生成 t/a/b

                                      # 文件如果是符号链接, 将使用符号链接对应的文件
cut                        -b 2   1.c # 按字节切割, 输出第 2 个字节
cut                        -c 2-  1.c # 按字符切割, 输出 [2, 末尾] 字符
cut                        -f 2-5 1.c # 按列切割,   输出 [2,5] 列
cut -d STR                 -f 2,5 1.c # 设置输入字段的分隔符, 默认为 TAB, 输出 第 2 列和第 5 列
cut -s                     -f  -5 1.c # 不输出不包含字段分隔符的列, 输出 [开头, 5] 的列
cut --output-delimiter=STR -f  -5 1.c # 设置输出的字段分隔符, 默认使用输入的字段分隔符

diff    1.txt 2.txt # 比较两个文件的不同
diff -u 1.txt 2.txt # 一体化输出, 比较两个文件的不同

dd if=/dev/zero of=junk.data bs=1M count=1

df   -Th                # 查看磁盘挂载情况

dos2unix 1.txt # \r\n (windows) => \n (Linux/iOS)
unix2doc 1.txt # \n (Linux/iOS) => \r\n (windows)

du                      # 列出目录大小
du -0                   # 输出以 \0 分割, 默认是换行符
du -a                   # 列出目录和文件大小
du -d 1                 # 最大目录深度
du -sh                  # 只列出整体使用大小
du --exclude="*.txt"    # 忽略指定文件, 支持通配符

file 1.txt # 查看换行符等

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
grep -P ..                # 使用 perl 风格的正则表达式
grep -W ..                # 单词匹配
grep -X ..                # 行匹配
grep ... --inclue "*.c"   # 指定文件
grep ... --exclue "*.c"   # 忽略文件
grep ... --exclue-dir src # 忽略目录

less # 空格   : 下一页
     # ctrl+F : 下一页
     # b      : 上一页
     # ctrl+b : 上一页
     # 回车   : 下一行
     # =      : 当前行号
     # y      : 上一行

ln -s target symbolic_link_name # 创建符号链接

md5sum 1.txt # MD5 检验

more    # 空格   : 下一页
        # ctrl+F : 下一页
        # b      : 上一页
        # ctrl+b : 上一页
        # 回车   : 下一行
        # =      : 当前行号

mv a b # a 是符号链接时, 将使用符号链接本身
       # b 是指向文件  的符号链接时， 相当于 移到 b 本身
       # b 是指向目录  的符号链接时， 相当于 移到 b 最终所指向的目录下
       # b 是指向不存在的符号链接时， 相当于 重命名

patch     1.txt diff.pathc  # 恢复文件
patch -p1 1.txt diff.pathc  # 恢复文件, 忽略 diff.pathc 的第一个路径

readlink    1.c.link  # 读取符号链接
readlink -f 1.c.link  # 读取符号链接, 递归

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

tail -f * # 动态查看新增内容

tee    1.txt # 管道中把文件拷贝到文件
tee -a 1.txt # 管道中把文件添加到文件

tr    'a-z' 'A-Z' # 小写转大写
tr -d 'a-z'       # 删除字符
tr -s ' '         # 压缩字符

tree -p "*.cc"       # 只显示  匹配到的文件
tree -I "*.cc"       # 只显示没匹配到的文件
tree -H . -o 1.html  # 指定目录生成 html 文件

uniq    # 删除重复的行
uniq -c # 输出统计的次数
uniq -d # 只输出重复的行, 重复的项只输出一次
uniq -D # 只输出重复的行, 重复的项输出多次
uniq -i # 忽略大小写
uniq -u # 只输出没重复的行

cat lyb | xargs -i vim {} # 以此编辑 lyb 中的每一个文件

wc    # 输出 换行符数 字符串数 字节数
wc -l #   行数
wc -w # 字符串数
wc -c # 字节数
wc -m # 字符数
```

# 计算机组成原理
# 计算机网络

# 最佳实际
* 文件名称建议: 大小写字母 数字 下划线 短横线 点
* 参数建议: 不要空格, 不要以短横线开头
* 学习命令: 以功能为核心,
* 学习一个命令需要注意的点
    * 不常用的命令, 只需知道大致功能即可, 比如, 组相关的命令
    * 不常用的命令, 只需知道命令的大致功能 或者 关键参数即可, 比如, 组相关的命令
    *   复杂的命令, 需要总结出常用的参数, 每次都过一遍 man 文档太麻烦了, 比如, ps
    *   常用的命令, 需要知道大致功能即可, 记住常用参数, 其他参数需要的时候查询即可
    * 支持 通配符, 还是基础的正则表达式 还是 扩展的正则表达式
    * 涉及过滤时, 多个命令是且还是或
    * 对符号链接的处理, 这个可以先猜, 有利于加深理解
    * 对转义字符的处理
    * 学习命令要以功能为核心而不是以命令参数为核心
    * 不要垃圾进垃圾出, 宁可不写, 也不写错的, 或者 不懂的内容

# 操作系统-打包和压缩
## 压缩命令需要考虑的问题
```
* 压缩, 能否压缩目录
* 压缩, 能否跳过文件
* 压缩, 能否跳过目录
* 压缩, 使用  精确名称跳过文件或目录时, 也会跳过子目录的文件或目录 -- 通用(不包括 zip gunzip, 下同)
* 压缩, 使用通配符名称跳过文件或目录时, 也会跳过子目录的文件或目录(假设没有和通配符相同的文件) -- 通用
* 压缩, 是否可以保留符号链接
* 压缩, 能否完整保留 Linux 权限, 比如 suid
* 压缩, 是否删除源文件
* 压缩, 目标文件已存在时, 怎么办?
* 解压, 是否可以指定解压目录
* 解压, 是否可以只解压部分文件
* 解压, 是否可以只解压部分目录
* 解压, 使用  精确名称指定部分文件或目录时, 需要从顶层目录开始指定 -- 通用
* 解压, 使用通配符名称指定部分文件或目录时, 也会跳过子目录的文件或目录(假设没有和通配符相同的文件) -- 通用
* 解压, 是否可以跳过部分文件
* 解压, 是否可以跳过部分目录
* 解压, 使用  精确名称跳过部分文件或目录时, 需要从顶层目录开始指定 -- 通用
* 解压, 使用通配符名称跳过部分文件或目录时, 也会跳过子目录的文件或目录(假设没有和通配符相同的文件) -- 通用
* 解压, 能否完整保留 Linux 权限, 比如 suid
* 解压, 是否删除源文件
* 解压, 目标文件已存在时, 怎么办?
* 查看, 查看部分文件或跳过部分文件要考虑的问题同解压
```

## tar
```
* 压缩, 能否压缩目录                            -- 可以(其实是先打包后压缩)
* 压缩, 能否跳过文件                            -- 可以
* 压缩, 能否跳过目录                            -- 可以
* 压缩, 是否可以保留符号链接                    -- 可以
* 压缩, 能否完整保留 Linux 权限, 比如 suid      -- 可以
* 压缩, 是否删除源文件                          -- 不会
* 压缩, 目标文件已存在时, 怎么办?               -- 删除旧文件, 生成新文件
* 解压, 是否可以指定解压目录                    -- 可以
* 解压, 是否可以只解压部分文件                  -- 可以
* 解压, 是否可以只解压部分目录                  -- 可以
* 解压, 是否可以跳过部分文件                    -- 可以
* 解压, 是否可以跳过部分目录                    -- 可以
* 解压, 能否完整保留 Linux 权限, 比如 suid      -- 可以
* 解压, 是否删除源文件                          -- 不会
* 解压, 目标文件已存在时, 怎么办?               -- 更新压缩包里存在的文件, 压缩包里不存在的文件保持不变

tar             acf 1.tgz                   ... # 打包并压缩, 根据后缀自动选择压缩类型
tar            vacf 1.tgz                   ... # 打包并压缩, 显示压缩过程
tar             acf 1.tgz -X 1.txt          ... # 打包并压缩, 跳过 1.txt 内的文件
tar             acf 1.tgz --exclude "..."   ... # 打包并压缩, 跳过文件或目录
tar              xf 1.tgz                       # 解压, 根据后缀自动选择压缩类型
tar             vxf 1.tgz                       # 解压, 显示解压过程
tar             pxf 1.tgz                       # 解压, 完整还原权限, 比如, suid
tar              xf 1.tgz -C ...                # 解压, 指定解压目录
tar              xf 1.tgz            1.txt      # 解压部分文件或目录, 精确
tar --wildcards -xf 1.tgz           "*.txt"     # 解压部分文件或目录, 通配符, 有的版本不需要 --wildcards
tar              xf 1.tgz --exclude  1.txt      # 解压跳过部分文件或目录, 精确
tar --wildcards -xf 1.tgz --exclude "*.txt"     # 解压跳过部分文件或目录, 通配符, 有的版本不需要 --wildcards
tar              tf 1.tgz                       # 列出压缩包中的文件和目录, 根据后缀自动选择压缩类型
tar             vtf 1.tgz                       # 列出压缩包中的文件和目录, 包括权限, 所属用户等
tar              tf 1.tgz  ...                  # 列出压缩包中的指定文件或目录, 说明同解压

tar cf 1.tar ... # 打包
tar xf 1.tar     # 解包
tar tf 1.tar     # 查看包
tar rf 1.tar ... # 添加包
tar uf 1.tar ... # 更新包

tar zcf 1.tgz ... # 打包并压缩 gzip
tar zxf 1.tgz     # 解压并解包 gzip
tar ztf 1.tgz     # 查看

tar zcf 1.tar.gz ... # 打包并压缩 gzip
tar zxf 1.tar.gz     # 解压并解包 gzip
tar ztf 1.tar.gz     # 查看

tar jcf 1.tar.bz2 ... # 打包并压缩 bz2
tar jxf 1.tar.bz2     # 解压并解包 bz2
tar jtf 1.tar.bz2     # 查看

tar Zcf 1.Z ... # 打包并压缩 compress
tar Zxf 1.Z     # 解压并解包 compress
tar Ztf 1.Z     # 查看
```

## gzip gunzip
```
* 压缩, 能否压缩目录                            -- 不能
* 压缩, 能否跳过文件                            -- 不能, 只有一个文件
* 压缩, 能否跳过目录                            -- 不能
* 压缩, 是否可以保留符号链接                    -- 不能, 只有一个文件, 符号链接没意义
* 压缩, 能否完整保留 Linux 权限, 比如 suid      -- 不能
* 压缩, 是否删除源文件                          -- 会
* 压缩, 目标文件已存在时, 怎么办?               -- 会提醒是否覆盖
* 解压, 是否可以指定解压目录                    -- 不能
* 解压, 是否可以只解压部分文件                  -- 不能, 只有一个文件
* 解压, 是否可以只解压部分目录                  -- 不能
* 解压, 是否可以跳过部分文件                    -- 不能, 只有一个文件
* 解压, 是否可以跳过部分目录                    -- 不能
* 解压, 能否完整保留 Linux 权限, 比如 suid      -- 不能
* 解压, 是否删除源文件                          -- 会
* 解压, 目标文件已存在时, 怎么办?               -- 会提醒是否覆盖

gzip      ...       #     压缩
gzip  -r ....       # 递归压缩
gzip  -l 1.gz       #     列出 1.gz 内文件
gzip  -d 1.gz       #   解压缩
gunzip   1.gz       #   解压缩
gunzip   1.tgz      #   解压缩
```

## bzip2 bunzip2
```
* 压缩, 能否压缩目录                            -- 不能
* 压缩, 能否跳过文件                            -- 不能, 只有一个文件
* 压缩, 能否跳过目录                            -- 不能
* 压缩, 是否可以保留符号链接                    -- 不能, 只有一个文件, 符号链接没意义
* 压缩, 能否完整保留 Linux 权限, 比如 suid      -- 不能
* 压缩, 是否删除源文件                          -- 默认会删除
* 压缩, 目标文件已存在时, 怎么办?               -- 默认会报错
* 解压, 是否可以指定解压目录                    -- 不能
* 解压, 是否可以只解压部分文件                  -- 不能, 只有一个文件
* 解压, 是否可以只解压部分目录                  -- 不能
* 解压, 是否可以跳过部分文件                    -- 不能, 只有一个文件
* 解压, 是否可以跳过部分目录                    -- 不能
* 解压, 能否完整保留 Linux 权限, 比如 suid      -- 不能
* 解压, 是否删除源文件                          -- 默认会删除
* 解压, 目标文件已存在时, 怎么办?               -- 默认会报错

bzip2       ...    #   压缩,   删除源文件, 目标文件已存在时报错
bzip2   -f  ...    #   压缩,   删除源文件, 目标文件已存在时覆盖
bzip2   -k  ...    #   压缩, 不删除源文件
bzip2   -v  ...    #   压缩,   显示压缩过程
bzip2   -q  ...    #   压缩, 不显示压缩过程
bzip2   -d  1.bz2  # 解压缩, 其他组合选项同压缩
bunzip2     1.bz2  # 解压缩, 其他组合选项同压缩
```

## compress uncompress
```
* 压缩, 能否压缩目录                            -- 不能
* 压缩, 能否跳过文件                            -- 不能, 只有一个文件
* 压缩, 能否跳过目录                            -- 不能
* 压缩, 是否可以保留符号链接                    -- 不能, 只有一个文件, 符号链接没意义
* 压缩, 能否完整保留 Linux 权限, 比如 suid      -- 不能
* 压缩, 是否删除源文件                          -- 会
* 压缩, 目标文件已存在时, 怎么办?               -- 默认会提醒是否覆盖
* 解压, 是否可以指定解压目录                    -- 不能
* 解压, 是否可以只解压部分文件                  -- 不能, 只有一个文件
* 解压, 是否可以只解压部分目录                  -- 不能
* 解压, 是否可以跳过部分文件                    -- 不能, 只有一个文件
* 解压, 是否可以跳过部分目录                    -- 不能
* 解压, 能否完整保留 Linux 权限, 比如 suid      -- 不能
* 解压, 是否删除源文件                          -- 会
* 解压, 目标文件已存在时, 怎么办?               -- 默认会提醒是否覆盖

  compress    ...  #   压缩, 目标文件已存在时可选择是否覆盖
  compress -f ...  #   压缩, 目标文件已存在时覆盖
  compress -r ...  #   压缩, 递归
  compress -d 1.Z  # 解压缩, 其他组合选项同压缩
uncompress    1.Z  # 解压缩, 其他组合选项同压缩
```

## zip unzip
```
* 压缩, 能否压缩目录                            -- 可以
* 压缩, 能否跳过文件                            -- 可以
* 压缩, 能否跳过目录                            -- 可以
* 压缩, 是否可以保留符号链接                    -- 默认使用符号链接所指向的文件
* 压缩, 能否完整保留 Linux 权限, 比如 suid      -- 不能
* 压缩, 是否删除源文件                          -- 默认不会
* 压缩, 目标文件已存在时, 怎么办?               -- 不会删除旧文件, 只会更新旧文件
* 解压, 是否可以指定解压目录                    -- 可以
* 解压, 是否可以只解压部分文件                  -- 可以
* 解压, 是否可以只解压部分目录                  -- 可以
* 解压, 是否可以跳过部分文件                    -- 可以
* 解压, 是否可以跳过部分目录                    -- 可以
* 解压, 能否完整保留 Linux 权限, 比如 suid      -- 不能
* 解压, 是否删除源文件                          -- 默认不会
* 解压, 目标文件已存在时, 怎么办?               -- 默认会提醒

zip     1.zip ...             # 压缩文件
zip -r  1.zip ...             # 压缩目录
zip -r  1.zip ... -x  1.txt   # 压缩, 跳过指定文件, 需要从顶层目录开始
zip -r  1.zip ... -x  "111/"  # 压缩, 跳过指定空目录, 需要从顶层目录开始, 精确 (必须包含斜杠)
zip -r  1.zip ... -x  "111/*" # 压缩, 跳过指定  目录, 需要从顶层目录开始, 精确
zip -r  1.zip ... -x "*.txt"  # 压缩, 跳过指定文件,   包括子目录, 通配符, 假设不存在文件 *.txt
zip -rj 1.zip    ...          # 压缩, 所有文件都移到顶层目录
zip -l  1.zip    ...          # 压缩 LF -> LF+CR
zip -ll 1.zip    ...          # 压缩 LF+CR -> LF
zip -m  1.zip    ...          # 压缩, 删除原始文件
zip -q  1.zip    ...          # 压缩, 不显示指令执行过程
zip -y  1.zip    ...          # 压缩, 保存符号链接本身
zip -d  1.zip   1.txt         # 删除 1.zip 里的文件, 需要从顶层路径开始, 精确
zip -d  1.zip  "123/"         # 删除 1.zip 里的空目录, 需要从顶层路径开始, 精确 (必须包含斜杠)
zip -d  1.zip  "123/*"        # 删除 1.zip 里的  目录, 需要从顶层路径开始, 精确
zip -d  1.zip "*.txt"         # 删除 1.zip 里的文件, 包括子目录, 通配符, 假设不存在文件 *.txt
zip -f  1.zip    ...          # 更新 1.zip 里的文件, 不添加
zip -u  1.zip    ...          # 更新 1.zip 里的文件, 不存在时添加, 感觉和默认行为没什么区别
zip -v  1.zip    ...          # 显示执行过程

unzip    1.zip               # 解压
unzip    1.zip   1.txt       # 解压部分文件, 精确, 需要从顶层路径开始
unzip    1.zip    123/       # 解压部分空目录, 精确, 需要从顶层路径开始 (必须包含斜杠)
unzip    1.zip   "123/*"     # 解压部分  目录, 精确, 需要从顶层路径开始
unzip    1.zip   "*.txt"     # 解压部分文件, 通配符, 包括子目录, 假设不存在文件 *.txt
unzip    1.zip -x ...        # 解压缩, 跳过指定文件或目录, 规则同上
unzip    1.zip -d ...        # 解压缩到指定目录
unzip -j 1.zip               # 解压时, 文件都移到顶层路径
unzip -o 1.zip               # 解压时, 直接覆盖重复的文件, 不提醒
unzip -n 1.zip               # 解压时,   不覆盖重复的文件
unzip -l 1.zip               # 列出 1.zip 的目录结构, 简单
unzip -v 1.zip               # 列出 1.zip 的目录结构, 详细点
```

## rar unrar
```
* 压缩, 能否压缩目录                            -- 可以
* 压缩, 能否跳过文件                            --
* 压缩, 能否跳过目录                            --
* 压缩, 是否可以保留符号链接                    -- 默认使用符号链接所指向的文件
* 压缩, 能否完整保留 Linux 权限, 比如 suid      -- 可以
* 压缩, 是否删除源文件                          -- 不会
* 压缩, 目标文件已存在时, 怎么办?               -- 不会删除旧文件, 只会更新旧文件
* 解压, 是否可以指定解压目录                    -- 可以
* 解压, 是否可以只解压部分文件                  -- 可以
* 解压, 是否可以只解压部分目录                  -- 可以
* 解压, 是否可以跳过部分文件                    --
* 解压, 是否可以跳过部分目录                    --
* 解压, 能否完整保留 Linux 权限, 比如 suid      -- 可以
* 解压, 是否删除源文件                          -- 不会
* 解压, 目标文件已存在时, 怎么办?               -- 会提醒

rar      a 1.rar ...      #   压缩文件或目录
rar -ol  a 1.rar ...      #   压缩文件或目录, 保留符号链接本身
unrar    v 1.rar          # 列出压缩包信息, 详细
unrar    l 1.rar          # 列出压缩包信息, 简易
unrar    l 1.rar ...      # 列出压缩包内的指定文件或目录
unrar    e 1.rar ...      # 解压缩到指定路径, 忽略压缩包内的路径
unrar    x 1.rar ...      # 解压缩到指定路径, 使用完整的压缩包路径
unrar    x 1.rar ... ...  # 解压缩到指定路径, 使用完整的压缩包路径, 只解压部分文件
```

# 操作系统-日期和时间
## 基础概念
* 地球自转一圈为一天
* 地球公转一圈为一年
* 地球公转一圈时, 地球自转了 365.24219 圈, 所以, 一年等于 365.24219 天
* 为了修正误差, 区分了平年和闰年
* 规则(这样算完还有误差, 但误差就比较小了)
    * 如果遇到不是整百年, 且能被四  整除, 是闰年
    * 如果遇到  是整百年, 且能被四百整除, 是闰年
* 为什么不把一年直接定义为 365 天, 为了保证夏天始终热, 冬天始终冷, 否则就乱了
* 闰年的参照物是太阳
* 闰月的参照物是月亮
* 时间戳:
    * 距离 1970-01-01 00:00:00 +0000 的秒数, 不包括闰秒
    * 不受时区的影响, 所有时区都相同
    * 有的系统允许使用负数, 有的系统不允许

## GMT(格林威治时间)(已过时)
* 太阳经过格林威治天文台的时间为中午12点
* 这里说的一天不受地球自转速度的影响
* 地球转的快了, 一天就短, 一秒也变短, 慢了, 一天就长, 一秒也变长

## UTC(正在用)
* 原子时间: 一秒是精确的, 一天也是精确的(原子时间有误差, 但很小)
* 由于, 地球自转速度的变化, 导致和 GMT 的时间对不上, 由此, 产生了闰秒
* 好消息是: 2035 年要取消闰秒了

## 夏令时
* 进夏令时的那一天只有 23 个小时
* 出夏令时的那一天只有 25 个小时
* 其他日期都有 24 个小时
* 可以节约能源

## 时区
* 每 15 个经度一个时区
* 总共 24 个时区
* 相邻时区相差一个小时

## 配置
* /etc/default/locale -- 修改系统显示

## 常用函数
```
* time(time_t*)                                                 获取基于 1970-01-01 00:00:00 +0000 的时间戳
* struct tm*    gmtime(const time_t*)                           时间戳   --> 时间元组, +0000 utc
* struct tm* localtime(const time_t*)                           时间戳   --> 时间元组, 本地时间
* char *         ctime(const time_t*)                           时间戳   --> 字符串
* char *  asctime(const struct tm *tm)                          时间元组 --> 字符串
* size_t strftime(char*, size_t, const char*, const struct tm*) 时间元组 --> 字符串, 可以指定格式
* time     mktime(struct tm *tm)                                时间元组 --> 字符戳
* char *strptime(const char*, const char*, struct tm*)          字符串   --> 时间元组
* double difftime(time_t time1, time_t time0);                  两个时间戳的差值

time() => localtime() => strftime(): 时间戳 => 时间元组 => 字符串形式
strptime() => mktime()             : 字符串形式 => 时间元组 => 时间戳
```

## 常用命令
```
* ntpdate -s time-b.nist.gov          # 使用时间服务器更新时间

* date "+%Y-%m-%d %H:%M:%S %z"        # 输出: 年-月-日 时-分-秒 时区
* date "+%F %T %z"                    # 输出: 年-月-日 时-分-秒 时区
* date "+%j"                          # 输出: 一年中的第几天
* date "+%u"                          # 输出: 一周中的第几天(1..7), 1 为周一
* date "+%U"                          # 输出: 一年中的第几周(00..53), 从周一开始
* date "+%w"                          # 输出: 一周中的第几天(0..6), 0 为周末
* date "+%W"                          # 输出: 一年中的第几周(00..53), 从周末开始
* date "+%s"                          # 输出: 时间戳
* date -d "2020-02-02 01:01:01 +0800" # 指定输入日期和时间, 秒数不能为 60
* date -d "@...."                     # 使用: 时间戳
* date -d "next sec"                  # 下一秒
* date -d "next secs"                 # 下一秒
* date -d "next second"               # 下一秒
* date -d "next seconds"              # 下一秒
* date -d "next min"                  # 下一分钟
* date -d "next mins"                 # 下一分钟
* date -d "next minute"               # 下一分钟
* date -d "next minutes"              # 下一分钟
* date -d "next hour"                 # 下一小时
* date -d "next hours"                # 下一小时
* date -d "next day"                  # 明天
* date -d "next days"                 # 明天
* date -d "next mon"                  # 下周一
* date -d "next monday"               # 下周一
* date -d "next month"                # 下个月
* date -d "next months"               # 下个月
* date -d "next year"                 # 下年
* date -d "next years"                # 下年
* date -d "next year  ago"            # 去年, 除年外, 其他也可以
* date -d "next years ago"            # 去年, 除年外, 其他也可以
* date -d "10year"                    # 十年以后, 除年外, 其他也可以
* date -d "10years"                   # 十年以后, 除年外, 其他也可以
* date -d "10   year"                 # 十年以后, 除年外, 其他也可以
* date -d "10   years"                # 十年以后, 除年外, 其他也可以
* date -d "10   year  ago"            # 十年以前, 除年外, 其他也可以
* date -d "10   years ago"            # 十年以前, 除年外, 其他也可以
* date -d "tomorrow"                  # 明天
* date -d "now"                       # 现在
* date -s "2020-02-02 10:10:10"       # 更新系统时间, 需要 root, 格式见 -d 选项
* date -r 1.c                         # 使用: 文件的 mtime
```

# 操作系统-用户和组
## 为什么存在用户?
* 要登录一个系统, 肯定需要一个名称, 用以区分不同的用户

## 为什么存在组?
* 为了多个用户之间共享数据

## 用户, 用户名称, 用户ID, 组, 组名称, 组ID之间的关系
* 用户和用户名称一一对应, 组和组名称一一对应
* 一个用户只能对应一个用户ID, 一个组只能对应一个组ID
* 多个用户可以对应一个用户ID, 多个组可以对应一个组ID
* 一个用户可以对应多个组, 但只能有一个主组

## 用户名称和组名称有什么限制?
* 只能包含 大小写字母 数字 下划线 短横线 小数点, 末尾可以有 $
* 短横线不能在开头, 用以区分可选项和名称
* . 和 .. 不允许
* 不能重复
* 不能是纯数字, 因为一些命令同时接受 ID 和名称的形式
* 长度最多 32 位

## 为什么存在用户ID和组ID?
* 节省空间
* 提高比较的效率

## 用户ID和组ID有什么限制
* 必须大于等于 0
* 0 一般是 root 使用

## 用户的属性
* 用户名称, 用户ID, 组名称, 组ID, 附属组ID
* 主目录, 主目录模板
* 默认 shell
* 用户过期日期
* 锁定用户, 解锁用户
* 密码过期到临时不可用的时间
* 密码修改的最小最大间隔, 警告天数
* UID GID 的值一般默认即可, 不需要特殊设置

## 当前终端的登录用户
* 经过终端或伪终端登录后, 不会再变化

## 当前终端的有效用户
* 经过终端或伪终端登录后, 通过 su 可再变化

## 配置文件
```
/etc/passwd          # 用户基本信息
/etc/shadow          # 用户密码信息
/etc/group           # 组基本信息
/etc/gshadow         # 组密码信息
/etc/default/useradd # useradd 默认配置
/etc/skel/           # 默认主目录模板
/etc/subgid          # 用户隶属的 GID
/etc/subuid          # 用户隶属的 UID
/etc/login.defs      # 有关登录的配置信息
```

## 相关命令
```
useradd           # 添加用户或修改默认配置
useradd -c ...    #   指定关于用户的一段描述
useradd -e ...    #   指定用户过期日期, YYYY-MM-DD
useradd -f ...    #   指定用户密码过期到账户临时不可用的天数
useradd -g ...    #   指定主组, 主组必须存在
useradd -G ...    #   指定附属组, 附属组必须存在, 可以多个, 以逗号分割
useradd -k ...    #   指定主目录模板, 如果主目录由 useradd 创建, 模板目录中的文件将拷贝到新的主目录中
useradd -K ...    #   修改默认参数
useradd -s ...    #   指定shell
useradd -D        #   查看默认配置
useradd -D ...    #   修改默认配置
useradd    -b ... #   指明主目录的父目录, 父目录必须存在
useradd -m -b ... #   指明主目录的父目录, 父目录不必存在, 会自动新建
useradd    -d ... #   指明主目录, 主目录可以不存在, 不存在的话不会新建
useradd -m -d ... #   指明主目录, 主目录可以不存在, 不存在的话会自动新建
useradd -m ...    #   用户主目录不存在的话自动新建
useradd -M ...    #   用户主目录不会新建
useradd -N ...    #   不创建和用户同名的组
useradd -o ...    #   允许 UID 重复
useradd -r ...    #   创建系统用户
useradd -u ...    #   指定 UID 的值
useradd -U ...    #   创建和用户同名的组

userdel    ...    # 删除用户
userdel -r ...    #   删除用户及其主目录

usermod           # 修改用户
usermod -a -G ... #   添加附属组
usermod -m ...    #   移动主目录
usermod -l ...    #   修改登录名
usermod -L ...    #   锁定用户
usermod -U ...    #   解锁用户
                  #   其他选项同 useradd

newusers          # 批量新增用户

passwd            # 修改 root 密码
passwd -stdin     # 修改 root 密码, 从标准输入读取
passwd        lyb # 修改 lyb  密码

chage            # 修改密码相关信息
chage -d ... lyb # 设置上次密码修改的日期
chage -d 0   lyb # 下次登录必须修改密码
chage -E ... lyb # 设置密码过期的日期
chage -I ... lyb # 设置密码过期到账户被锁的天数
chage -m ... lyb # 设置密码修改的最小间隔
chage -M ... lyb # 设置密码修改的最大间隔
chage -W ... lyb # 设置密码过期前的警告的天数
chage -l     lyb # 列出密码相关信息

chfn             # 修改个人信息, 手机号之类
chsh -s ...      # 修改默认的 shell
chsh -l          # 列出所有支持的 shell

groups    # 列出用户所属的组名称
groupadd  # 添加组
groupmod  # 修改组信息, 包括组的ID和组名称
groupdel  # 删除组
groupmems # 管理当前用户的主组, 新增或删除成员
gpasswd   # 管理组, 新增或删除成员, 删除密码, 设置组管理人员等
newgrp    # 切换组
sg        # 使用其他组执行命令

su        # 切到 root
su -      # 切到 root, 更新主目录, 环境变量等, 相当于重新登录
su   lyb  # 切到 lyb

sudo                                          # 权限管理文件: /etc/sudoers, 使用 visudo 编辑
sudo -u USERNAME COMMAND                      # 指定用户执行命令
sudo -S date -s "20210722 10:10:10" <<< "123" # 脚本中免密码使用

sudoedit ...                                  # 编辑文件

users  # 列出所有登陆用户

w      # 列出谁登录, 以及目前在干什么
who    # 列出谁登录
who -m # 列出当前终端登录的用户
whoami # 列出当前终端的有效用户

id        # 输出实际或有效的用户和组信息

last      # 列出最近保存的登录的信息
lastb     # 列出最近保存的登录的信息, 包括失败情况

lastlog           # 列出最近一次的登录信息
lastlog -b 10     # 最近一次的登录在 10 天前的信息
lastlog -t 10     # 最近一次的登录在 10 天内的信息
lastlog -C -u lyb # 清除 lyb 最近一次的登录信息
lastlog -S -u lyb # 设置 lyb 最近一次的登录信息
lastlog    -u lyb # 查看 lyb 最近一次的登录信息
```

# 操作系统-软件安装
## 包管理器
### 优点：
1. 安装，卸载 或 升级方便
2. 不容易对系统造成污染（可能性极小）
3. 不需要处理复杂的依赖关系

### 缺点：
1. 需要有管理员权限
2. 安装的版本可能比较旧
3. 不能指定编译参数

## 源码编译到系统目录
### 优点：
1. 可以安装指定的版本
2. 可以指定编译参数

### 缺点：
1. 需要理员权限
2. 可能需要处理复杂的依赖关系
3. 可能会对系统造成污染
4. 安装，卸载 或 升级比较麻烦

## 源码编译到用户目录
### 优点：
1. 可以安装指定的版本
2. 可以指定编译参数
3. 不会对系统造成污染
4. 不需要管理员权限（需要管理员提供编译工具）

### 缺点：
1. 可能需要处理复杂的依赖关系
2. 安装，卸载 或 升级比较麻烦

## 个人建议：
1. 如果没有管理员权限，只能选择源码编译到用户目录
2. 如果有管理员权限，优先选择包管理器，而后选择编译安装到用户目录，尽量不要编译安装到系统目录

## 常用命令
```
apt update      # 更新软件源
                # 软件源: /etc/apt/sources.list
                #         /etc/apt/sources.list.d/
                # 格式:  包类别(deb-软件包 deb-src-源码包) url 发行版本号 分类
                # 更新软件源:
                #   1. 修改上述文件 或 add-apt-repository ... 或 add-apt-repository --remove ...
                #   2. apt update
apt search  vim # 搜寻软件包
apt install vim # 安装软件包
apt show    vim # 列出软件包的信息
apt upgrade     # 更新软件
apt remove  vim # 卸载软件包
apt purge   vim # 卸载软件包, 删除数据和配置文件
apt autoremove  # 自动卸载不需要的软件包

                   # dpkg 为 apt 的后端
dpkg -i ...        # 安装本地的包
dpkg -L vim        # 列出 vim 软件包安装的全部文件
dpkg --search /... # 查看该文件是哪个软件包安装的, 使用绝对路径

yum install epel-release # 安装软件源 epel
yum check-update         # 更新软件源
                         # 软件源: /etc/yum.repos.d/
                         # * [...]           -- 源的名字
                         # * name=...        -- 源的描述
                         # * baseurl=file:// --	源的路径, file:// 表示本地仓库
                         # * enabled=...	 --	是否启用该仓库, 1-启用, 0-不启用
                         # * gpgcheck=...	 -- 是否不用校验软件包的签名, 0-不校验, 1-校验
                         # * gpgkey=...      -- 上个选项对应的 key 值
yum clean all            # 清空软件源缓存
yum makecache            # 新建软件源缓存
yum repolist             # 查看软件源(可达的)

yum search vim           # 搜寻软件包
yum install package_name # 安装软件, 也可以本地安装
yum localinstall ...     # 本地安装
yum update package_name  # 更新某个软件包
yum update               # 更新所有软件包
yum remove  package_name # 卸载软件
yum erase   package_name # 卸载软件，删除数据和文件

yum list installed       # 列出已安装的软件
yum list vim             # 列出某软件包的详细信息
yum list updates         # 列出可用更新
yum provides vim         # 查看软件属于哪个软件包
yum provides /etc/vimrc  # 查看文件由哪个软件使用

                  # 文件如果是符号链接, 将使用符号链接对应的文件
cat               # 输出 标准输入 的内容
cat          -    # 输出 标准输入 的内容
cat    1.txt      # 输出 1.txt 的内容, 文件支持多个
cat    1.txt -    # 输出 1.txt 和 标准输入 的内容
cat -n 1.txt      # 显示行号
cat -b 1.txt      # 显示行号, 行号不包括空行, 将覆盖参数 -n
cat -s 1.txt      # 去掉多余的连续的空行
cat -T 1.txt      # 显示 TAB
cat -E 1.txt      # 使用 $ 标明行结束的位置

chattr +i 1.c # 设置文件不可修改
chattr -i 1.c # 取消文件不可修改

column -t # 列对齐

                                                       # 文件如果是符号链接, 将使用符号链接对应的文件
comm                        1.c 2.c                    # 要求文件已排序, 以行比较
comm --check-order          1.c 2.c                    #   检测文件是否已排序
comm --nocheck-order        1.c 2.c                    # 不检测文件是否已排序
comm --output-delimiter=... 1.c 2.c                    # 指定列分割, 默认是 TAB
comm                        1.c 2.c       | tr -d '\t' # 全集
comm                        1.c 2.c -1 -2 | tr -d '\t' # 交集
comm                        1.c 2.c -3    | tr -d '\t' # B - A 和 A - B
comm                        1.c 2.c -1 -3              # B - A
comm                        1.c 2.c -2 -3              # A - B

cp    123 456      # 拷贝文件时, 使用符号链接所指向的文件
                   # 拷贝目录时, 目录中的符号链接将使用符号链接本身
                   # 456 只使用符号链接所指向的文件
cp -r 123 456      # 递归复制
cp -P 123 456      # 总是拷贝符号链接本身
cp -L 123 456      # 总是拷贝符号链接所指的文件
cp --parents a/b t # 全路径复制, 将生成 t/a/b

cut                        -b 2   1.c # 按字节切割, 输出第 2 个字节
cut                        -c 2-  1.c # 按字符切割, 输出 [2, 末尾] 字符
cut                        -f 2-5 1.c # 按列切割,   输出 [2,5] 列
cut -d STR                 -f 2,5 1.c # 设置输入字段的分隔符, 默认为 TAB, 输出 第 2 列和第 5 列
cut -s                     -f  -5 1.c # 不输出不包含字段分隔符的列, 输出 [开头, 5] 的列
cut --output-delimiter=STR -f  -5 1.c # 设置输出的字段分隔符, 默认使用输入的字段分隔符

diff    1.txt 2.txt # 比较两个文件的不同
diff -u 1.txt 2.txt # 一体化输出, 比较两个文件的不同

# 计算机网络-内网穿透
指的是位于 NAT 之后的机器, 相互连接的问题(P2P)

## NAT 用途
* 子网机器 => NAT => 互联网或其他网络
* 可以解决 IPv4 地址短缺的问题(使用一个IP地址可以让子网内的用户都可以上网)
* 可以使得访问更安全(通过 NAT 过滤)

## NAT 类型
### 基础NAT(只修改 IP)(基本不用)
### NAPT(修改IP和端口号)
* 完全圆锥形NAT(Full cone NAT)
    1. 如果内网机器(A:X)通过NAT(D:X1)发送数据给公网机器(B:Y)
    2. 那么, 内网机器(A:X)发往任何机器的任何端口号的数据都会通过NAT(D:X1)发送
    3. 任何外网机器的任何端口号都可通过NAT(D:X1)向内网机器(A:X)发送数据(任意IP, 任意端口号)
* 受限圆锥形NAT(Address-Restricted cone NAT)
    1. 如果内网机器(A:X)通过NAT(D:X1)发送数据给公网机器(B:Y)
    2. 那么, 内网机器(A:X)发往任何机器的任何端口号的数据都会通过NAT(D:X1)发送
    3. 外网机器(B)的任何端口号都可通过NAT(D:X1)向内网机器(A:X)发送数据(同IP, 任意端口号)
* 端口受限圆锥形NAT(port-Restricted cone NAT)
    1. 如果内网机器(A:X)通过NAT(D:X1)发送数据给公网机器(B:Y)
    2. 那么, 内网机器(A:X)发往任何机器的任何端口号的数据都会通过NAT(D:X1)发送
    3. 外网机器(B:Y)才可以通过NAT(D:X1)向内网机器(A:X)发送数据(同IP, 同端口号)
* 对称NAT(Symmetric NAT)
    1. 如果内网机器(A:X)通过NAT(D:X1)发送数据给公网机器(B:Y)
    2. 那么, 内网机器(A:X)通过NAT(D:X2)发送数据给公网机器(B:Z), X1 != X2 (IP 相同, 端口号不同)
    3. 那么, 内网机器(A:X)通过NAT(D:X3)发送数据给公网机器(C:Y), X1 != X3 (IP 不同, 端口号相同)
    4. 那么, 内网机器(A:X)通过NAT(D:X4)发送数据给公网机器(C:Z), X1 != X4 (IP 不同, 端口号不同)
    5. 外网机器(B:Y)才可以通过NAT(D:X1)向内网机器(A:X)发送数据(同IP, 同端口号)
    6. 外网机器(B:Z)才可以通过NAT(D:X2)向内网机器(A:X)发送数据(同IP, 同端口号)
    7. 外网机器(C:Y)才可以通过NAT(D:X3)向内网机器(A:X)发送数据(同IP, 同端口号)
    8. 外网机器(C:Z)才可以通过NAT(D:X4)向内网机器(A:X)发送数据(同IP, 同端口号)

## 检测NAT的类型(需要公网机器(B:Y), 公网机器(C:Z))
0. 内网机器(A:X)给公网机器(B:Y)发送数据
1. 公网机器(B:Y)返回内网机器(A:X)的地址: D:X1
2. 如果 D == A && X1 == X, 则为公网 IP
3. 否则, 公网机器(C:Z)通过NAT(D:X1)给内网机器(A:X)发送消息(IP和端口号都不同)
4. 如果内网机器(A:X)可以收到消息，则为 完全圆锥形 NAT
5. 否则, 公网机器(B:Z)通过NAT(D:X1)给内网机器(A:X)发送消息(IP相同, 端口号不同)
6. 如果内网机器(A:X)可以收到消息，则为 受限圆锥形 NAT
7. 否则, 内网机器(A:X)给公网机器(C:Z)发送数据
8. 公网机器(C:Z)返回内网机器的地址: D:X2
9. 如果 X1 == X2, 则为 端口受限圆锥形 NAT, 否则为对称 NAT

## P2P 通信
### 通过公共机器直接通信(不受任何NAT类型的限制, 但效率比较低, 会给服务器造成很大的消耗)
* 内网机器(A)与公网机器器(C)相连
* 内网机器(B)与公网机器器(C)相连
* 内网机器(A)将数据发给公网机器(C), 公网机器(C)再将数据发送给内网机器(B)
* 内网机器(B)将数据发给公网机器(C), 公网机器(C)再将数据发送给内网机器(A)

### 机器(A:X)和机器(B:Y)都是公网IP
两个机器可以直接相连

### 机器(A:X)或机器(B:Y)只有一个是公网IP
* 假设, 机器(A:X)有公网IP
* 通过 机器(B:Y) => NAT(E:Q) => 机器(A:X) 发送数据, 因为机器(A:X)为公网IP
* 此时 机器(A:X) => NAT(E:Q) => 机器(B:Y) 也通了

### 机器(A:X)和机器(B:Y)位于不同 NAT, 有一个公网机器(C:Y)
1. 机器(A:X)或机器(B:Y)所属的 NAT 为完全锥形 NAT
    * 假定机器(A:X)所属的 NAT 为完全锥形 NAT
    * 通过 机器(A:X) => NAT(D:P) => 公网机器(C:Z) 发送数据
    * 通过 机器(B:Y) => NAT(E:Q) => 公网机器(C:Z) 发送数据
    * 通过 公网机器(C:Z) => NAT(E:Q) => 机器(B:Y) 发送数据NAT(D:P)
    * 通过 机器(B:Y) => NAT(E:R) => NAT(D:P) => 机器(A:X) 发送数据(完全锥形 NAT)
    * 此时 机器(A:X) => NAT(D:P) => NAT(E:R) => 机器(B:Y) 也通了
2. 机器(A:X)或机器(B:Y)所属的 NAT 为受限锥形 NAT
    * 假定机器(A:X)所属的 NAT 为受限锥形 NAT
    * 通过 机器(A:X) => NAT(D:P) => 公网机器(C:Z) 发送数据
    * 通过 机器(B:Y) => NAT(E:Q) => 公网机器(C:Z) 发送数据
    * 通过 公网机器(C:Z) => NAT(D:P) => 机器(A:X) 发送数据NAT(E:Q)
    * 通过 公网机器(C:Z) => NAT(E:Q) => 机器(B:Y) 发送数据NAT(D:P)
    * 通过 机器(A:X) => NAT(D:P) => NAT(E:Q) 发送数据, 会被丢弃
        * 因为NAT(E:Q) 不知道数据要发往哪里
        * 但 NAT(E) => NAT(D:P) => 机器(A:X) 这条路已经通了,
        * 此时, NAT(E)的任何端口号都通过 NAT(D:P)=>机器(A:X) 发送数据(受限锥形 NAT)
    * 通过 机器(B:Y) => NAT(E:R) => NAT(D:P) => 机器(A:X) 发送数据, 会成功,
        * 因为NAT(E) => NAT(D:P) => 机器(A:X) 是通的
    * 此时, 机器(A:X) => NAT(D:P) => NAT(E:R) => 机器(B:Y) 也通了
3. 机器(A:X)和机器(B:Y)所属的 NAT 均为端口受限锥形 NAT
    * 通过 机器(A:X) => NAT(D:P) => 公网机器(C:Z) 发送数据
    * 通过 机器(B:Y) => NAT(E:Q) => 公网机器(C:Z) 发送数据
    * 通过 公网机器(C:Z) => NAT(D:P) => 机器(A:X) 发送数据NAT(E:Q)
    * 通过 公网机器(C:Z) => NAT(E:Q) => 机器(B:Y) 发送数据NAT(D:P)
    * 通过 机器(A:X) => NAT(D:P) => NAT(E:Q) 发送数据, 会被丢弃
        * 因为NAT(E:Q) 不知道数据要发往哪里
        * 但 NAT(E:Q) => NAT(D:P) => 机器(A:X) 这条路已经通了(端口受限锥形 NAT)
    * 通过 机器(B:Y) => NAT(E:Q) => NAT(D:P) => 机器(A:X) 发送数据, 会成功,
        * 因为机器NAT(E:Q) => NAT(D:P) => 机器(A:X) 是通的
    * 此时, 机器(A:X) => NAT(D:P) => NAT(E:Q) => 机器(B:Y)  也通了
4. 机器(A:X)和机器(B:Y)所属的 NAT 均为对称 NAT
    * 无法穿透
    * 可以考虑通过公网机器发送数据
5. 机器(A:X)和机器(B:Y)所属的 NAT 一个为对称 NAT，一个为端口受限的 NAT
    * 无法穿透
    * 可以考虑通过公网机器发送数据

# 计算机网络
## 基础知识
```
硬盘: 1T = 1000G = 1000 * 1000 * 1000 * 1000B = ... / 1024 / 1024 /1024 GB = 931GB
网卡: 1000M = 1000Mbps = 125MB (网速也一样)

  带宽: 网速, 上限由网卡控制
吞吐量: 有效数据的速度, 速度小于带宽
  延时: 客户端发送数据到收到数据的时差

kmg(1000), KMG(1024), B(字节), b(位)

## 网络接口层(帧)(以太网)
### 为什么不能去掉MAC(48位, 一般无法改变)
1. 网络协议分层, 不同层实现不同的功能, 交换机会使用其传递数据
2. 直接使用IP其实也可以, 这个就是历史原因了

### 集线器: 无脑转发数据到所有出口(很少使用了)
* 机器收到不是自己的数据将丢弃

### 交换机: 将指定数据直接发送到目标机器
* 利用MAC地址表发送数据到指定机器, 找不到时, 将发送数据给所有机器
* 到达的数据需要知道目标的MAC地址
* 机器数量过大时, 会很难处理

### 通过MAC可以区分是单播还是(组播或广播)

## 网络层(数据包)
###为什么不能去掉IP(32位)
1. 为了划分子网, 方便路由, 传送数据到子网

* 主机号都为 0 表明网络地址
* 主机号都为 1 表明广播地址
* 互联网上只能使用公有IP
* 子网: 由 IP 和子网掩码(主机号都为0)确定
* 默认网关: 用于路由
* ARP: IP => MAC (ARP 缓存表)

### ICMP(不使用端口号, 和 TCP UDP IGMP处于同一级)
* 传输控制协议
* ping 实现

IGMP

1.0.0.0~126.255.255.255   -- a类
128.0.0.0~191.255.255.255 -- b类
192.0.0.0~223.255.255.255 -- c类
224.0.0.0~239.255.255.255 -- 组播地址
240.0.0.0~255.255.255.254 -- 保留
10.0.0.0/8                -- a类私有
172.16.0.0/12             -- b类私有
192.168.0.0/16            -- c类私有
127.0.0.0/8               -- 本机使用
224.0.0.0/24              -- 本网络组播
239.0.0.0/8               -- 私有组播

0.0.0.0                   -- 使用 DHCP 获取 IP 时, 填的源 IP
255.255.255.255           -- 使用 DHCP 获取 IP 时, 填的目标 IP

路由器: 将指定数据直接发送到目标(可能需要再次转发)
* 利用路由表发送数据到指定机器, 找不到将发送到路由器的默认网关
* 到达的数据需要知道目标的 IP 地址

单播(一般的网络服务都是单播)
1. 源IP和目标IP属于同一个子网时, 利用arp获取目标的MAC, 然后利用交换机发送数据到指定机器
2. 否则, 利用arp获取默认网关的MAC, 然后利用交换机发送数据到默认网关
3. 默认网关会修改源MAC, 然后再查找下一跳或指定机器

数据传输过程中, 原 IP 和目标 IP 一般不变, 除了, NAT 等

组播(IGMP 直播 电视)
1. 组播源注册: 服务器(组播源IP)向中介机构(RP)注册组播IP(2.2.2.2)
2. 客户端向中介机构(RP)申请加入组播IP: 生成基于中介机构(RP)的树(RPT), 同时获取组播源IP
3. 客户端向服务器(组播源IP)申请加入组播IP: 生成基于源的树(SPT), 废弃掉 RPT(SPT路径更优)
4. 服务器通过SPT, 向所有的注册组播IP的用户发送数据
    * 源IP和MAC填自己的数据
    * 目的IP为组播地址
    * 目的MAC为: 01:00:5e + 组播IP 地址低 23 bit(区分单播 组播 广播)
    * 由于目的IP为组播IP, 无法获取确切的MAC, 指定某一机器, 所以只能采用广播向所有机器发送数据
5. 客户端或者路由器通过接收到的数据的组播地址来确定是不是自己所需要的数据

广播(ARP, 使用DHCP申请IP地址时)
利用集线器发送所有数据到当前网络的所有机器

任播: 最近或最合适的客户

### 传输层(段)(TCP UDP)
端口号(16位)
* [0, 1024)      公认端口号, 需要 root 启动, 比如 80
* [1024, 32768)  注册端口, 可以自己注册一些常用服务
* [32768, 60990) 动态端口, 进程未指定端口号时, 将从这个范围内获取一个端口号
                 可通过文件 /proc/sys/net/ipv4/ip_local_port_range 获取
* [60990, 65535) 可能有特殊用途

TCP 有广播和组播一说吗?

TCP
* 三次握手
    1. 客户端将随机的序列号发送给服务端(SYN)(CLOSED -> SYN-SENT)
    2. 服务端收到数据后, 知道了客户端的序列号
       服务端将自己随机的序列号以及客户端序列号加一返回给客户端(SYN ACK)(LISTEN -> SYN-RCVD)
    3. 客户端收到数据后, 认为连接已经建立成功了
       客户端将服务端的序列号加一发送给服务端(ACK)(SYN-SENT -> ESTABLISHED)
       此时客户端就可以发送数据了
    4. 服务端收到数据后, 认为连接已经建立成功了, 可以发送数据了(SYN-RCVD -> ESTABLISHED)
* 四次挥手(服务端也可以先发起)
    1. 客户端发送 FIN(ESTABLISHED -> FIN-WAIT-1)
    2. 服务端收到 FIN(ESTABLISHED -> CLOSE-WAIT
       服务端向客户端发送确认
       客户端收到确认(FIN-WAIT-1 -> FIN-WAIT-2)
       此时, 客户端不能再向服务端发送数据, 但服务端可以向客户端发送数据
    3. 服务端发送 FIN(CLOSE-WAIT -> LAST-ACK)
    4. 客户端收到 FIN(FIN-WAIT-2 -> TIME-WAIT)
       向服务端发送确认
       等待 2MSL, 客户端(TIME-WAIT -> CLOSED)
       (为了处理服务端可能收不到确认的情况, 也为了让游离在外的包尽可能消亡)
       服务端收到确认(LAST-ACK -> CLOSED)
* 为什么需要序列号(32位):
    * 数据包需要被确认, 而包可能会被拆, 需要使用序列号来判断确认到哪个数据包了
    * 数据包可能会丢失, 需要使用序列号来判断需要重发哪个数据包
    * 数据包可能会重复, 需要使用序列号来丢弃重复的数据包
    * 数据包到达的时间, 顺序可能不同, 需要使用序列号排序
* 初始序列号为什么随机生成:
    * 随机序列号很难猜测, 为了避免其他人冒充对方报文, 或 伪造reset报文, 影响正常的使用
    * 为了避免旧数据影响新连接, 例如
        客户端连接服务端
        客户端向服务端发送一个数据包(由于网络问题, 数据包发了两次, 有游离包在网络中)
        客户端向服务端发送 reset, 立刻退出(没有经过正常的四次挥手)
        此时, 客户端使用相同的IP和端口号重新连服务端, 并成功
        此时, 游离的包到达服务端,
        如果初始话序列号相同, 此游离包  在服务端的接收窗口内, 会被误认为是新的数据包, 而返回确认
        如果初始话序列号不同, 此游离包不在服务端的接收窗口内, 会被丢弃(极大概率)
* 序列号回绕:
    初始化序列号每4微妙增长一个, 即, 每秒增长 250000 个, 循环一次需要 4 个多小时
    远大于数据包的最大分段的时间(MSL)(一般两分钟)
    所以不会对数据造成影响, 而发送的数据大小不受序列号的限制
* 所有有数据的报文都需要ack, 也可能会重传
* 报文类型
    *   SYN: 三次握手(需要确认, 可能会重传)
    *   FIN: 四次挥手(需要确认, 可能会重传)
    *  data: 数据报文(需要确认, 可能会重传)
    * reset: 重置(不需要确认,   不会重传)(发送重置后, 内核会销毁掉所有的连接信息, 对方的确认没意义)
    *   ACK: 确认(不需要确认,   不会重传)(如果确认的话就死循环了)(不包含数据)(下一个期望的序列号)
    *   ACK: 确认(  需要确认, 可能会重传)(如果确认的话就死循环了)(  包含数据)(下一个期望的序列号)
* SYN 和 FIN 为什么占一个序列号: 为了处理可能的重传
* reset 发送场景:
    * 客户端连接服务端, 而服务端的此端口没有被监听, 会返回 rst
    * 客户端连接服务端, 被防火墙连接(不一定, 可能收到 ICMP 错误)
    * 当接收缓冲区内还有数据, 但关闭了改 socket, 会向对方发送 rst
    * 向已关闭的 socket 发送数据, 对方会返回 rst
* 为什么需要三次握手:
    1. 一次握手: 客户端发送连接, 即认为连接成功, 服务端收到连接, 即认为连接成功
                 由于客户端无法知道服务端的序列号, 也就没有序列号这一说了,
                 TCP 的包不能拆分了(无法确认数据包的先后), 也就没有确认机制了(无法确认),
                 直接相当于 UDP 了
    2. 两次握手: 客户端发送连接
                 服务端收到连接, 并返回确认, 此时, 服务端认为连接成功了
                 客户端收到确认, 认为连接成功了
                 * 如果客户端的连接包丢失了, 由于无法收到确认包, 所以会重新发送连接包
                 * 如果服务端的确认包丢失了, 服务端感知不到这种情况,
                     由于客户端接收不到确认包, 所以客户端仍然会重新发送连接包
                 * 旧的连接包会影响服务端的使用, 例如,
                        客户端连接服务端(由于网络问题, 连接包发了两次, 有一个游离包在网络中)
                        服务端返回确认
                        客户端收到确认, 向服务端发送 reset, 立刻退出(没有经过正常的四次挥手)
                        此时, 游离的包到达服务端, 服务端认为是新的连接, 向客户端发送确认
                        客户端收到子虚乌有的确认直接丢弃了
                        (客户端可以考虑发送 reset 让服务端释放资源也成, 客户端不存在或不可达也还是有问题)
                        服务端直到发送数据, 才能知道连接不成功(不发送的话, 一直浪费)
    3. 三次握手: 客户端发送连接
                 服务端收到连接, 并返回确认
                 客户端收到确认, 并返回确认, 认为连接成功了
                 服务端收到确认, 认为连接成功了
                 * 如果客户端的连接包丢失了, 由于无法收到确认包, 所以会重新发送
                 * 如果服务端的确认包丢失了, 由于无法收到确认包, 所以会重新发送
                 * 旧的连接包不会影响服务端的使用, 例如,
                        客户端连接服务端(由于网络问题, 连接包发了两次, 有一个游离包在网络中)
                        服务端返回确认
                        客户端收到确认, 向服务端发送 reset, 立刻退出(没有经过正常的四次挥手)
                        此时, 游离的包到达服务端, 服务端认为是新的连接, 向客户端发送确认
                        客户端收到子虚乌有的确认直接丢弃了(客户端也可以考虑发送 reset)
                        服务端没收到确认消息, 会多次发送, 最终放弃, 释放资源
    4. 其实, 两次握手也能成功, 兼顾效率和可靠性, 选择三次握手(主要是网络出问题的情况)
      * 三次握手保证双方都知道对方是可收可发的(保证是可用的, 不一定是可靠的)


UDP

### 应用层(消息)(HTTP DNS SSH DHCP)
DHCP(广播, UDP)
1. 新机器(IP: 0.0.0.0)发送信息给当前网络(IP: 255.255.255.255)的所有机器(不会跨网关)
2. 包含 DHCP 服务器的机器发送新的 IP 给新机器(IP: 255.255.255.255)
3. 新机器(IP: 新IP)发送确认信息给 DHCP 服务器

### 浏览器输入 https://www.bing.com 后的行为
1. 解析 www.bing.com. 找到域名 bing.com. 查找对应 IP, 顺序查找,
    * DNS cache
    * 本地 host 文件
    * DNS 服务器(8.8.8.8, 找不到的话, 会递归查找, 直到根域名服务器)
2. 使用目标 IP 和端口号三次握手
3. TLS 商讨密钥的方案
4.

### 防火墙
包过滤防火墙: 过滤某些不必要的流量, 依靠 IP 端口号 协议类型(ICMP)
代理防火墙: http 代理
            socks 代理

真正的路由器应该只有路由的功能

### NAT(Network Address Translation)
主要目的是解决 IPv4 地址短缺的问题以及安全

分类
* 基础NAT: 只修改 IP
* NAPT: 修改IP和端口号
	1. 完全圆锥形NAT(Full cone NAT)
		1. 如果内网机器(A:X)通过NAT(D:X1)发送数据给公网机器(B:Y)
		2. 那么, 内网机器(A:X)发往任何机器的任何端口号的数据都会通过NAT(D:X1)发送
		3. 任何外网机器的任何端口号都可通过NAT(D:X1)向内网机器(A:X)发送数据(任意IP, 任意端口号)
	2. 受限圆锥形NAT(Address-Restricted cone NAT)
		1. 如果内网机器(A:X)通过NAT(D:X1)发送数据给公网机器(B:Y)
		2. 那么, 内网机器(A:X)发往任何机器的任何端口号的数据都会通过NAT(D:X1)发送
		3. 外网机器(B)的任何端口号都可通过NAT(D:X1)向内网机器(A:X)发送数据(同IP, 任意端口号)
	3. 端口受限圆锥形NAT(port-Restricted cone NAT)
		1. 如果内网机器(A:X)通过NAT(D:X1)发送数据给公网机器(B:Y)
		2. 那么, 内网机器(A:X)发往任何机器的任何端口号的数据都会通过NAT(D:X1)发送
		3. 外网机器(B:Y)才可以通过NAT(D:X1)向内网机器(A:X)发送数据(同IP, 同端口号)
	4. 对称NAT(Symmetric NAT)
		1. 如果内网机器(A:X)通过NAT(D:X1)发送数据给公网机器(B:Y)
		2. 那么, 内网机器(A:X)通过NAT(D:X2)发送数据给公网机器(B:Z), X1 != X2 (IP 相同, 端口号不同)
		3. 那么, 内网机器(A:X)通过NAT(D:X3)发送数据给公网机器(C:Y), X1 != X3 (IP 不同, 端口号相同)
		4. 那么, 内网机器(A:X)通过NAT(D:X4)发送数据给公网机器(C:Z), X1 != X4 (IP 不同, 端口号不同)
		5. 外网机器(B:Y)可以通过NAT(D:X1)向内网机器(A:X)发送数据(同IP, 同端口号)
		6. 外网机器(B:Z)可以通过NAT(D:X2)向内网机器(A:X)发送数据(同IP, 同端口号)
		7. 外网机器(C:Y)可以通过NAT(D:X3)向内网机器(A:X)发送数据(同IP, 同端口号)
		8. 外网机器(C:Z)可以通过NAT(D:X4)向内网机器(A:X)发送数据(同IP, 同端口号)

检测NAT的类型
0. 内网机器(A:X)给公网机器(B:Y)发送数据
1. 公网机器(B:Y)返回内网机器(A:X)的地址: D:X1
2. 如果 D == A && X1 == X, 则为公网 IP
3. 否则, 公网机器(C:Z)通过NAT(D:X1)给内网机器(A:X)发送消息(IP和端口号都不同)
4. 如果内网机器(A:X)可以收到消息，则为 完全圆锥形 NAT，
5. 否则, 公网机器(B:Z)通过NAT(D:X1)给内网机器(A:X)发送消息(IP相同, 端口号不同)
6. 如果内网机器(A:X)可以收到消息，则为 受限圆锥形 NAT,
7. 否则, 内网机器(A:X)给公网机器(C:Z)发送数据
8. 公网机器(C:Z)返回内网机器的地址: D:X2
9. 如果 X1 == X2, 则为 端口受限圆锥形 NAT, 否则为对称 NAT

## p2p 通信
### 机器(A:X)和机器(B:Y)都是公网IP
两个机器可以直接相连

### 机器(A:X)或机器(B:Y)只有一个是公网IP
* 假设, 机器(A:X)有公网IP
* 通过 机器(B:Y) => NAT(E:Q) => 机器(A:X) 发送数据, 因为机器(A:X)为公网IP
* 此时 机器(A:X) => NAT(E:Q) => 机器(B:Y) 也通了

### 机器(A:X)和机器(B:Y)位于不同 NAT, 有一个公网机器(C:Y)
1. 机器(A:X)或机器(B:Y)所属的 NAT 为完全锥形 NAT
	* 假定机器(A:X)所属的 NAT 为完全锥形 NAT
	* 通过 机器(A:X) => NAT(D:P) => 公网机器(C:Z) 发送数据
	* 通过 机器(B:Y) => NAT(E:Q) => 公网机器(C:Z) 发送数据
	* 通过 公网机器(C:Z) => NAT(E:Q) => 机器(B:Y) 发送NAT(D:P)数据
	* 通过 机器(B:Y) => NAT(E:R) => NAT(D:P) => 机器(A:X) 发送数据(完全锥形 NAT)
	* 此时 机器(A:X) => NAT(D:P) => NAT(E:R) => 机器(B:Y) 也通了
2. 机器(A:X)或机器(B:Y)所属的 NAT 为受限锥形 NAT
	* 假定机器(A:X)所属的 NAT 为受限锥形 NAT
	* 通过 机器(A:X) => NAT(D:P) => 公网机器(C:Z) 发送数据
	* 通过 机器(B:Y) => NAT(E:Q) => 公网机器(C:Z) 发送数据
	* 通过 公网机器(C:Z) => NAT(D:P) => 机器(A:X) 发送NAT(E:Q)数据
	* 通过 公网机器(C:Z) => NAT(E:Q) => 机器(B:Y) 发送NAT(D:P)数据
	* 通过 机器(A:X) => NAT(D:P) => NAT(E:Q) => 机器(B:Y) 发送数据, 会失败
		* 因为机器(B:Y) => NAT(E:Q) => NAT(D:P) => 机器(A:X) 未发送过消息
		* 但 NAT(E) => NAT(D:P) => 机器(A:X) 这条路已经通了,
		* 此时, NAT(E)的任何端口号都通过 NAT(D:P)=>机器(A:X) 发送数据(受限锥形 NAT)
	* 通过 机器(B:Y) => NAT(E:R) => NAT(D:P) => 机器(A:X) 发送数据, 会成功,
		* 因为机器(A:X) => NAT(D:P) => NAT(E) 路是通的
	* 此时, 机器(A:X) => NAT(D:P) => NAT(E:R) => 机器(B:Y) 也通了
3. 机器(A:X)和机器(B:Y)所属的 NAT 均为端口受限锥形 NAT
	* 通过 机器(A:X) => NAT(D:P) => 公网机器(C:Z) 发送数据
	* 通过 机器(B:Y) => NAT(E:Q) => 公网机器(C:Z) 发送数据
	* 通过 公网机器(C:Z) => NAT(D:P) => 机器(A:X) 发送NAT(E:Q)数据
	* 通过 公网机器(C:Z) => NAT(E:Q) => 机器(B:Y) 发送NAT(D:P)数据
	* 通过 机器(A:X) => NAT(D:P) => NAT(E:Q) => 机器(B:Y) 发送数据, 会失败,
		* 因为机器(B:Y) => NAT(E:Q) => NAT(D:P) 未发送过消息
		* 但 NAT(E:Q) => NAT(D:P) => 机器(A:X) 这条路已经通了(端口受限锥形 NAT)
	* 通过 机器(B:Y) => NAT(E:Q) => NAT(D:P) => 机器(A:X) 发送数据, 会成功,
		* 因为机器NAT(E:Q) => NAT(D:P) => 机器(A:X) 是通的
	* 此时，机器(A:X) => NAT(D:P) => NAT(E:Q) => 机器(B:Y)  也通了
4. 机器(A:X)和机器(B:Y) 所属的 NAT 均为对称 NAT: 无法穿透
5. 机器(A:X)和机器(B:Y)所属的 NAT 一个为对称 NAT，一个为端口受限的 NAT: 无法穿透


p2p 通信(客户端(A)位于NAT(a)后, 客户端(B)位于NAT(b)后, 服务器(C)位于公网, 客户端(A)和客户端(B)要通信)
1. 通过服务器(c)直接通信:(不受任何NAT类型的限制, 但效率比较低, 会给服务器造成很大的消耗)(TCP)
	客户端(A)通过NAT(a)与服务器(C)相连
	客户端(B)通过NAT(b)与服务器(C)相连
	客户端(A)将数据发给服务器(C), 服务器(C)再将数据发送给客户端(B)
	客户端(B)将数据发给服务器(C), 服务器(C)再将数据发送给客户端(A)

UDP-打洞(客户端A位于局域网a, 客户端B位于局域网b, 服务器C位于公网, 客户端A和客户端B要通信)
1. 全锥形NAT

	假设, 内网机器(A:X), 公网机器(B:Y), 公网机器(C:Z)
如果内网机器(A:X)发送数据给公网机器(B:Y), 则映射的公网接口(D:X1)
如果内网机器(A:X)发送数据给公网机器(C:Z), 则映射的公网接口(D:X2)

## UDP hole punching
	### 方法
假设有两个客户 A:X B:Y 位于不同的 NAT 中，还有一个处于公网的服务器 C:Z

假设: X:x(私有) -> X1:x1(NAT) -> Y1:y1(公有)
此时, 如果, 新连接: X:x(私有) -> X2:x2(NAT) -> Y2:y2(公有)(X1 == X2)
1. 对于任何 Y1:y1 和 Y2:y2, X1:x1 都等于 X2:x2, 即: X:x 发向任何地址的数据都使用 NAT 的 X1:x1 (任何地址)
2. 如果 Y1 == Y2, 则 X1:x1 == X2:x2, 即: X:x 只有发往 Y1 的数据才使用 NAT 的 X1:x1 (IP 相同)
3. 如果 Y1:y1 == Y2:y2, 则 X1:x1 == X2:x2, 即: X:x 只有发往 Y1:y1 的数据才使用 NAT 的 X1:x1 (IP 和 端口号都相同)
此时, 如果, Y3:y3(私有) -> X1:x1(NAT) -> X:x(私有)
1. 对于任何 Y3:y3, 都可以发送成功(全锥形NAT)(任意)
2. 只要 Y3 == Y1, 就可以发送成功(受限圆锥形NAT)(IP相同)
3. 只有 Y3:y3 == Y1:y1, 才可以发送成功(端口受限圆锥形NAT)(IP和端口号都相同)
4.

链路层广播

MTU 最大传输单元 (链路层)

p2p

网络层:

强主机模式: 数据包必须和对应网络接口对上
弱主机模式: 数据包和任一网络接口对上即可


## 网络
* [0, 1024)      公认端口号, 需要 root 启动, 比如 80
* [1024, 32768)  注册端口, 可以自己注册一些常用服务
* [32768, 60990) 动态端口, 进程未指定端口号时, 将从这个范围内获取一个端口号
                 可通过文件 /proc/sys/net/ipv4/ip_local_port_range 获取
* [60990, 65535)


防火墙:
包过滤防火墙: 过滤某些不必要的流量, 依靠 IP 端口号 协议类型(ICMP)
代理防火墙: http 代理
            socks 代理

真正的路由器应该只有路由的功能

# NAT
## NAT(Network Address Translation)
主要目的是解决 IPv4 地址短缺的问题

## 分类
* 基础NAT: 只修改 IP
* NAPT: 修改IP和端口号
	1. 完全圆锥形NAT(Full cone NAT)
		1. 如果内网机器(A:X)通过NAT(D:X1)发送数据给公网机器(B:Y)
		2. 那么, 内网机器(A:X)发往任何机器的任何端口号的数据都会通过NAT(D:X1)发送
		3. 任何外网机器的任何端口号都可通过NAT(D:X1)向内网机器(A:X)发送数据(任意IP, 任意端口号)
	2. 受限圆锥形NAT(Address-Restricted cone NAT)
		1. 如果内网机器(A:X)通过NAT(D:X1)发送数据给公网机器(B:Y)
		2. 那么, 内网机器(A:X)发往任何机器的任何端口号的数据都会通过NAT(D:X1)发送
		3. 外网机器(B)的任何端口号都可通过NAT(D:X1)向内网机器(A:X)发送数据(同IP, 任意端口号)
	3. 端口受限圆锥形NAT(port-Restricted cone NAT)
		1. 如果内网机器(A:X)通过NAT(D:X1)发送数据给公网机器(B:Y)
		2. 那么, 内网机器(A:X)发往任何机器的任何端口号的数据都会通过NAT(D:X1)发送
		3. 外网机器(B:Y)才可以通过NAT(D:X1)向内网机器(A:X)发送数据(同IP, 同端口号)
	4. 对称NAT(Symmetric NAT)
		1. 如果内网机器(A:X)通过NAT(D:X1)发送数据给公网机器(B:Y)
		2. 那么, 内网机器(A:X)通过NAT(D:X2)发送数据给公网机器(B:Z), X1 != X2 (IP 相同, 端口号不同)
		3. 那么, 内网机器(A:X)通过NAT(D:X3)发送数据给公网机器(C:Y), X1 != X3 (IP 不同, 端口号相同)
		4. 那么, 内网机器(A:X)通过NAT(D:X4)发送数据给公网机器(C:Z), X1 != X4 (IP 不同, 端口号不同)
		5. 外网机器(B:Y)可以通过NAT(D:X1)向内网机器(A:X)发送数据(同IP, 同端口号)
		6. 外网机器(B:Z)可以通过NAT(D:X2)向内网机器(A:X)发送数据(同IP, 同端口号)
		7. 外网机器(C:Y)可以通过NAT(D:X3)向内网机器(A:X)发送数据(同IP, 同端口号)
		8. 外网机器(C:Z)可以通过NAT(D:X4)向内网机器(A:X)发送数据(同IP, 同端口号)

## 检测NAT的类型
0. 内网机器(A:X)给公网机器(B:Y)发送数据
1. 公网机器(B:Y)返回内网机器(A:X)的地址: D:X1
2. 如果 D == A && X1 == X, 则为公网 IP
3. 否则, 公网机器(C:Z)通过NAT(D:X1)给内网机器(A:X)发送消息(IP和端口号都不同)
4. 如果内网机器(A:X)可以收到消息，则为 完全圆锥形 NAT，
5. 否则, 公网机器(B:Z)通过NAT(D:X1)给内网机器(A:X)发送消息(IP相同, 端口号不同)
6. 如果内网机器(A:X)可以收到消息，则为 受限圆锥形 NAT，否则,
7. 内网机器(A:X)给公网机器(C:Z)发送数据
8. 公网机器(C:Z)返回内网机器的地址: D:X2
9. 如果 X1 == X2, 则为 端口受限圆锥形 NAT, 否则为对称 NAT

## p2p 通信
### 机器(A:X)和机器(B:Y)都是公网IP
两个机器可以直接相连

### 机器(A:X)或机器(B:Y)只有一个是公网IP
* 假设, 机器(A:X)有公网IP
* 由于, 机器(A:X)有公网IP, 所以机器(B:Y) => NAT(E:Q) => 机器(A:X) 可以发送数据
* 由于, 机器(B:Y) => NAT(E:Q) => 机器(A:X) 连接过, 所以, 机器(A:X) => NAT(E:Q) => 机器(B:Y) 也通了

### 机器(A:X)和机器(B:Y)位于不同 NAT, 有一个公网机器(C:Y)
1. 机器(A:X)或机器(B:Y)所属的 NAT 为完全锥形 NAT
	* 假定机器(A:X)所属的 NAT 为完全锥形 NAT
	* 通过 机器(A:X) => NAT(D:P) => 公网机器(C:Z) 发送数据
	* 通过 机器(B:Y) => NAT(E:Q) => 公网机器(C:Z) 发送数据
	* 通过 公网机器(C:Z) => NAT(E:Q) => 机器(B:Y) 发送NAT(D:P)数据
	* 此时 机器(B:Y) => NAT(E:R) => NAT(D:P) => 机器(A:X) 就通了(完全锥形 NAT)
	* 此时 机器(A:X) => NAT(D:P) => NAT(E:R) => 机器(B:Y) 也通了
2. 机器(A:X)或机器(B:Y)所属的 NAT 为受限锥形 NAT
	* 假定机器(A:X)所属的 NAT 为受限锥形 NAT
	* 通过 机器(A:X) => NAT(D:P) => 公网机器(C:Z) 发送数据
	* 通过 机器(B:Y) => NAT(E:Q) => 公网机器(C:Z) 发送数据
	* 通过 公网机器(C:Z) => NAT(D:P) => 机器(A:X) 发送NAT(E:Q)数据
	* 通过 公网机器(C:Z) => NAT(E:Q) => 机器(B:Y) 发送NAT(D:P)数据
	* 通过 机器(A:X) => NAT(D:P) => NAT(E:Q) => 机器(B:Y) 发送数据, 会失败
		* 因为机器(B:Y) => NAT(E:Q) => NAT(D:P) 未发送过消息
		* 但 NAT(E) => NAT(D:P) => 机器(A:X) 这条路已经通了,
		* 此时, NAT(E)的任何端口号都通过 NAT(D:P)=>机器(A:X) 发送数据(受限锥形 NAT)
	* 通过 机器(B:Y) => NAT(E:R) => NAT(D:P) => 机器(A:X) 发送数据, 会成功,
		* 因为机器(A:X) => NAT(D:P) => NAT(E) 路是通的
		* 此时, 机器(A:X) => NAT(D:P) => NAT(E:R) => 机器(B:Y) 也通了
3. 机器(A:X)和机器(B:Y)所属的 NAT 均为端口受限锥形 NAT
	* 通过 机器(A:X) => NAT(D:P) => 公网机器(C:Z) 发送数据
	* 通过 机器(B:Y) => NAT(E:Q) => 公网机器(C:Z) 发送数据
	* 通过 公网机器(C:Z) => NAT(D:P) => 机器(A:X) 发送NAT(E:Q)数据
	* 通过 公网机器(C:Z) => NAT(E:Q) => 机器(B:Y) 发送NAT(D:P)数据
	* 通过 机器(A:X) => NAT(D:P) => NAT(E:Q) => 机器(B:Y) 发送数据, 会失败,
		* 因为机器(B:Y) => NAT(E:Q) => NAT(D:P) 未发送过消息
		* 但 NAT(E:Q) => NAT(D:P) => 机器(A:X) 这条路已经通了(端口受限锥形 NAT)
	* 通过 机器(B:Y) => NAT(E:Q) => NAT(D:P) => 机器(A:X) 发送数据, 会成功,
		* 因为机器NAT(E:Q) => NAT(D:P) => 机器(A:X) 是通的
	* 此时，机器(A:X) => NAT(D:P) => NAT(E:Q) => 机器(B:Y)  也通了
4. 机器(A:X)和机器(B:Y) 所属的 NAT 均为对称 NAT: 无法穿透
5. 机器(A:X)和机器(B:Y)所属的 NAT 一个为对称 NAT，一个为端口受限的 NAT: 无法穿透


1. 客户 A:X 通过 D:P 多次发送数据给 C:Z
2. 客户 B:Y 通过 E:Q 多次发送数据给 C:Z
3. 服务器 C:Z 将 A:X 的映射的 D:P 多次发送给 B:Y
4. 服务器 C:Z 将 B:Y 的映射的 E:Q 多次发送给 A:X
5. 客户 A:X 多次发送数据给 E:Q
6. 在此之后，客户 B:Y   可以通过 E:Q --> D:P 给客户 A:X 发送消息
7. 在此之后，客户 A:X 也可以通过 D:P --> E:Q 给客户 B:Y 发送消息



p2p 通信(客户端(A)位于NAT(a)后, 客户端(B)位于NAT(b)后, 服务器(C)位于公网, 客户端(A)和客户端(B)要通信)
1. 通过服务器(c)直接通信:(不受任何NAT类型的限制, 但效率比较低, 会给服务器造成很大的消耗)(TCP)
	客户端(A)通过NAT(a)与服务器(C)相连
	客户端(B)通过NAT(b)与服务器(C)相连
	客户端(A)将数据发给服务器(C), 服务器(C)再将数据发送给客户端(B)
	客户端(B)将数据发给服务器(C), 服务器(C)再将数据发送给客户端(A)


UDP-打洞(客户端A位于局域网a, 客户端B位于局域网b, 服务器C位于公网, 客户端A和客户端B要通信)
1. 全锥形NAT

	假设, 内网机器(A:X), 公网机器(B:Y), 公网机器(C:Z)
如果内网机器(A:X)发送数据给公网机器(B:Y), 则映射的公网接口(D:X1)
如果内网机器(A:X)发送数据给公网机器(C:Z), 则映射的公网接口(D:X2)

## UDP hole punching
	### 方法
假设有两个客户 A:X B:Y 位于不同的 NAT 中，还有一个处于公网的服务器 C:Z

假设: X:x(私有) -> X1:x1(NAT) -> Y1:y1(公有)
此时, 如果, 新连接: X:x(私有) -> X2:x2(NAT) -> Y2:y2(公有)(X1 == X2)
1. 对于任何 Y1:y1 和 Y2:y2, X1:x1 都等于 X2:x2, 即: X:x 发向任何地址的数据都使用 NAT 的 X1:x1 (任何地址)
2. 如果 Y1 == Y2, 则 X1:x1 == X2:x2, 即: X:x 只有发往 Y1 的数据才使用 NAT 的 X1:x1 (IP 相同)
3. 如果 Y1:y1 == Y2:y2, 则 X1:x1 == X2:x2, 即: X:x 只有发往 Y1:y1 的数据才使用 NAT 的 X1:x1 (IP 和 端口号都相同)
此时, 如果, Y3:y3(私有) -> X1:x1(NAT) -> X:x(私有)
1. 对于任何 Y3:y3, 都可以发送成功(全锥形NAT)(任意)
2. 只要 Y3 == Y1, 就可以发送成功(受限圆锥形NAT)(IP相同)
3. 只有 Y3:y3 == Y1:y1, 才可以发送成功(端口受限圆锥形NAT)(IP和端口号都相同)

链路层广播

MTU 最大传输单元 (链路层)

p2p

网络层:

traceroute: 查看数据包经过的路径

强主机模式: 数据包必须和对应网络接口对上
弱主机模式: 数据包和任一网络接口对上即可

DHCP:
```

# 计算机组成原理-整数-浮点数-字符
## 本文主要讨论数据在内存以及文件中存储
* 基础知识(原码 反码 补码 移码 字节序)
* 无符号的整数的存储(内存以及二进制文件)
* 有符号的整数的存储(内存以及二进制文件)
* 浮点数的存储(内存以及二进制文件)
* 字符存储(内存 二进制文件 文本文件)
* 查看二进制(内存)
* 查看二进制(文件)

## 基础知识(原码 反码 补码 移码 字节序)

### 加减法的所有类型
* 正数+正数:
* 正数-正数:
* 正数+负数: 可以转化为 正数-正数
* 正数-负数: 可以转化为 正数+正数
* 负数+正数: 可以转化为 正数-正数
* 负数+负数: 可以转化为 正数+正数, 然后把正数变成负数
* 负数-正数: 可以转化为 正数+正数, 然后把正数变成负数
* 负数-负数: 可以转化为 正数-负数
* 正数: 可以转化为    0+正数
* 负数: 可以转化为    0-正数

所以我们考虑加减法只要处理 正数+正数 和 正数-正数 的情况就可以了

### 原码
* 正数: 符号位为 0
* 负数: 符号位为 1
* +0: 0000
* -0: 1000
* 最大: 0111(+7)
* 最小: 1111(-7)
* 比较大小:
    * 先比较符号位, 正数大于负数
    * 同为正数, 数越大, 值越大
    * 同为负数, 数越大, 值越小
* 正数+正数: 需要使用加法器处理, 像列竖式一样, 高位直接舍弃
* 正数-正数: 需要使用减法器处理

### 反码
* 计算:
    * 正数的反码和原码相同
    * 负数的反码在原码的基础上, 把除符号位外的所有位取反
* 定义:
    * 最高位取负, 值为 2^(w-1) - 1, 其他位取正, 即:
    * 0000 == -0*(2^3-1) + 0*2^2 + 0*2^1 + 0*2^0 = -0 + 0 + 0 + 0 = +0
    * 1111 == -1*(2^3-1) + 1*2^2 + 1*2^1 + 1*2^0 = -7 + 4 + 2 + 1 = -0
    * 0111 == -0*(2^3-1) + 1*2^2 + 1*2^1 + 1*2^0 = -0 + 4 + 2 + 1 = +7(最大)
    * 1000 == -1*(2^3-1) + 0*2^2 + 0*2^1 + 0*2^0 = -7 + 0 + 0 + 0 = -7(最小)
* 比较大小(比使用原码好一点, 同号的比较大小可以统一)
    * 先比较符号位, 正数大于负数
    * 同为正数, 数越大, 值越大
    * 同为负数, 数越大, 值越小
* 正数+正数: 无意义
* 正数-正数: 无意义

### 补码
* 计算
    * 正数的补码和原码相同
    * 负数的补码在反码的基础上, 在最后一位加一
* 定义:
    * 最高位取负, 其他位取正
    * 0000 == -0*2^3 + 0*2^2 + 0*2^1 + 0*2^0 = -0 + 0 + 0 + 0 = +0
    * 0111 == -0*2^3 + 1*2^2 + 1*2^1 + 1*2^0 = -0 + 4 + 2 + 1 = +7(最大)
    * 1000 == -1*2^3 + 0*2^2 + 0*2^1 + 0*2^0 = -8 + 0 + 0 + 0 = -8(最小)
* 比较大小(比使用原码好一点, 同号的比较大小可以统一)
    * 先比较符号位, 正数大于负数
    * 同为正数, 位数越大, 值越大
    * 同为负数, 位数越大, 值越大
* 正数+正数: 使用加法器处理
* 正数-正数: 可以转化为 正数 + 负数, 然后使用加法器处理(补码存在的主要目的)
* 补码变符号
    * 正数(+1) => 负数(-1) == 正数的补码(0001)各位取反(1110), 然后加一(1111)
    * 负数(-1) => 正数(+1) == 负数的补码(1111)各位取反(0000), 然后加一(0001)
* 加法器: 像列竖式一样, 从低到高, 一位一位相加, 该进就进, 超过最高位直接舍弃

### 移码
* 在原码的基础上加一个数字, 使得所有的数字都是非负数
* 比较大小: 直接比较即可
* 加法: 无意义
* 减法: 无意义

### 字节序(单元大小是多字节的数据, 高字节在前还是在后)
* 网络字节序(大端)
* 内存中存储(大小端由 CPU 决定, 一般使用小端存储)(主机字节序)
* 文件内存储二进制(同内存中存储)(二进制文件)
* 文件中存储字符(由 BOM 决定)(文本文件)

### 大小端
#### 大端存储(高字节存储在内存的低字节)
* 方便判断正负
* 看起来直观, 手写的计算机存储和真实的存储一致

#### 小端存储(高字节存储在内存的高字节)
* 方便类型转换, 比如 int => short

#### 涉及的 C++ 类型
* 整形: short, int, long, long long
* 浮点型: float, double, long double
* 字符类: `wchar_t`, `char16_t`, `char32_t`

#### 判断
使用共同体或类似的方法

测试: [01.cc](./01.cc)

### BOM
* UTF-8 : 不需要 BOM (使用 vim 的 set nobomb 可以去掉 BOM)
* UTF-16: 由 BOM 指定
* UTF-32: 由 BOM 指定
* GBK: 不需要 BOM

## 无符号的整数的存储(内存以及二进制文件)
* 使用原码表示
* 溢出时舍弃高位
* 最小数: 0000(0*2^3+0*2^2+0*2^1+0*2^0 == 0)
* 最大数: 1111(1*2^3+1*2^2+1*2^1+1*2^0 == 15)
* unsigned char, unsigned short, usigned long, unsigned long long
* 除 unsigned char 外, 有大小端之分
* 无符号的整数 除以 无符号的整数 结果还是 无符号的整数, 小数部分直接舍弃

## 有符号的整数的存储(内存以及二进制文件)
* 使用补码表示(方便处理减法以及负数)
* 溢出时未定义
* 最小数: 1000(-1*2^3+0*2^2+0*2^1+0*2^0 == -8)
* 最大数: 0111(+0*2^3+1*2^2+1*2^1+1*2^0 == +7)
* signed char, short, long, long long
* 除 signed char 外, 有大小端之分
* 有符号的整数 除以 有符号的整数
    * 商的符号由除数和被除数决定, 取余的符号只和被除数有关(C++11)
    * 小数部分直接舍弃

测试: [02.cc](./02.cc)

## 浮点数的存储(内存以及二进制文件)
* 使用 double, 探索浮点数的存储以及精度的损失
* 区分大小端
* 格式: 1-符号位 11-阶码 52-尾码

### 浮点数的类型
* 正负  零: 阶码都为 0, 尾码  都为 0
* 非规约数: 阶码都为 0, 尾码不都为 0, 阶码的偏移量为 1022, 尾码整数部分为 0 (特别小的数字)
* 正负无穷: 阶码都为 1, 尾码  都为 0
* 非数字: 阶码都为 1, 尾码不都为 0
* 规约数: 阶码不都为 0, 也不都为 1, 阶码的偏移量为 1023, 尾码整数部分为 1
* 查看浮点数类型: pclassify(...)

### 浮点数的舍入模式
* 范围:
    * 浮点数存储(二进制)
    * 保留小数位数(十进制)
    * 如果不能精确处理, 是舍弃还是进一
* 向下舍入:
    * 正数: 舍弃
    * 负数: 进一
    * std::floor
* 向上舍入:
    * 正数: 进一
    * 负数: 舍弃
    * std::ceil
* 向零舍入:
    * 正数: 舍弃
    * 负数: 舍弃
    * std::trunc
    * 浮点数-->整数
* 四舍五入:
    * 只用于保留小数位数
    * 剩余部分第一位小于 5: 舍弃
    * 剩余部分第一位大于等于 5: 进一
    * std::round
* 最近舍入:
    * 四舍六入五取偶
    * 保留小数
        * 剩余部分第一位小于 5: 舍弃
        * 剩余部分第一位大于 5: 进一
        * 剩余部分第一位 5 后  存在非 0 位: 进一
        * 剩余部分第一位 5 后不存在非 0 位: 进一
            * 精确存储的的最后一位为奇数: 进一
            * 精确存储的的最后一位为偶数: 舍弃
    * 存储
        * 剩余部分第一位为 0: 舍弃
        * 剩余部分第一位为 1 且后  存在 非 0 位: 进一
        * 剩余部分第一位为 1 且后不存在 非 0 位
            * 精确存储的的最后一位为 1: 进一
            * 精确存储的的最后一位为 0: 舍弃
    * 默认是最近舍入
* 由舍入模式决定:
    * std::rint
    * std::nearbyint
* 查看舍入模式: fegetround()
* 设置舍入模式: fesetround(...)

#### 测试文件
* 测试保留小数时的四舍六入五取偶: [03.cc](./03.cc)
* 测试存储小数时的四舍六入五取偶: [04.cc](./04.cc)

### 浮点数异常(这个比较乱, 一般不重要)
* 范围:
    * 四则运算
    * 调用函数
    * 参数不合法 或者 结果不准确的问题
* 类型:
    * 除以 0
    * 结果不准确
    * 参数非法
    * 上溢
    * 下溢
* 清空浮点数异常: feclearexcept(...)
* 测试浮点数异常: fetestexcept(...)
* 可能会引发浮点数异常的场景:
    * 浮点数的四则运算
    * 绝大部分函数
* 不会引发浮点数异常的场景:
    * isless 只对 signaling NaN 抛出异常
    * nearbyint 系列

测试: [05.cc](./05.cc)

### 浮点数最多可以表示的小数点后的位数
* 最小非规约正数的最后一位非 0 位
* 1074 位

测试: [06.cc](./06.cc)

### 阶码为什么用移码? 不用补码, 反码, 原码
* 方便比较大小
    * 符号位特殊
    * 其他位直接比较即可
* 使用其他的还需要判断阶码的符号位

### 相邻可表示的浮点数的差值是不是一定的?
* 不是
* 离零越近, 差值越小
* 非规约数:
    * 差值: 2 的 (0-1022-52) 次
    * 即: 2 的 -1074 次
* 最大非规约正数 --> 最小规约正数
    * 差值: 2 的 (0-1022-52) 次
    * 即: 2 的 -1074 次
* 阶码相同时
    * 差值: 2 的 (阶码-1023-52) 次
* 阶码相邻时
    * 差值: 2 的 (小的阶码-1023-52) 次

### 非规约数的偏移量为什么是 1022, 不是 1023?, 非规约数的整数位为什么是 0, 不是 1?
* 设 a 为最大正非规约数的上一可表示数: 0 00000000000 (0)1111111111111111111111111111111111111111111111111110
* 设 b 为最大正非规约数              : 0 00000000000 (0)1111111111111111111111111111111111111111111111111111
* 设 c 为最小正规约数                : 0 00000000001 (1)0000000000000000000000000000000000000000000000000000
* 设 d 为最小正规约数的下一可表示数  : 0 00000000001 (1)0000000000000000000000000000000000000000000000000001
* 如果非规约数的偏移量是 1022, 非规约数的整数位是 0
    * a 为: -1022次 - -1074次 - -1074次 (-1022 - 52)
    * b 为: -1022次 - -1074次
    * c 为: -1022次
    * d 为: -1022次 + -1074次
    * b - a: -1074次
    * c - b: -1074次
    * d - c: -1074次
* 如果非规约数的偏移量是 1023, 非规约数的整数位是 0 (非规约数 => 规约数, 变化差值不太连续)
    * a 为: -1023次 - -1075次 - -1075次 (-1023 - 52)
    * b 为: -1023次 - -1075次
    * c 为: -1022次 == -1023次 + -1023次
    * d 为: -1022次 + -1074次
    * b - a: -1075次
    * c - b: -1075次 + -1023次
    * d - c: -1074次
* 如果非规约数的偏移量是 1022, 非规约数的整数位是 1(最大非规约数 大于 最小规约数, 不行)
    * a 为: -1022次 + -1022次 - -1074次 - -1074次 (-1022 - 52)
    * b 为: -1022次 + -1022次 - -1074次
    * c 为: -1022次
    * d 为: -1022次 + -1074次
    * b - a: -1074次
    * c - b: -1074次 - -1022次 (小于 0)
    * d - c: -1074次
* 如果非规约数的偏移量是 1023, 非规约数的整数位是 1(相比较, 第一种能表达更贴近 0 的数)
    * a 为: -1023次 + -1023次 - -1075次 - -1075次 (-1023 - 52)
    * b 为: -1023次 + -1023次 - -1075次
    * c 为: -1022次 == -1023次 + -1023次
    * d 为: -1022次 + -1074次
    * b - a: -1075次
    * c - b: -1075次
    * d - c: -1074次

测试: [07.cc](./07.cc)

### 规约数的隐藏位为什么是1?
为了节省空间

### 浮点数精度损失
* 范围
    * 浮点数存储
    * 浮点数取回
    * 浮点数计算
* 小于最小非规约正数的正数将当作 0
* 大于最大规约正数的数字将当作正无穷
* 以下仅讨论规约数和非规约数
* 浮点数字符串(a) --> 浮点数二进制(b)
    * 可能无法精确转换(0.1)
* 浮点数二进制(b) --> 浮点数科学计数(c)
    * 无精度损失
* 浮点数科学计数(c) --> 调节幂次(d)
    * 如果, 幂次小于 -1022
        * 将幂次改为 -1022
        * 同时调整小数部分
    * 无精度损失
* 调节幂次(d) --> 存储-52位(e)
    * 整数部分为 1, 表示规约数
    * 整数部分为 0, 表示非规约数
    * 只存储小数部分
    * 前 51 位精确存储
    * 最后一位四舍六入五取偶
    * 注意: 进一的时候可能引发前 51 位变化
* 存储-52位(e) --> 浮点数二进制(f)
    * 无精度损失
* 浮点数二进制(f) --> 浮点数十进制(g)
    * 无精度损失
* 浮点数十进制(g) --> 保留小数位数(h)
    * 默认: 四舍六入五取偶
* 一个精确的浮点数表示的上下限
    * 如果最后一位是 0, 则范围是 [下限, 上限]
    * 如果最后一位是 1, 则范围是 (下限, 上限)

测试: [08.cc](./08.cc)

### 15 位精度是什么意思?
* 并不是说: 所有数字的前15位可以精确表示(0.1 不能精确表示)
* 而是说计算机能保证的能区分的精度是 15 位, 在指数相同的情况下, 存储的不同数的前 15 位有效数字是不同的
* 超过 15 位也可能能表示

#### 理解
* 符号位, 阶码固定的情况下, 相邻的可表示数的差值是固定的, 可表示数的状态也是固定的
* 52 位二进制能表示 4503599627370496 种状态
* 53 位二进制能表示 9007199254740992 种状态
* 即 能够准确表示十五位状态
* 即 能够保证的精度是十五位数
* 还是不太清楚, 先放下吧,...

测试: [09.cc](./09.cc)

## 字符存储(内存 二进制文件 文本文件)(建议只使用不带bom的utf-8)
* 编码: 字符 -> 计算机存储
* 解码: 计算机存储 -> 字符
* 字符集:
    * ASCII (和编码规则一一对应)
    * GB2312 => GBK(cp936) => GB18030 (和编码规则一一对应)
    * BIG5
    * Unicode
    * Latin1(ISO-8859-1) 单字节使用完整的八位字节, 所以可以将其他编码当作 Latin1 来传输不会丢失数据
* 编码规则:
   * UTF-8
        * 文本文件: 不需要 BOM, 存在也成(FE FF => EF BB BF)(建议不要)
        * 内存以及二进制文件: 不需要考虑字节序
   * UTF-16
        * 文本文件: 需要 BOM(FE FF 或 FF FE)
        * 内存以及二进制文件: 和主机的字节序相同
   * UTF-32
        * 文本文件: 需要 BOM(00 00 FE FF 或 FF FE 00 00)
        * 内存以及二进制文件: 和主机的字节序相同
   * windows 的 记事本 的 ASCI   : 本地编码
   * windows 的 记事本 的 unicode: 带 BOM 的小端的 UTF-16
   * windows 的 记事本 的 utf-8  : 带 BOM 的 UTF-8
* 文件编码转换: iconv -f gbk -t utf-8 1.txt -o 1.txt
* 文件编码不一定能准确获取
* 在 C++ 中使用(建议只使用 UTF-8)
    * UTF-8 : char, string   ,  ".....", u8"....."
    * UTF-16: char, u16string, u"....."
    * UTF-32: char, u32string, U"....."
    * 字符串常量以 \u 开头的四个十六进制数表示 Unicode
    * 字符串常量以 \U 开头的八个十六进制数表示 Unicode

测试: [10.cc](./10.cc)

## 查看二进制(内存)
* 使用 gdb
* 在代码中直接读取内存中存储的值

## 查看二进制(文件)
```
xxd -b     1.txt  # 输出二进制而不是十六进制
xxd -e     1.txt  # 使用小端模式
xxd -g ... 1.txt  # 每组的字节数            -- 建议使用, 读取的顺序和存储的顺序相同, 不需要考虑字节序

hd         1.txt # 每组一个字节 显示十六进制+ASCII -- 不建议使用, 得考虑字节序
hexdump -b 1.txt # 每组一个字节 显示八进制
hexdump -c 1.txt # 每组一个字节 显示字符
hexdump -C 1.txt # 每组一个字节 显示十六进制+ASCII
hexdump -d 1.txt # 每组两个字节 显示  十进制
hexdump -o 1.txt # 每组两个字节 显示  八进制
hexdump -x 1.txt # 每组两个字节 显示十六进制

od -t a   1.txt # 每组一个字节, 显示字符(nl) -- 不建议使用, 得考虑字节序
od -t c   1.txt # 每组一个字节, 显示字符(\n)
od -t d4  1.txt # 每组四个字节, 显示有符号的十进制数字
od -t f4  1.txt # 每组四个字节, 显示浮点数
od -t o4  1.txt # 每组四个字节, 显示  八进制数字
od -t u4  1.txt # 每组四个字节, 显示无符号的十进制数字
od -t x4  1.txt # 每组四个字节, 显示十六进制数字
od -t d4z 1.txt # 每组四个字节, 显示十进制数字, 并显示原始字符
od -a     1.txt # 同 -t a
od -b     1.txt # 同 -t o1
od -c     1.txt # 同 -t c
od -d     1.txt # 同 -t u2
od -f     1.txt # 同 -t f
od -i     1.txt # 同 -t dI
od -l     1.txt # 同 -t dL
od -o     1.txt # 同 -t o2
od -s     1.txt # 同 -t d2
od -x     1.txt # 同 -t x2
od --endian={big|little} 1.txt # 指明大小端
```

# 操作系统-正则表达式
## 正则表达式需要考虑的问题
1. 同一行只匹配一个, 还是多个
2. 匹配时, 是否忽略大小写(grep -i)

## 正则表达式语法
### 基础 扩展和 perl 风格
* 基础的正则表达式: grep, sed, vim
* 扩展的正则表达式: egrep, grep -E, sed -r, gawk
* perl的正则表达式: perl, grep -P

|        |说明                              |     基础             |   扩展   |   Perl 风格          |
|--------|----------------------------------|----------------------| ---------|----------------------|
|^       |字符串开头                        |     支持             |   支持   |    支持              |
|$       |字符串结尾                        |     支持             |   支持   |    支持              |
|.       |除换行符以外的任意字符            |     支持             |   支持   |    支持              |
|[]      |中括号中的任意字符                |     支持             |   支持   |    支持              |
|[^]     |中括号外的任意字符                |     支持             |   支持   |    支持              |
|?       |前面字符出现 [0,    1] 次, 贪婪   |   不支持, 转义后支持 |   支持   |    支持              |
|*       |前面字符出现 [0, 无穷] 次, 贪婪   |     支持             |   支持   |    支持              |
|+       |前面字符出现 [1, 无穷] 次, 贪婪   |   不支持, 转义后支持 |   支持   |    支持              |
|{n}     |前面字符出现  n        次, 贪婪   |   不支持, 转义后支持 |   支持   |    支持              |
|{n,}    |前面字符出现 [n, 无穷] 次, 贪婪   |   不支持, 转义后支持 |   支持   |    支持              |
|{n,m}   |前面字符出现 [n,    m] 次, 贪婪   |   不支持, 转义后支持 |   支持   |    支持              |
|        |在贪婪的字符后加上 ? 表示懒惰     |   不支持             | 不支持   |    支持              |
|()      |把括号内的内容当作一个整体        |   不支持, 转义后支持 |   支持   |    支持              |
|\1      |子表达式, 以左括号计数            |     支持             |   支持   |    支持              |
|(?=...) |向前查找  匹配指定内容, 但不返回  |   不支持             | 不支持   |    支持              |
|(?!...) |向前查找不匹配指定内容, 但不返回  |   不支持             | 不支持   |    支持              |
|(?<=...)|向后查找  匹配指定内容, 但不返回  |   不支持             | 不支持   |    支持, 只能固定长度|
|(?<!...)|向后查找不匹配指定内容, 但不返回  |   不支持             | 不支持   |    支持, 只能固定长度|
|(?(1))  |第一个子表达式成功才匹配          |   不支持             | 不支持   |    支持              |
| \|     |多个表达式或                      |   不支持, 转义后支持 |   支持   |    支持              |


### 对转义字符的支持
|                                |   grep|(grep -E)|(grep -P)| egrep |  sed  |(sed -r) |perl|  gawk|  vim |
|--------------------------------|-------|---------|---------|-------|-------|---------|----|------|------|
| \b   单词开头或结尾            |   支持|  支持   |  支持   |  支持 |  支持 |  支持   |支持|不支持|不支持|
| \B 非单词开头或结尾            |   支持|  支持   |  支持   |  支持 |  支持 |  支持   |支持|不支持|不支持|
| \d   数字                      | 不支持|不支持   |  支持   |不支持 |不支持 |不支持   |支持|不支持|  支持|
| \D 非数字                      | 不支持|不支持   |  支持   |不支持 |不支持 |不支持   |支持|不支持|  支持|
| \s   空白字符                  |   支持|  支持   |  支持   |  支持 |  支持 |  支持   |支持|不支持|  支持|
| \S 非空白字符                  |   支持|  支持   |  支持   |  支持 |  支持 |  支持   |支持|不支持|  支持|
| \w   数字 字母 下划线          |   支持|  支持   |  支持   |  支持 |  支持 |  支持   |支持|不支持|  支持|
| \W 非数字 字母 下划线          |   支持|  支持   |  支持   |  支持 |  支持 |  支持   |支持|不支持|  支持|
| \l 下一字符转换为小写          | 不支持|不支持   |不支持   |不支持 |  支持 |  支持   |支持|不支持|  支持|
| \L 所有字符转换为小写, 直到 \E | 不支持|不支持   |不支持   |不支持 |  支持 |  支持   |支持|不支持|  支持|
| \u 下一字符转换为大写          | 不支持|不支持   |不支持   |不支持 |  支持 |  支持   |支持|不支持|  支持|
| \U 所有字符转换为大写, 直到 \E | 不支持|不支持   |不支持   |不支持 |  支持 |  支持   |支持|不支持|  支持|

## 实战
### 1. 查找合法的 IPv4 地址 (由点分割的四个数字, 每个数字的取值都是 [0, 255])
```
$ v='\d|[1-9]\d|1\d{2}|2[0-4]\d|25[0-5]'
$ grep -P -o  "^\s*(($v)\.){3}($v)\s*\$" 1.txt
$
$ v='[0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5]'
$ grep -E -o  "^\s*(($v)\.){3}($v)\s*\$" 1.txt
```

### 2. 查看固定电话是否合法(0354-5757023 (0354)5757023 5757023)
* 区号必须以0开头, 区号可以是1到3位
* 电话号码必须是7位

```
$ grep -P -o '^\s*((\()?0\d{1,3}(?(2)\)|-))?\d{7}\s*$' 2.txt
$
$ grep -P -o '^\s*(0\d{1,3}-|\(0\d{1,3}\))\d{7}\s*$'   2.txt
```


# 计算机语言-Bash
## 简介
* Bash 是脚本, 一门编程语言

## 特殊字符 -- 要使用原字符必须转义
```
* 没引号包含
    * {} # 变量分割符 或 块语句
    * [] # 通配符 或 数字计算等等
    * () # 子shell
    * $  # 读取变量, 无值时默认忽略
    * !  # 一些快捷的方式获取命令或参数
    * ;  # 命令的分割符
    * #  # 注释
    * -  # 字符串以 - 开头表示是可选参数
    * -- # 后面的字符串都不是可选参数
    * '  # 单引号
    * "  # 双引号
    * &  # 后台运行
* 单引号包含:
    * '  # 单引号, 需要在字符串开头加上 $ 符号
* 双引号包含:
    * $  # 读取变量, 无值时默认忽略
    * !  # 一些快捷的方式获取命令或参数
    * "  # 双引号
```

## 特殊变量
```
$HOME  # 主目录
$IPS   # 默认分隔符, 默认为: " \t\n", 包含转义字符时, 需要在开头添加 $, IFS=$'\n'
$PATH  # 命令路径
$PS1   # 提示符
$PWD   # 当前工作目录
$SHELL # 当前 shell
$?     # 上一命令执行是否成功
$$     # shell ID
$_     # 上一命令的最后一个参数
$!     # 后台最后一个进程的进程 ID
$0     # shell 名称
$-     # shell 启动参数
```

## 字符串(包括数字)
```
v=...   #   解析变量和转义字符
v="..." #   解析变量和转义字符
v='...' # 不解析变量和转义字符
v="...
...
"       # 字符串跨行
v='...
...
'       # 字符串跨行

${v:-w}              # v 不为空, 返回 $v, 否则, 返回 w
${v:=w}              # v 不为空, 返回 $v, 否则, 令 v=w, 返回 w
${v:+w}              # v 不为空, 返回  w, 否则, 返回空
${v:?w}              # v 不为空, 返回 $v, 否则, 输出 w, 退出
${#val}              # 输出字符串的长度
${val:起始位置:长度} # 获取子串
lyb=123
lyb=$lyb+123         # 字符串连接, lyb 将变成 123+123
lyb=123.456.txt
lyb=${lyb%.*}        # 后缀非贪婪匹配, lyb 为 123.456
lyb=${lyb%%.*}       # 后缀  贪婪匹配, lyb 为 123
lyb=${lyb#*.}        # 前缀非贪婪匹配, lyb 为 456.txt
lyb=${lyb##*.}       # 前缀  贪婪匹配, lyb 为 txt
lyb=${lyb/*./str}    # 全文  贪婪匹配, lyb 为 strtxt, 匹配一次
lyb=${lyb//*./str}   # 全文  贪婪匹配, lyb 为 strtxt, 匹配多次
lyb=${lyb^^}         # 变为大写
lyb=${lyb,,}         # 变为小写
```

## 索引数组
```
* v=(1 2 3)  # 初始化数组, 以空字符分割多个元素
* ${v[1]}    # 数组中指定元素的值
* ${v[-1]}   # 数组中最后一个元素的值
* ${v[@]}    # 数组中所有元素的值, "1" "2" "3"
* ${#v[@]}   # 数组中元素的个数
* ${!v[@]}   # 获取所有的 key
* v+=(1 2 3) # 添加数组元素
```

## 关联数组
```
* declare -A v # 声明
* v[a]=a       # 赋值
* v[-1]=b      # 以 -1 作为 key
               # 其他同索引数组
```

## 模拟命令的标准输入
```
解释变量
cat << EOF
    $lyb
EOF

解释变量
cat << "EOF"
    $lyb
EOF

不解释变量
cat << 'EOF'
    $lyb
EOF

cat <<<  $lyb  #   解释变量
cat <<< "$lyb" #   解释变量
cat <<< '$lyb' # 不解释变量
```

## 括号 -- 只列举常用的情况
```
* 命令替换使用 $() 而不是反引号
    * (ls)         # 子shell执行命令, 输出到屏幕上
    * lyb=$(ls)    # 子shell执行命令, 存入变量
* 整数运算
    * (())         # 整数运算, 变量不需要加 $
    * lyb=$((...)) # 将结果存储在变量中
* 使用 [[ ... ]] 测试
    * [[     -z "$lyb"   ]] # 判断是否空字符串
    * [[     -n "$lyb"   ]] # 判断是否不是空字符串
    * [[ !   -n "$lyb"   ]] # 非操作
    * [[ "111" =~ 1{1,3} ]] # 扩展的正则表达式匹配
    * [[     -a file     ]] # file 存在
    * [[     -e file     ]] # file 存在
    * [[     -f file     ]] # file 存在且普通文件
    * [[     -d file     ]] # file 存在且是目录
    * [[     -h file     ]] # file 存在且是符号链接
    * [[     -L file     ]] # file 存在且是符号链接
    * [[     -b file     ]] # file 存在且是  块文件
    * [[     -c file     ]] # file 存在且是字符文件
    * [[     -p file     ]] # file 存在且是一个命名管道
    * [[     -S file     ]] # file 存在且是一个网络 socket
    * [[     -s file     ]] # file 存在且其长度大于零, 可用于判断空文件
    * [[     -N file     ]] # file 存在且自上次读取后已被修改
    * [[     -r file     ]] # file 存在且可读
    * [[     -w file     ]] # file 存在且可写权
    * [[     -x file     ]] # file 存在且可执行
    * [[     -u file     ]] # file 存在且设置了 SUID
    * [[     -g file     ]] # file 存在且设置了 SGID
    * [[     -k file     ]] # file 存在且设置了 SBIT
    * [[     -O file     ]] # file 存在且属于有效的用户 ID
    * [[     -G file     ]] # file 存在且属于有效的组   ID
    * [[     -t fd       ]] # fd 是一个文件描述符，并且重定向到终端
    * [[ FILE1 -nt FILE2 ]] # FILE1 比 FILE2 的更新时间更近, 或者 FILE1 存在而 FILE2 不存在
    * [[ FILE1 -ot FILE2 ]] # FILE1 比 FILE2 的更新时间更旧, 或者 FILE2 存在而 FILE1 不存在
    * [[ FILE1 -ef FILE2 ]] # FILE1 和 FILE2 引用相同的设备和 inode 编号
* cat <(ls)                 # 将命令或函数的输出作为文件
```

## 脚本
```
$0 # 脚本名称
$1 # 第一个参数
$@ # 参数序列
$# # 参数个数

if for while

function

函数内建议使用 local 局部变量, 声明和使用放到不同的行
```

测试文件: [301-01.sh](./301-01.sh)

## 通配符
```
* ~           # 用户主目录
* ~lyb        # 用户 lyb 的主目录, 匹配失败的话, 不扩展
* ~+          # 当前目录
* ?           # 任意单个字符, 匹配失败的话, 不扩展
* *           # 任意多个字符, 匹配失败的话, 不扩展
* [123]       # [1,3] 中任意一个, 匹配失败的话, 不扩展
* [1-5]       # [1,5] 中任意一个, 匹配失败的话, 不扩展
* [!a]        # 非 a, 匹配失败的话, 不扩展
* [^a]        # 非 a, 匹配失败的话, 不扩展
* {1,2,3}     # [1,3] 匹配失败, 也会扩展
* {,1}        # 空 或 1, 匹配失败, 也会扩展
* {1..10}     # 匹配失败, 也会扩展
* {01..10}    # 匹配失败, 也会扩展(保证两位数)
* {1..10..3}  # 匹配失败, 也会扩展
```

## 正则表达式
1. 同一行只匹配一个, 还是多个
2. 匹配时, 是否忽略大小写(grep -i)

### 基础 扩展和 Perl 风格
* 基础的正则表达式: grep, sed, vim
* 扩展的正则表达式: egrep, grep -E, sed -r, gawk
* perl的正则表达式: perl, grep -P

|         | 说明                             | 基础       | 扩展    | Perl 风格          |
|---------| ---------------------------------| -----------|---------|--------------------|
|^        | 字符串开头                       |       支持 |  支持   | 支持               |
|$        | 字符串结尾                       |       支持 |  支持   | 支持               |
|.        | 除换行符以外的任意字符           |       支持 |  支持   | 支持               |
|[]       | 中括号中的任意字符               |       支持 |  支持   | 支持               |
|[^]      | 中括号外的任意字符               |       支持 |  支持   | 支持               |
|?        | 前面字符出现 [0,    1] 次, 贪婪  | 转义后支持 |  支持   | 支持               |
|*        | 前面字符出现 [0, 无穷] 次, 贪婪  |       支持 |  支持   | 支持               |
|+        | 前面字符出现 [1, 无穷] 次, 贪婪  | 转义后支持 |  支持   | 支持               |
|{n}      | 前面字符出现  n        次, 贪婪  | 转义后支持 |  支持   | 支持               |
|{n,}     | 前面字符出现 [n, 无穷] 次, 贪婪  | 转义后支持 |  支持   | 支持               |
|{n,m}    | 前面字符出现 [n,    m] 次, 贪婪  | 转义后支持 |  支持   | 支持               |
|         | 在贪婪的字符后加上 ? 表示懒惰    |     不支持 |不支持   | 支持               |
|()       | 把括号内的内容当作一个整体       | 转义后支持 |  支持   | 支持               |
|\1       | 子表达式, 以左括号计数           |       支持 |  支持   | 支持               |
|(?=...)  | 向前查找  匹配指定内容, 但不返回 |     不支持 |不支持   | 支持               |
|(?!...)  | 向前查找不匹配指定内容, 但不返回 |     不支持 |不支持   | 支持               |
|(?<=...) | 向后查找  匹配指定内容, 但不返回 |     不支持 |不支持   | 支持, 只能固定长度 |
|(?<!...) | 向后查找不匹配指定内容, 但不返回 |     不支持 |不支持   | 支持, 只能固定长度 |
|(?(1))   | 第一个子表达式成功才匹配         |     不支持 |不支持   | 支持               |
| \|      | 多个表达式或                     | 转义后支持 |  支持   | 支持               |

### 对转义字符的支持
|                                |   grep|grep -E|grep -P| egrep |  sed  |sed -r |perl|  gawk|  vim |
|--------------------------------|-------|-------|-------|-------|-------|-------|----|------|------|
| \b   单词开头或结尾            |   支持|  支持 |  支持 |  支持 |  支持 |  支持 |支持|不支持|不支持|
| \B 非单词开头或结尾            |   支持|  支持 |  支持 |  支持 |  支持 |  支持 |支持|不支持|不支持|
| \d   数字                      | 不支持|不支持 |  支持 |不支持 |不支持 |不支持 |支持|不支持|  支持|
| \D 非数字                      | 不支持|不支持 |  支持 |不支持 |不支持 |不支持 |支持|不支持|  支持|
| \s   空白字符                  |   支持|  支持 |  支持 |  支持 |  支持 |  支持 |支持|不支持|  支持|
| \S 非空白字符                  |   支持|  支持 |  支持 |  支持 |  支持 |  支持 |支持|不支持|  支持|
| \w   数字 字母 下划线          |   支持|  支持 |  支持 |  支持 |  支持 |  支持 |支持|不支持|  支持|
| \W 非数字 字母 下划线          |   支持|  支持 |  支持 |  支持 |  支持 |  支持 |支持|不支持|  支持|
| \l 下一字符转换为小写          | 不支持|不支持 |不支持 |不支持 |  支持 |  支持 |支持|不支持|  支持|
| \L 所有字符转换为小写, 直到 \E | 不支持|不支持 |不支持 |不支持 |  支持 |  支持 |支持|不支持|  支持|
| \u 下一字符转换为大写          | 不支持|不支持 |不支持 |不支持 |  支持 |  支持 |支持|不支持|  支持|
| \U 所有字符转换为大写, 直到 \E | 不支持|不支持 |不支持 |不支持 |  支持 |  支持 |支持|不支持|  支持|

### 实战
* 1. 查找合法的 IPv4 地址(由点分割的四个数字, 每个数字的取值都是 [0, 255])
* 2. 查看固定电话是否合法(0354-5757023 (0354)5757023 5757023)
    * 区号必须以0开头, 区号可以是1到3位
    * 电话号码必须是7位

测试文件: [301-02.sh](./301-02.sh)

## 常用快捷键
```
Ctrl+A      # 将光标移到行首
Ctrl+B      # 将光标向左移动一个字符
Ctrl+C      # 向前台进程组发送 SIGINT, 默认终止进程
Ctrl+D      # 删除光标前的字符 或 产生 EOF 或 退出终端
Ctrl+E      # 将光标移到行尾
Ctrl+F      # 将光标向右移动一个字符
Ctrl+G      # 响铃
Ctrl+H      # 删除光标前的一个字符
Ctrl+I      # 相当于TAB
Ctrl+J      # 相当于回车
Ctrl+K      # 删除光标处到行尾的字符
Ctrl+L      # 清屏
Ctrl+M      # 相当于回车
Ctrl+N      # 查看历史命令中的下一条命令
Ctrl+O      # 类似回车，但是会显示下一行历史
Ctrl+P      # 查看历史命令中的上一条命令
Ctrl+Q      # 解锁终端
Ctrl+R      # 历史命令反向搜索, 使用 Ctrl+G 退出搜索
Ctrl+S      # 锁定终端 -- TODO 历史命令正向搜索, 使用 Ctrl+G 退出搜索
Ctrl+T      # 交换前后两个字符
Ctrl+U      # 删除光标处到行首的字符
Ctrl+V      # 输入控制字符
Ctrl+W      # 删除光标左边的一个单词
Ctrl+X      #   TODO-列出可能的补全 ?
Ctrl+Y      # 粘贴被删除的字符
Ctrl+Z      # 前台运行的程序 --> 后台暂停
Ctrl+/      # 撤销之前的操作
Ctrl+\      # 产生 SIGQUIT, 默认杀死进程, 并生成 core 文件
Ctrl+xx     # 光标和行首来回切换

Esc+B              # 移动到当前单词的开头(左边)
Esc+F              # 移动到当前单词的结尾(右边)
Esc+.              # 获取上一条命令的最后的部分

Alt+B              # 向后（左边）移动一个单词
Alt+C              # 光标处字符转为大写
Alt+D              # 删除光标后（右边）一个单词
Alt+F              # 向前（右边）移动一个单词
Alt+L              # 光标处到行尾转为小写
Alt+R              # 取消变更
Alt+T              # 交换光标两侧的单词
Alt+U              # 光标处到行尾转为大写
Alt+BACKSPACE      # 删除光标前面一个单词，类似 Ctrl+W，但不影响剪贴板
Alt+.              # 使用上条命令的最后一个单词

Ctrl+X Ctrl+X      # 连续按两次 Ctrl+X，光标在当前位置和行首来回跳转
Ctrl+X Ctrl+E      # 用你指定的编辑器，编辑当前命令
Ctrl+insert        # 复制命令行内容
shift+insert       # 粘贴命令行内容
```

## 常用命令
```
!!    # 上一条命令
!l    # 执行最近使用的以 l 打头的命令
!l:p  # 输出最近使用的以 l 打头的命令
!num  # 执行历史命令列表的第 num 条命令
!$    # 上一条命令的最后一个参数
!*    # 上一条命令的所有参数
^1^2  # 将前一条命令中的 1 变成 2

\command # 忽略别名

awk '
     BEGIN   { getline     } # 可选  读取一行
     pattern { commands    } # pattern 类型
                             #      * NR < 5        # 行号 [1,4] 的行
                             #      * NR==1,NR==4   # 行号 [1,4] 的行
                             #      * /linux/       #   包含 linux 的行, 支持正则
                             #      * !/linux/      # 不包含 linux 的行, 支持正则
                             #      * /start/,/end/ # [] 区间匹配, 支持正则
                             #      * $1  ~ /123/   # 使用正则表达式匹配
                             #      * $1 !~ /123/   # 使用正则表达式匹配, 排除匹配到的行
                             #      * $1 ==  123    # 数值匹配, 精确匹配
                             #      * $1 == "123"   # 字符串匹配, 精确匹配
     END     { print "end" } # 可选
    ' 1.txt

awk            '{ print $0 }' 1.txt #
awk -F:        '{ print $0 }' 1.txt # 以字符       : 作为字段分割符
awk -F123      '{ print $0 }' 1.txt # 以字符串   123 作为字段分割符
awk -F[123]    '{ print $0 }' 1.txt # 以字符   1 2 3 作为字段分割符
awk -f         1.awk          1.txt # 从文件中读取命令
awk -v lyb=... '{ print $0 }' 1.txt # 定义变量
    # * 数字:
    #     * 包括整数和浮点数
    #     * 整数除以整数，结果可能是小数
    #     * int(...) 将浮点数转换为整数，将舍弃小数部分，比如 int(1.9) == 1, int(-1.9) == -1
    #     * + 将对数字进行相加, 即使是字符串
    # * 字符串：以单引号 或 双引号 包含的字符串
    #     * tolower() -- 小写
    #     * toupper() -- 大写
    #     * length()  -- 长度
    #     * sub() -- 正则查找, 替换第一处
    #     * gsub() -- 正则查找, 替换所有
    #     * gensub() -- 正则查找, 可选择替换所有还是某一个, 不修改原字符串
    #     * index() -- 字符串查找
    #     * match() -- 字符串查找(正则表达式), 并将结果保存到数组
    #     * split() -- 字符串 => 数组
    #     * 字符串连接直接使用空分开即可
    # * 数组：awk 使用关联数组，下标使用数字或字符串都成
    #     * 添加或修改元素  : arr[i] = ...
    #     * 删除数组中的变量: delete arr[i]
    #     * 遍历数组: i 为数组下标，注意返回的顺序不固定
    #         for (i in arr) {
    #             ....
    #         }
    #     * asort()  -- 元素排序
    #     * asorti() -- 索引排序
    # * 变量:
    #     * 变量不需要声明，可以直接使用
    #     * 变量使用一般不用使用 $, 除非是数字型变量，为了和数字区分，需要加上 $ 符号
    # * 赋值：赋值号左右两边有无空格都成
    # * 语句使用分号分割
    # *       if 语句, 同 C语言
    # *    while 语句, 同 C语言
    # * do while 语句, 同 C语言
    # *      for 语句，同 C语言, 外加 for (i in arr) i 为索引, arr 为数组
    # * 时间函数
    #     * systime()  -- 获取当前的时间戳
    #     * strftime() -- 时间戳 --> 格式化
    #     * mktime()   -- 年月日等 --> 时间戳
    # * 其他常用函数
    #     * print    参数以逗号分割，输出的字段分割符默认为空格，结尾将输出换行符
    #     * printf   同 C 语言
    # * 常用变量
    #       * $0  整行
    #       * $1  第一列
    #       * FS  输入字段分隔符 默认值为空字符
    #       * RS  输入记录分隔符 默认值为换行符
    #       * OFS 输出字段分隔符 默认值为空格
    #       * ORS 输出记录分隔符 默认值为换行符
    #       * FILENAME   用作gawk输入数据的数据文件的文件名
    #       * FNR        当前数据文件中的数据行数
    #       * IGNORECASE 设成非零值时，忽略gawk命令中出现的字符串的字符大小写
    #       * NF         数据文件中的字段总数
    #       * NR         已处理的输入记录数
    #       * RLENGTH    由match函数所匹配的子字符串的长度
    #       * RSTART     由match函数所匹配的子字符串的起始位置
    # * 函数, 执行 shell 命令及测试 见: 301-04.sh

apt update      # 更新软件源
                # 软件源: /etc/apt/sources.list
                #         /etc/apt/sources.list.d/
                # 格式:  包类别(deb-软件包 deb-src-源码包) url 发行版本号 分类
                # 更新软件源:
                #   1. 修改上述文件 或 add-apt-repository ... 或 add-apt-repository --remove ...
                #   2. apt update
apt search  vim # 搜寻软件包
apt install vim # 安装软件包
apt show    vim # 列出软件包的信息
apt upgrade     # 更新软件
apt remove  vim # 卸载软件包
apt purge   vim # 卸载软件包, 删除数据和配置文件
apt autoremove  # 自动卸载不需要的软件包

basename $(readlink -f $0) # 获取脚本的名称
dirname  $(readlink -f $0) # 获取脚本的目录

bash file-name # 执行文件内的命令
bash -c "ls"   # 将字符串的内容交由 bash 执行, 字符串里可包含重定向和管道

bc <<< "scale=2; 10/2" # 使用两位小数, 输出: 5.00
bc <<< "ibase=2;  100" # 输入使用二进制, 输出: 4
bc <<< "obase=2;   10" # 输出使用二进制, 输出: 1010

bg %jobspec # 后台暂停 --> 后台运行, 有无 % 都成
fg %jobspec # 后台     --> 前台运行, 有无 % 都成

c++filt  a.out    # 可以解析动态库里的符号

                  # 文件如果是符号链接, 将使用符号链接对应的文件
cat               # 输出 标准输入 的内容
cat          -    # 输出 标准输入 的内容
cat    1.txt      # 输出 1.txt 的内容, 文件支持多个
cat    1.txt -    # 输出 1.txt 和 标准输入 的内容
cat -n 1.txt      # 显示行号
cat -b 1.txt      # 显示行号, 行号不包括空行, 将覆盖参数 -n
cat -s 1.txt      # 去掉多余的连续的空行
cat -T 1.txt      # 显示 TAB
cat -E 1.txt      # 使用 $ 标明行结束的位置

chage            # 修改密码相关信息
chage -d ... lyb # 设置上次密码修改的日期
chage -d 0   lyb # 下次登录必须修改密码
chage -E ... lyb # 设置密码过期的日期
chage -I ... lyb # 设置密码过期到账户被锁的天数
chage -m ... lyb # 设置密码修改的最小间隔
chage -M ... lyb # 设置密码修改的最大间隔
chage -W ... lyb # 设置密码过期前的警告的天数
chage -l     lyb # 列出密码相关信息

chattr +i 1.c # 设置文件不可修改
chattr -i 1.c # 取消文件不可修改

chsh -s ...      # 修改默认的 shell
chsh -l          # 列出所有支持的 shell


clang-format    main.cc                                  # 预览规范后的代码
clang-format -i main.cc                                  # 直接在原文件上规范代码
clang-format -style=Google main.cc                       # 显示指明代码规范，默认为 LLVM
clang-format --dump-config -style=Google > .clang-format # 将代码规范配置信息写入文件 .clang-format
clang-format -style=file main.cc                         # 使用自定义代码规范,
                                                         # 规范位于当前目录或任一父目录的文件
                                                         # 的 .clang-format 或 _clang-format 中，
                                                         # (如果未找到文件，使用默认代码规范)
# 参考资源:
# clang-format  -> https://clang.llvm.org/docs/ClangFormat.html
# clang-format  -> https://clang.llvm.org/docs/ClangFormatStyleOptions.html
# askubuntu     -> https://askubuntu.com/questions/730609/how-can-i-find-the-directory-to-clang-format
# stackoverflow -> https://stackoverflow.com/a/39781747/7671328

column -t # 列对齐

                                                       # 文件如果是符号链接, 将使用符号链接对应的文件
comm                        1.c 2.c                    # 要求文件已排序, 以行比较
comm --check-order          1.c 2.c                    #   检测文件是否已排序
comm --nocheck-order        1.c 2.c                    # 不检测文件是否已排序
comm --output-delimiter=... 1.c 2.c                    # 指定列分割, 默认是 TAB
comm                        1.c 2.c       | tr -d '\t' # 全集
comm                        1.c 2.c -1 -2 | tr -d '\t' # 交集
comm                        1.c 2.c -3    | tr -d '\t' # B - A 和 A - B
comm                        1.c 2.c -1 -3              # B - A
comm                        1.c 2.c -2 -3              # A - B

cp    123 456      # 拷贝文件时, 使用符号链接所指向的文件
                   # 拷贝目录时, 目录中的符号链接将使用符号链接本身
                   # 456 只使用符号链接所指向的文件
cp -r 123 456      # 递归复制
cp -P 123 456      # 总是拷贝符号链接本身
cp -L 123 456      # 总是拷贝符号链接所指的文件
cp --parents a/b t # 全路径复制, 将生成 t/a/b

           # 定期执行命令
crontab -l # 查询任务表
crontab -e # 编辑任务表
           # 格式为: 分钟 小时 日 月 星期 执行的程序
           # *     : 每分钟执行
           # 1-3   : 1 到 3分钟内执行
           # */3   : 每 3 分钟执行一次
           # 1-10/3: 1-10 分钟内, 每 3 分钟执行
           # 1,3,5 : 1,3,5 分钟执行
           # crontab 不会自动执行 .bashrc, 如果需要, 需要在脚本中手动执行
crontab -r # 删除任务表

curl -I ... # 只打印头部信息
                                      # 文件如果是符号链接, 将使用符号链接对应的文件
cut                        -b 2   1.c # 按字节切割, 输出第 2 个字节
cut                        -c 2-  1.c # 按字符切割, 输出 [2, 末尾] 字符
cut                        -f 2-5 1.c # 按列切割,   输出 [2,5] 列
cut -d STR                 -f 2,5 1.c # 设置输入字段的分隔符, 默认为 TAB, 输出 第 2 列和第 5 列
cut -s                     -f  -5 1.c # 不输出不包含字段分隔符的列, 输出 [开头, 5] 的列
cut --output-delimiter=STR -f  -5 1.c # 设置输出的字段分隔符, 默认使用输入的字段分隔符

date "+%Y-%m-%d %H:%M:%S %z"        # 输出: 年-月-日 时-分-秒 时区
date "+%F %T %z"                    # 输出: 年-月-日 时-分-秒 时区
date "+%j"                          # 输出: 一年中的第几天
date "+%u"                          # 输出: 一周中的第几天(1..7), 1 为周一
date "+%U"                          # 输出: 一年中的第几周(00..53), 从周一开始
date "+%w"                          # 输出: 一周中的第几天(0..6), 0 为周末
date "+%W"                          # 输出: 一年中的第几周(00..53), 从周末开始
date "+%s"                          # 输出: 时间戳
date -d "2020-02-02 01:01:01 +0800" # 指定输入日期和时间, 秒数不能为 60
date -d "@...."                     # 使用: 时间戳
date -d "next sec"                  # 下一秒
date -d "next secs"                 # 下一秒
date -d "next second"               # 下一秒
date -d "next seconds"              # 下一秒
date -d "next min"                  # 下一分钟
date -d "next mins"                 # 下一分钟
date -d "next minute"               # 下一分钟
date -d "next minutes"              # 下一分钟
date -d "next hour"                 # 下一小时
date -d "next hours"                # 下一小时
date -d "next day"                  # 明天
date -d "next days"                 # 明天
date -d "next mon"                  # 下周一
date -d "next monday"               # 下周一
date -d "next month"                # 下个月
date -d "next months"               # 下个月
date -d "next year"                 # 下年
date -d "next years"                # 下年
date -d "next year  ago"            # 去年, 除年外, 其他也可以
date -d "next years ago"            # 去年, 除年外, 其他也可以
date -d "10year"                    # 十年以后, 除年外, 其他也可以
date -d "10years"                   # 十年以后, 除年外, 其他也可以
date -d "10   year"                 # 十年以后, 除年外, 其他也可以
date -d "10   years"                # 十年以后, 除年外, 其他也可以
date -d "10   year  ago"            # 十年以前, 除年外, 其他也可以
date -d "10   years ago"            # 十年以前, 除年外, 其他也可以
date -d "tomorrow"                  # 明天
date -d "now"                       # 现在
date -s "2020-02-02 10:10:10"       # 更新系统时间, 需要 root, 格式见 -d 选项
date -r 1.c                         # 使用: 文件的 mtime

diff    1.txt 2.txt # 比较两个文件的不同
diff -u 1.txt 2.txt # 一体化输出, 比较两个文件的不同

dd if=/dev/zero of=junk.data bs=1M count=1
dd if=/dev/zero bs=1M count=1000 | nc 127.0.0.1 9999 # 测速-客户端

df   -Th    # 文件系统挂载情况

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

dos2unix 1.txt # \r\n (windows) => \n (Linux/iOS)
unix2doc 1.txt # \n (Linux/iOS) => \r\n (windows)

                   # dpkg 为 apt 的后端
dpkg -i ...        # 安装本地的包
dpkg -L vim        # 列出 vim 软件包安装的全部文件
dpkg --search /... # 查看该文件是哪个软件包安装的, 使用绝对路径

du                      # 列出目录大小
du -0                   # 输出以 \0 分割, 默认是换行符
du -a                   # 列出目录和文件大小
du -d 1                 # 最大目录深度
du -sh                  # 只列出整体使用大小
du --exclude="*.txt"    # 忽略指定文件, 支持通配符

echo -n "123"                # 不换行
echo -e "\e[1;33m lyb \e[0m" # 文本黄色 加粗
echo  $'123\''               # 单引号内存在单引号的情况
echo  $(cal)                 # 输出字符以空格区分
echo "$(cal)"                # 保留输出字符的分割符
echo ${!S*}                  # 列出所有包含 S 的变量

env          # 设置环境变量, 然后执行程序

exec &>> 1.log  # 脚本内重定向
exec ls         # 替换当前 shell, 执行后不再执行之后的命令
exec &>  1.txt  # 打开文件描述符, 然后继续执行之后的命令

flock    1.c ls # 设置文件互斥锁 执行命令, 设置锁失败, 等待
flock -n 1.c ls # 设置文件互斥锁 执行命令, 设置锁失败, 退出

[[ "$FLOCKER" != "$0" ]] && exec env FLOCKER="$0" flock -en "$0" "$0" "$@" || :
                # 脚本内使用, 保证脚本最多执行一次
                # 解释:
                #   1. 第一次进入脚本, 由于变量未设置, 会执行 exec
                #   2. 调用 exec, 使用 env 设置 变量名
                #   3. 执行 flock, 重新执行这个脚本, 执行完脚本后会退出, 不会执行之后的命令
                #        * 使用脚本名作为 文件锁, 脚本名使用绝对路径, 所以不会重复
                #   4. 第二次进入脚本, 由于变量已设置, 直接往下执行就可以了
                # 5. 在此期间, 如果, 有其他脚本进入, 文件锁获取失败, 就直接退出了

file 1.txt # 查看换行符等

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

firewall-cmd --list-ports                      # 查看所有打开的端口
firewall-cmd --list-services                   # 查看所有打开的服务
firewall-cmd --get-services                    # 查看所有的服务
firewall-cmd --reload                          # 重新加载配置
firewall-cmd --complete-reload                 # 重启服务
firewall-cmd             --add-service=http    # 添加服务
firewall-cmd --permanent --add-service=http    # 添加服务, 永久生效, 需要重新加载配置
firewall-cmd             --remove-service=http # 移除服务
firewall-cmd             --add-port=80/tcp     # 添加端口
firewall-cmd --permanent --add-port=80/tcp     # 添加端口, 永久生效, 需要重新加载配置
firewall-cmd             --remove-port=80/tcp  # 移除端口
firewall-cmd             --query-masquerade    # 检查是否允许伪装IP
firewall-cmd               --add-masquerade    # 允许防火墙伪装IP
firewall-cmd --permanent   --add-masquerade    # 允许防火墙伪装IP, 永久生效, 需要重新加载配置
firewall-cmd            --remove-masquerade    # 禁止防火墙伪装IP
firewall-cmd --add-forward-port=proto=80:proto=tcp:toaddr=192.168.0.1:toport=8080
                                               # 端口转发, 0.0.0.0:80 --> 192.168.0.1:8080
firewall-cmd --add-forward-port=proto=80:proto=tcp:toaddr=192.168.0.1:toport=8080 --permanent
                                               # 端口转发, 永久生效, 需要重新加载配置
firewall-cmd --runtime-to-permanent            # 将当前防火墙的规则永久保存

free -h     # 内存使用情况

g++ -0g main.cc
g++ -01 main.cc
g++ -02 main.cc
g++ -03 main.cc
g++ -g  main.cc   # 生成 gdb 的文件

gdb [a.out] [pid]            # 启动 gdb               -- 常用
gdb> file a.out              # 设置可执行文件         -- 常用
gdb> set args	             # 设置程序启动命令行参数 -- 常用
gdb> show args	             # 查看设置的命令行参数
gdb> run [arguments]         # 运行程序(r)            -- 常用
gdb> attach pid              # gdb 正在运行的程序     -- 常用
gdb> info breakpoints        # 列出断点信息(i)        -- 常用
gdb> break file:line         # 在指定行设置断点(b)    -- 常用
gdb> break function          # 在制定函数设置断点(b)
gdb> break function if b==0  # 根据条件设置断点(b)
gdb> tbreak file:line        # 在指定行设置临时断点(tb)
gdb> disable breakpoints num # 禁用断点 num          -- 常用
gdb>  enable breakpoints num # 启用断点 num          -- 常用
gdb>  delete breakpoints num # 删除断点 num
gdb> clear   line            # 清除指定行的断点
gdb> continue [num]          # 继续运行到指定断点(c) -- 常用
gdb> until     line          # 运行到指定行(u)       -- 常用
gdb> jump      line          # 跳转到指定行(j), 和 until 的区别是跳过的代码不会执行
gdb> next     [num]          # 继续运行多次(n)       -- 常用
gdb> step                    # 进入函数(s)           -- 常用
gdb> finish                  # 退出函数(fin), 会执行完当前函数 -- 常用
gdb> return ...              # 退出函数, 并指定返回值, 和 finish 的区别是不会继续执行之后的代码, 直接返回
gdb> print v                 # 输出变量的值(p)       -- 常用
gdb> print v=123             # 修改变量的值(p)
gdb> p *pointer              # 输出指针指向的值
gdb> p arr[1]@3              # 输出数组 arr[1] 开始的3个元素
gdb> p/t var                 # 按  二进制格式显示变量
gdb> p/o var                 # 按  八进制格式显示变量
gdb> p/d var                 # 按  十进制格式显示变量
gdb> p/u var                 # 按  十进制格式显示无符号整型
gdb> p/x var                 # 按十六进制格式显示变量
gdb> p/a var                 # 按十六进制格式显示地址
gdb> p/c var                 # 按字符格式显示变量
gdb> p/f var                 # 按浮点数格式显示变量
gdb> p/s var                 # 字符串
gdb>         display v       # 和 p 类似, 但后续会自动输出变量的值
gdb> disable display num     # 暂时取消输出
gdb>  enable display num     # 恢复输出
gdb>  delete display num     # 删除自动输出变量的值的编号
gdb>       undisplay num     # 删除自动输出变量的值的编号
gdb> info    display         # 列出自动打印变量的值
gdb> x/8xb &v                # 输出 double 的二进制表示 -- 常用
gdb> x/nfu  v                # n 表示打印多少个内存单元
                             # f 打印格式, x d u o t a c f(默认8位)
                             # u 内存单元, b=1 h=2 w=4 g=8
                             # x 和 p 的区别
                             #   * p 的参数是变量的值, x 的参数是变量的地址
                             #   * p 打印的单位长度即是变量的长度, x 可以指定单位长度
                             #   * x 可以打印连续的多个单位长度(这个可以方便看 double 的每一个字节的内容)
gdb> list                    # 显示当前行之后的源程序(l) -- 常用
gdb> list -                  # 显示当前行之前的源程序
gdb> list 2,10               # 显示 2 - 10 行的源程序
gdb>  set listsize 20        # 设置列出源码的行数
gdb> show listsize           # 输出列出源码的行数
gdb> set  print elements 0   # 设置打印变量长度不受限制 -- 常用
gdb> show print elements
gdb> backtrace               # 显示堆栈信息(bt)        -- 常用
gdb> frame     n             # 查看指定层的堆栈信息(f) -- 常用
gdb> thread	                 # 切换到指定线程
gdb> watch	                 # 监视某一个变量的值是否发生变化
gdb> ptype	                 # 查看变量类型

getconf NAME_MAX / # 获取变量的值
getconf PATH_MAX /

getopts # 处理参数, -- 表示可选参数的终止

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
grep -P ..                # 使用 perl 风格的正则表达式
grep -W ..                # 单词匹配
grep -X ..                # 行匹配
grep ... --inclue "*.c"   # 指定文件
grep ... --exclue "*.c"   # 忽略文件
grep ... --exclue-dir src # 忽略目录

groups    # 列出用户所属的组名称
groupadd  # 添加组
groupmod  # 修改组信息, 包括组的ID和组名称
groupdel  # 删除组
groupmems # 管理当前用户的主组, 新增或删除成员
gpasswd   # 管理组, 新增或删除成员, 删除密码, 设置组管理人员等

hd         1.txt # 每组一个字节 显示十六进制+ASCII -- 不建议使用, 得考虑字节序
hexdump -b 1.txt # 每组一个字节 显示八进制
hexdump -c 1.txt # 每组一个字节 显示字符
hexdump -C 1.txt # 每组一个字节 显示十六进制+ASCII
hexdump -d 1.txt # 每组两个字节 显示  十进制
hexdump -o 1.txt # 每组两个字节 显示  八进制
hexdump -x 1.txt # 每组两个字节 显示十六进制

history

iconv -f gbk -t utf-8 1.txt -o 1.txt

id        # 输出实际或有效的用户和组信息

ifconfig -- 已过时, 被 ip addr  替代

ip a                                 # 显示网卡信息
ip addr    show                      # 显示指定网卡信息
ip address show dev   lo             # 显示指定网卡信息
ip address add 192.268.1.10 dev eth0 # 添加 IP 地址
ip address del 192.268.1.10 dev eth0 # 删除 IP 地址

ip link set dev eth0 multicast on  # 启用组播
ip link set dev eth0 multicast off # 禁用组播
ip link set dev eth0 up            # 启用网卡
ip link set dev eth0 down          # 禁用网卡
ip link set dev eth0 arp       on  # 启用 arp 解析
ip link set dev eth0 arp       off # 禁用 arp 解析
ip link set dev eth0 mtu      1500 # 设置最大传输单元
ip link set dev eth0 address  ...  # 设置 MAC 地址

ip route       # 路由信息
ip route show  # 路由信息
ip route get   # 查看指定 IP 的路由信息
ip route add   # 添加路由
ip route chage # 修改路由
ip route flush # 清空路由信息

ip neighbour  # 查看 arp 协议

ip -s link         # 查看统计信息
ip -s link ls eth0 # 查看统计信息, 指定网卡

ip maddr  # 广播
ip rule   # 路由策略, 和网卡有关
ip tunnel # 隧道

                              # 使用 iperf 测试的时候需要关掉防火墙: sudo systemctl stop firewalld
iperf -s                      # 服务器(TCP), 端口号为 5001
iperf -s -p 8080              # 服务器(TCP), 端口号为 8080
iperf -s -f MB                # 服务器(TCP), 端口号为 5001, 设置输出的单位
iperf -s -i 10                # 服务器(TCP), 端口号为 5001, 设置报告的时间间隔为 10s
iperf -s -D                   # 服务器(TCP), 端口号为 5001, 服务器在后台启动
iperf -s -1                   # 服务器(TCP), 端口号为 5001, 只接受一个客户端
iperf -s -N                   # 服务器(TCP), 端口号为 5001, 使用 TCP nodelay 算法
iperf -s -u                   # 服务器(UDP), 端口号为 5001
iperf -c 127.0.0.1            # 客户端(TCP), 服务器端口号为 5001
iperf -c 127.0.0.1 -p 8080    # 客户端(TCP), 服务器端口号为 8080
iperf -c 127.0.0.1 -i 1       # 客户端(TCP), 服务器端口号为 5001, 设置报告的时间间隔为 1s
iperf -c 127.0.0.1 -t 10      # 客户端(TCP), 服务器端口号为 5001, 设置测试时间为 10s
iperf -c 127.0.0.1 -f MB      # 客户端(TCP), 服务器端口号为 5001, 设置输出的单位
iperf -c 127.0.0.1 -b 100M    # 客户端(TCP), 服务器端口号为 5001, 设置发送速率
iperf -c 127.0.0.1 -n 100M    # 客户端(TCP), 服务器端口号为 5001, 设置测试的数据的大小
iperf -c 127.0.0.1 -k 100M    # 客户端(TCP), 服务器端口号为 5001, 设置测试的数据包的数量
iperf -c 127.0.0.1 -R         # 客户端(TCP), 服务器端口号为 5001, 反向测试, 服务端连客户端
iperf -c 127.0.0.1         -d # 客户端(TCP), 客户端连服务端的同时, 服务端同时连客户端, 端口号为 5001
iperf -c 127.0.0.1 -L 9090 -d # 客户端(TCP), 客户端连服务端的同时, 服务端同时连客户端, 端口号为 9090
iperf -c 127.0.0.1         -r # 客户端(TCP), 客户端连服务端结束后, 服务端连回客户端,   端口号为 5001
iperf -c 127.0.0.1 -L 9090 -r # 客户端(TCP), 客户端连服务端结束后, 服务端连回客户端,   端口号为 9090
iperf -c 127.0.0.1 -P 30      # 客户端(TCP), 客户端线程数为 30
iperf -c 127.0.0.1 -u         # 客户端(UDP)

jobs          # 列出后台作业
jobs %jobspec # 作业号有无 % 都成
jobs -l       #   列出后台作业的 PID
jobs -p       # 只列出后台作业的 PID
jobs -n       # 只列出进程改变的作业
jobs -s       # 只列出停止的作业
jobs -r       # 只列出运行中的作业

kill         pid # 通过进程ID发送信号给进程或进程组
kill -signal pid # 指定信号，默认值为 SIGTERM
kill -l          # 列出所有信号

killall             # 通过进程名称发送信号给进程或进程组, 进程名称精确匹配
killall -l          # 列出所有信号
killall -o 2m a.out # 发给 2 分钟前启动的 a.out
killall -y 2m a.out # 发给 2 分钟内启动的 a.out
killall -w    a.out # 等待进程结束

pkill         ... # 杀死进程, 扩展的正则表达式，参数和 pgrep 类似 -- 常用
pkill -signal ... # 指定信号，默认值为 SIGTERM

last      # 列出最近保存的登录的信息
lastb     # 列出最近保存的登录的信息, 包括失败情况

lastlog           # 列出最近一次的登录信息
lastlog -b 10     # 最近一次的登录在 10 天前的信息
lastlog -t 10     # 最近一次的登录在 10 天内的信息
lastlog -C -u lyb # 清除 lyb 最近一次的登录信息
lastlog -S -u lyb # 设置 lyb 最近一次的登录信息
lastlog    -u lyb # 查看 lyb 最近一次的登录信息
less # 空格   : 下一页
     # ctrl+F : 下一页
     # b      : 上一页
     # ctrl+b : 上一页
     # 回车   : 下一行
     # =      : 当前行号
     # y      : 上一行

ln -s target symbolic_link_name # 创建符号链接

ls &> /dev/null # 重定向

                   # lsof -- sudo yum install lsof
lsof -iTCP         # 查看 TCP 信息
lsof -i :22        # 查看指定 端口号 的信息
lsof -i@1.2.3.4:22 # 查看是否连接到指定 IP 和 端口号上
lsof -p 1234       # 指定 进程号
lsof -d 0,1,2,3    # 指定 文件描述符
lsof -t            # 仅获取进程ID

md5sum 1.txt # MD5 检验

more    # 空格   : 下一页
        # ctrl+F : 下一页
        # b      : 上一页
        # ctrl+b : 上一页
        # 回车   : 下一行
        # =      : 当前行号

mv a b # a 是符号链接时, 将使用符号链接本身
       # b 是指向文件  的符号链接时， 相当于 移到 b 本身
       # b 是指向目录  的符号链接时， 相当于 移到 b 最终所指向的目录下
       # b 是指向不存在的符号链接时， 相当于 重命名

                                        # 注意, 有不同版本的 nc, 参数不一定相同
nc -l             8080                  # 服务端(tcp), 接收单个连接
nc -lk            8080                  # 服务端(tcp), 接收多个连接
nc -lv            8080                  # 服务端(tcp), 显示连接信息
nc -lu            8080                  # 服务端(udp)
nc      127.0.0.1 8080                  # 客户端(tcp)
nc -n   127.0.0.1 8080                  # 客户端(tcp), 不进行域名解析, 节省时间
nc -N   127.0.0.1 8080                  # 客户端(tcp), 收到 EOF 后, 退出(有的版本不需要此参数, 会自动退出)
nc -w 3 127.0.0.1 8080                  # 客户端(tcp), 设置超时时间
nc -vz  127.0.0.1 8080                  # 客户端(tcp), 不发送信息, 只显示连接信息(测试单个端口)
nc -vz  127.0.0.1 8080-8090             # 客户端(tcp), 不发送信息, 只显示连接信息(测试多个端口)
nc -u   127.0.0.1 8080                  # 客户端(udp)
nc -lk            8080 | pv > /dev/null # 测速-服务端, 注意重定向, 否则会受限于终端的写速率
nc      127.0.0.1 8080      < /dev/zero # 测试-客户端

netstat  -- 已过时, 被 ss       替代

newgrp    # 切换组

nmap             127.0.0.1 # 主机发现 -> 端口扫描, 默认扫描 1000 个端口
nmap -p  80      127.0.0.1 # 主机发现 -> 端口扫描, 指定端口号
nmap -p  80-85   127.0.0.1 # 主机发现 -> 端口扫描, 指定端口号
nmap -p  80,8080 127.0.0.1 # 主机发现 -> 端口扫描, 指定端口号
nmap -Pn         127.0.0.1 # 跳过主机发现, 直接端口扫描
nmap -sn         127.0.0.1 # 主机发现

nohup sleep 1000 & # 脱离终端, 在后台运行, 忽略信号 SIGHUP

nslookup baidu.com # 查询 域名 对应 的 IP

ntpdate -s time-b.nist.gov          # 使用时间服务器更新时间

od -t a   1.txt # 每组一个字节, 显示字符(nl) -- 不建议使用, 得考虑字节序
od -t c   1.txt # 每组一个字节, 显示字符(\n)
od -t d4  1.txt # 每组四个字节, 显示有符号的十进制数字
od -t f4  1.txt # 每组四个字节, 显示浮点数
od -t o4  1.txt # 每组四个字节, 显示  八进制数字
od -t u4  1.txt # 每组四个字节, 显示无符号的十进制数字
od -t x4  1.txt # 每组四个字节, 显示十六进制数字
od -t d4z 1.txt # 每组四个字节, 显示十进制数字, 并显示原始字符
od -a     1.txt # 同 -t a
od -b     1.txt # 同 -t o1
od -c     1.txt # 同 -t c
od -d     1.txt # 同 -t u2
od -f     1.txt # 同 -t f
od -i     1.txt # 同 -t dI
od -l     1.txt # 同 -t dL
od -o     1.txt # 同 -t o2
od -s     1.txt # 同 -t d2
od -x     1.txt # 同 -t x2
od --endian={big|little} 1.txt # 指明大小端

passwd            # 修改 root 密码
passwd -stdin     # 修改 root 密码, 从标准输入读取
passwd        lyb # 修改 lyb  密码

patch     1.txt diff.pathc  # 恢复文件
patch -p1 1.txt diff.pathc  # 恢复文件, 忽略 diff.pathc 的第一个路径

ping      www.bing.com # 使用 ICMP ping 主机
ping -c 3 www.bing.com # 使用 ICMP ping 主机, 设置测试的次数
ping -i 3 www.bing.com # 使用 ICMP ping 主机, 设置间隔的秒数
ping -w 3 www.bing.com # 使用 ICMP ping 主机, 设置耗时的上限
ping -f   www.bing.com # 使用 ICMP ping 主机, 高速率极限测试, 需要 root 权限

                             # 多个命令之间取或
ps -U RUID -G RGID           # 实际的用户和组
ps -u EUID -g EGID           # 有效的用户和组
ps -p PID                    # 进程ID, 多个进程可以重复使用 -p 或者参数以分号分割 -- 常用
ps -s SID                    # 会话ID
ps --ppid PPID               # 父进程ID
ps -t ...                    # 终端
ps -C vim                    # 进程名称, 全名称 或 前 15 位

ps -o ruid,ruser,rgid,rgroup # 实际的用户和组
ps -o euid,euser,egid,egroup # 有效的用户和组
ps -o suid,suser,sgid,sgroup # 保存的用户和组
ps -o fuid,fuser,fgid,fgroup # 文件的用户和组, 一般和有效的相同
ps -o supgid,supgrp          # 附属组ID
ps -o pid,ppid,pgid,sid      # 进程ID, 父进程ID, 进程组ID, 会话ID
ps -o ouid                   # 会话ID所属用户ID
ps -o tty                    # 终端
ps -o tpgid                  # 输出前台进程的ID
ps -o luid,lsession          # 终端登录的用户ID和会话ID
ps -o stat,state             # 进程状态
                             # R 正在运行
                             # S 正在休眠(可被打断)
                             # D 正在休眠(不可被打断)
                             # T 后台暂停的作业
                             # t debug 调试中
                             # Z 僵尸进程
ps -o pmem,rsz,vsz           # 内存百分比,内存,内存(含交换分区)
ps -o pcpu,c,bsdtime,cputime # cpu: 百分比,百分比整数,user+system,system
ps -o lstart,etime,etimes    # 启动时间,运行时间,运行时间(秒), 无法对 etimes 进行排序
ps -o nice,pri,psr,rtprio    # 优先级
ps -o wchan                  # 进程休眠, 返回当前使用的内核函数
                             # 进程运行, 返回 -
                             # 列出线程, 返回 *
ps -o cmd                    # 启动命令
ps -o comm                   # 进程名称
ps -o fname                  # 进程名称的前 8 位

ps -e           # 所有进程
ps -H           # 输出进程树
ps -ww          # 不限制输出宽度
ps --no-headers # 不输出列头部
ps --headers    #   输出列头部
ps --sort -pcpu # cpu 使用率逆序

ps -o lwp,nlwp # 线程ID, 线程数
ps -L          # 列每一个线程

pstree     [PID] # 以进程 PID 为根画进程树, 默认为 1
pstree  -c [PID] # 展示所有子树
pstree  -p [PID] # 展示进程ID
pstree  -g [PID] # 展示进程组ID
pstree  -n [PID] # 使用 PID 排序而不是 进程名称
pstree  -l [PID] # 使用长行, 方便写入文件

              # 多个命令之间取且
pgrep         # 使用进程名称查找, 使用扩展的正则表达式
pgrep -f  ... # 使用启动命令匹配, 默认使用进程名称匹配(最多15位)
pgrep -c  ... # 输出匹配到的进程数目           -- 常用
pgrep -d，... # 设置输出的分割符，默认是换行符 -- 常用
pgrep -i  ... # 忽略大小写
pgrep -l  ... # 列出进程名称(最多15位)         -- 常用
pgrep -a  ... # 列出启动命令                   -- 常用
pgrep -n  ... # 仅列出最新的进程
pgrep -o  ... # 仅列出最旧的进程
pgrep -g  ... # 指定进程组ID
pgrep -G  ... # 指定实际组ID
pgrep -P  ... # 指定父进程ID
pgrep -s  ... # 指定会话ID
pgrep -t  ... # 指定终端
pgrep -u  ... # 指定有效用户ID
pgrep -U  ... # 指定实际用户ID
pgrep -v  ... # 反转结果
pgrep -x  ... # 精确匹配，默认不需要完全匹配
pgrep -w  ... # 列出线程ID

pidof    # 进程名称 => PID, 精确匹配, 没有长度限制
pwdx pid # 列出进程的当前工作目录

read name     # 读取, 如果参数值小于字段数, 多余的值放入最后一个字段

readlink    1.c.link  # 读取符号链接
readlink -f 1.c.link  # 读取符号链接, 递归

redis flushdb # 清空数据
redis -c ...  # 集群时需要使用 -c 启动, 否则查不到数据

route    -- 已过时, 被 ip route 替代

rz          #  windows 向 虚拟机  发送数据

sed    "p"                 1.txt #   正常使用
sed -e "p"                 1.txt #   使用 -e 添加脚本, -e 支持多次使用
sed -n "p"                 1.txt #   不输出模式空间的内容
sed -i "p"                 1.txt #   直接在原文件上修改
sed -r "p"                 1.txt #   使用扩展的正则表达式，默认使用基础的正则表达式 -- 推荐使用
sed -z "p"                 1.txt #   输入行以 \0 区分, 而不是 \n
sed -f 1.sed               1.txt #   从文件中读取脚本
sed -n "p"                 1.txt #   输出整个文件
sed -n "2p"                1.txt #   输出第二行
sed -n "2!p"               1.txt # 不输出第二行
sed -n "2,5p"              1.txt #   输出 [2,5] 行
sed -n "2,+4p"             1.txt #   输出 [2,6] 行
sed -n "$p"                1.txt #   输出最后一行
sed -n "/11/p"             1.txt #   输出匹配到 111 的行, 支持正则
sed -n "\c11cp"            1.txt #   输出匹配到 11 的行, c 可以使用任意字符, 便于处理包含 / 的情况
sed -n "/111/,/222/p"      1.txt #   输出匹配到 111 的行, 到匹配到 222 的行(包含)
                                 #       222 未匹配到时表示文件末尾
                                 #       开始匹配使用正则表达式时, 不能匹配同一行
sed -n "/111/,+4p          1.txt #   输出匹配到 111 的行以及接下来四行, 共五行
sed -n "0,/111/p"          1.txt #   输出文件开头到匹配到 111 的行
                                 #       如果 /111/ 可以匹配第一行，将输出第一行
sed -n "1,/111/p"          1.txt #   输出第一行到匹配到 111 的行
                                 #       /111/ 不会匹配第一行
sed -n ": ..."             1.txt # 定义标签
sed -n "="                 1.txt # 输出行号
sed -n "a ..."             1.txt # 行后插入
sed -n "b ..."             1.txt # 跳到标签处，如果标签未指定时，跳到脚本末尾
sed -n "c ..."             1.txt # 取代所选择的行
sed -n "d"                 1.txt # 删除模式空间的内容, 并进入下一循环
sed -n "D"                 1.txt # 删除模式空间的第一行内容
                                 #     如果模式空间变为空，开始下一循环
                                 #     否则，跳到脚本开始处继续
sed -n "g"                 1.txt # 将保持空间复制到模式空间
sed -n "G"                 1.txt # 将保持空间附加到模式空间
sed -n "h"                 1.txt # 将模式空间复制到保持空间
sed -n "H"                 1.txt # 将模式空间附加到保持空间
sed -n "i ..."             1.txt # 行前插入
sed -n "l"                 1.txt # 列出当前行，标明不可见字符
sed -n "n"                 1.txt # 读取下一行到模式空间
sed -n "N"                 1.txt # 将下一行添加到模式空间内容后
sed -n "p"                 1.txt # 打印模式空间的内容
sed -n "P"                 1.txt # 打印模式空间的第一行内容
sed -n "2q"                1.txt # 输出第一行，第二行后退出
sed -n "2Q"                1.txt # 输出第一行后退出
sed -n "r..."              1.txt # 每一行后添加文件的内容
                                 #     貌似无法在文件开头添加另一文件的内容
sed    "R2.txt"            1.txt # 第一行后插入 2.txt 的第一行
                                 # 第二行后插入 2.txt 的第二行, 如果 2.txt 已读完，则不插入
sed    "s/123/456/"        1.txt # 替换第一处
sed    "s/123/456/2"       1.txt # 替换第二处
sed    "s/123/456/2g"      1.txt # 替换第二处及以后
sed    "s/123/456/g"       1.txt # 替换所有
sed -n "s/123/456/gp"      1.txt # 打印替换后的结果
sed -n "s/123/456/gw2.txt" 1.txt # 替换后的结果写入文件 2.txt
sed    "s|123|456|"        1.txt # 使用不同的分割符
sed    "s/.*/[&]/"         1.txt # & 用于表示所匹配到的内容
sed    "s/\(1\)/[\1]/"     1.txt # \1 表示第一个字串
sed -r "s/(1)/[\1]/"       1.txt # \1 表示第一个字串
sed    "s/1/a \t b/"       1.txt # 可以包含 \n \t
sed -n "t abc              1.txt # 前一个 s 命令成功会跳转到指定标签   -- 这个一般用不上
sed -n "T abc              1.txt # 前一个 s 命令未成功会跳转到指定标签 -- 这个一般用不上
sed -n "w ..."             1.txt # 写模式空间的内容到文件
sed -n "W ..."             1.txt # 写模式空间的第一行的内容到文件
sed -n "x"                 1.txt # 交换模式空间和保持空间的内容
sed -n "y/123/456/"        1.txt
sed -n "y/1-3/456/"        1.txt
sed -n "y/123/4-6/"        1.txt
sed -n "y/1-3/4-6/"        1.txt
                                 # 测试 301-03.sh

set -o nounset  # 使用未初始化的变量报错, 同 -u
set -o errexit  # 只要发生错误就退出, 同 -e
set -o pipefail # 只要管道发生错误就退出
set -o errtrace # 函数报错时, 也处理 trap ERR, 同 set -E
set -o  xtrace  # 执行前打印命令, 同 -x
set -o verbose  # 读取前打印命令, 同 -v
set -o vi       # 使用 vi 快捷键
set -- ....     # 重新排列参数
                # 建议使用: set -ueo pipefail

sg        # 使用其他组执行命令

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

ss       # 显示已连接的 UDP, TCP, unix domain sockets
ss -x    # unix domain sockets
ss -u    #          UDP
ss -t    # 已连接的 TCP
ss -tl   #   监听的 TCP
ss -ta   # 已连接和监听的 TCP
ss -tln  # 服务使用数字而不是名称
ss -tlnp # 列出监听的进程号, 需要root 权限
ss -s    # 显示统计
ss src   192.168.198.128:22  # 通过源  IP和端口号筛选信息
ss dst   192.168.198.1:51932 # 通过目的IP和端口号筛选信息
ss sport OP 22               # 通过源  端口号过滤数据
ss dport OP 22               # 通过目的端口号过滤数据
                             # OP 可以是空, >(gt) >=(ge) <(lt) <=(le) ==(eq) !=(ne), 注意转义

### 密钥登录
主目录权限不能是 777

### 常用命令
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

strace               # 追踪进程的系统调用和信号处理
strace cmd argv      # strace 和命令 同时启动
strace -p pid        # 追踪正在运行的程序, 多个进程, 指定 -p 多次
strace -c            # 统计系统调用的时间, 次数
strace -o ...        # 输出到指定的文件
strace -tt           # 显示调用时间 时分秒.毫秒
strace -T            # 显示系统调用的耗时
strace -f            # 跟踪子进程, 不包括 vfork
strace -F            # 跟踪 vfork
strace -e trace=...  # 跟踪指定信号调用
strace -s ...        # 参数是字符串时, 最大输出长度, 默认是32个字节
strace -e signal=... # 跟踪指定信号

su        # 切到 root
su -      # 切到 root, 更新主目录, 环境变量等, 相当于重新登录
su   lyb  # 切到 lyb

sudo                                          # 权限管理文件: /etc/sudoers, 使用 visudo 编辑
sudo -u USERNAME COMMAND                      # 指定用户执行命令
sudo -S date -s "20210722 10:10:10" <<< "123" # 脚本中免密码使用

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

tac               # 最后一行 => 第一行

tail -f * # 动态查看新增内容

tcpdump 可选项 协议(tcp udp icmp ip arp) 源(src dst) 类型(host net port portrange) 值
* [S]: SYN(发起连接), [P]: push(发送), [F]:fin(结束), [R]: RST(重置), [.](确认或其他)
* ack 表示下一个要接收的 seq 号
* length 有效数据的长度
* win 接收窗口的大小
* 为避免shell干扰, 可将内容用引号包含
* and  or 可以组合多个条件

tcpdump -D                      # 列出可以 tcpdump 的网络接口
tcpdump -i eth0                 # 捕捉某一网络接口
tcpdump -i any                  # 捕捉所有网络接口
tcpdump -i any -c 20            # 捕捉所有网络接口, 限制包的数量
tcpdump -i any -n               # 捕捉所有网络接口, 使用IP和端口号, 而不是域名和服务名称
tcpdump -i any -w ...           # 捕捉所有网络接口, 将数据保存在文件中
tcpdump -i any -r ...           # 捕捉所有网络接口, 从文件中读取数据
tcpdump -i any -A               # 捕捉所有网络接口, 打印报文 ASCII
tcpdump -i any -x               # 捕捉所有网络接口, 打印包的头部, -xx -X -XX 类似
tcpdump -i any -e               # 捕捉所有网络接口, 输出包含数据链路层信息
tcpdump -i any -l               # 捕捉所有网络接口, 使用行缓存, 可用于管道
tcpdump -i any -N               # 捕捉所有网络接口, 不打印域名
tcpdump -i any -Q in            # 捕捉所有网络接口, 指定数据包的方向 in, out, inout
tcpdump -i any -q               # 捕捉所有网络接口, 简洁输出
tcpdump -i any -s ...           # 捕捉所有网络接口, 设置读取的报文长度,0 无限制
tcpdump -i any -S ...           # 捕捉所有网络接口, 使用绝对 seq
tcpdump -i any -v               # 捕捉所有网络接口, 显示详细信息, -vv -vvv 更详细
tcpdump -i any -t               # 捕捉所有网络接口, 不打印时间
tcpdump -i any -tt              # 捕捉所有网络接口, 发送(绝对时间), 确认(绝对时间)(时间戳)
tcpdump -i any -ttt             # 捕捉所有网络接口, 发送(相对时间), 确认(相对间隔)(时分秒 毫秒)
tcpdump -i any -tttt            # 捕捉所有网络接口, 发送(绝对时间), 确认(绝对时间)(年月日-时分秒)
tcpdump -i any -ttttt           # 捕捉所有网络接口, 发送(相对时间), 确认(相对时间)(时分秒 毫秒)
tcpdump -l                      # 使用行缓存, 可用于管道
tcpdump src  host 192.168.1.100 # 指定源地址 可以使用 /8 表明网络
tcpdump dst  host 192.168.1.100 # 指定目的地址
tcpdump      host 192.168.1.100 # 指定主机地址
tcpdump       net 192.168.1     # 指定网络地址, 也可以使用 /8 表示
tcpdump src  port 22            # 指定源端口号
tcpdump dst  port 22            # 指定目的端口号
tcpdump      port 22            # 指定端口号, 可使用服务名称
tcpdump not  port 22            # 排除端口号
tcpdump tcp                     # 指定协议
tcpdump "tcp[tcpflags] == tcp-syn" # 基于tcp的flag过滤
tcpdump less 32                 # 基于包大小过滤
tcpdump greater 64              # 基于包大小过滤
tcpdump ether   host  ...          # 基于 MAC 过滤
tcpdump gateway host ...          # 基于网关过滤
tcpdump ether broadcast      # 基于广播过滤
tcpdump ether multicast      # 基于多播过滤
tcpdump ip broadcast         # 基于广播过滤
tcpdump ip multicast         # 基于多播过滤

tee    1.txt # 管道中把文件拷贝到文件
tee -a 1.txt # 管道中把文件添加到文件

top     # 第一行 系统时间 运行时间 用户数 平均负载
        # 第二行 进程总结
        # 第三行 CPU 总结
        # 第四行 物理内存总结
        # 第五行 虚拟内存总结
        # 交互命令
        #   空格 或 回车 刷新
        #   l 切换负载的显示
        #   t 切换任务的显示
        #   m 切换内存的显示
        #   f 选择展示的字段
        #   R 反向排序
        #   c 显示命令名称 或 完整命令行
        #   i 显示空闲任务
        #   u 显示特定用户的进程
        #   k 结束任务
        #   h 帮助
        #   L 搜索字符串
        #   H 显示线程
        #   0 不显示统计值为 0 的项
        #   1   显示所有的cpu信息
        #   < 排序字段左移
        #   > 排序字段右移
        #   M 内存排序
        #   P CPU 排序
        #   T 时间排序
top -n 1   # 刷新次数
top -b     # 方便写入文件
top -c     # 显示完整命令行
top -p ... # 指定 PID
top -u lyb # 指定用户


tr    'a-z' 'A-Z' # 小写转大写
tr -d 'a-z'       # 删除字符
tr -s ' '         # 压缩字符

traceroute: 查看数据包经过的路径

trap ... ERR  # 发生错误退出时, 执行指定命令
trap ... EXIT # 任意情况退出时, 执行指定命令

tree -p "*.cc"       # 只显示  匹配到的文件
tree -I "*.cc"       # 只显示没匹配到的文件
tree -H . -o 1.html  # 指定目录生成 html 文件

uname -a # 全部信息
uname -m # x86_64 等
uname -r # 内核版本

uniq    # 删除重复的行
uniq -c # 输出统计的次数
uniq -d # 只输出重复的行, 重复的项只输出一次
uniq -D # 只输出重复的行, 重复的项输出多次
uniq -i # 忽略大小写
uniq -u # 只输出没重复的行

uptime -s # 列出系统启动时间

users  # 列出所有登陆用户

useradd           # 添加用户或修改默认配置
useradd -c ...    #   指定关于用户的一段描述
useradd -e ...    #   指定用户过期日期, YYYY-MM-DD
useradd -f ...    #   指定用户密码过期到账户临时不可用的天数
useradd -g ...    #   指定主组, 主组必须存在
useradd -G ...    #   指定附属组, 附属组必须存在, 可以多个, 以逗号分割
useradd -k ...    #   指定主目录模板, 如果主目录由 useradd 创建, 模板目录中的文件将拷贝到新的主目录中
useradd -K ...    #   修改默认参数
useradd -s ...    #   指定shell
useradd -D        #   查看默认配置
useradd -D ...    #   修改默认配置
useradd    -b ... #   指明主目录的父目录, 父目录必须存在
useradd -m -b ... #   指明主目录的父目录, 父目录不必存在, 会自动新建
useradd    -d ... #   指明主目录, 主目录可以不存在, 不存在的话不会新建
useradd -m -d ... #   指明主目录, 主目录可以不存在, 不存在的话会自动新建
useradd -m ...    #   用户主目录不存在的话自动新建
useradd -M ...    #   用户主目录不会新建
useradd -N ...    #   不创建和用户同名的组
useradd -o ...    #   允许 UID 重复
useradd -r ...    #   创建系统用户
useradd -u ...    #   指定 UID 的值
useradd -U ...    #   创建和用户同名的组

userdel    ...    # 删除用户
userdel -r ...    #   删除用户及其主目录

usermod           # 修改用户
usermod -a -G ... #   添加附属组
usermod -m ...    #   移动主目录
usermod -l ...    #   修改登录名
usermod -L ...    #   锁定用户
usermod -U ...    #   解锁用户
                  #   其他选项同 useradd

cat lyb | xargs -i vim {} # 以此编辑 lyb 中的每一个文件

xxd -b     1.txt  # 输出二进制而不是十六进制
xxd -e     1.txt  # 使用小端模式
xxd -g ... 1.txt  # 每组的字节数            -- 建议使用, 读取的顺序和存储的顺序相同, 不需要考虑字节序

w      # 列出谁登录, 以及目前在干什么
who    # 列出谁登录
who -m # 列出当前终端登录的用户
whoami # 列出当前终端的有效用户

wc    # 输出 换行符数 字符串数 字节数
wc -l #   行数
wc -w # 字符串数
wc -c # 字节数
wc -m # 字符数

yum install epel-release # 安装软件源 epel
yum check-update         # 更新软件源
                         # 软件源: /etc/yum.repos.d/
                         # * [...]           -- 源的名字
                         # * name=...        -- 源的描述
                         # * baseurl=file:// --	源的路径, file:// 表示本地仓库
                         # * enabled=...	 --	是否启用该仓库, 1-启用, 0-不启用
                         # * gpgcheck=...	 -- 是否不用校验软件包的签名, 0-不校验, 1-校验
                         # * gpgkey=...      -- 上个选项对应的 key 值
yum clean all            # 清空软件源缓存
yum makecache            # 新建软件源缓存
yum repolist             # 查看软件源(可达的)

yum search vim           # 搜寻软件包
yum install package-name # 安装软件, 也可以本地安装
yum localinstall ...     # 本地安装
yum update package-name  # 更新某个软件包
yum update               # 更新所有软件包
yum remove  package-name # 卸载软件
yum erase   package-name # 卸载软件，删除数据和文件

yum list installed       # 列出已安装的软件
yum list vim             # 列出某软件包的详细信息
yum list updates         # 列出可用更新
yum provides vim         # 查看软件属于哪个软件包
yum provides /etc/vimrc  # 查看文件由哪个软件使用

## 建议
* 使用 pgrep 获取 PID, 使用 ps 列出详细信息
* 使用 etimes 可以方便计算出启动时间, 并格式化 年-月-日 时-分-秒 时区
* 一般使用进程的前 15 位即可
* 使用 pkill 发送信号
```

## 简介

## 申明和定义
* 变量使用前必须申明或定义
* 多个文件使用相同的变量时, 注意防止重复定义, 使用前确保初始化已完成

## 赋值和初始化
* 初始化使用构造函数
* 赋值使用重载的赋值运算符

## 循环
* 普通循环: for(int i = 0; i < 10; ++i)
* 普通循环: for(.. it = ve.begin(); it != ve.end(); ++it)
* 范围for:  for(auto& v : ve)
* 范围for:  for(const auto& v : ve)
* 推荐使用范围for, 更方便

## 函数
* 参数传递即可以使用值传递也可以使用引用传递
* 使用 tuple 可以返回多个值

## 类
* 使用 `.` 获取成员变量或函数

## 常用库
* vector<int>
* list<int>
* map<string, int>
* set<string>
* unordered_map<string, int>
* unordered_set<string>
* queue<string>
* stack<string>

要使用常量时, 直接在前添加 const 即可, 比如 const vector<int>

## 常用函数
* all_of, any_of, none_of
* find, find_if, find_if_not
* copy, copy_if, copy_n, copy_backward
* fill, fill_n
* remove, remove_if, remove_copy, remove_copy_if
* replace, replace_if, replace_copy, replace_copy_if
* swap, swap_ranges, iter_swap
* reverse, reverse_copy
* generate, generate_n 生成区间
* rotate, rotate_copy 轮询
* unique, unique_copy
* count, count_if: 统计出现的次数
* is_sorted, is_sorted_until, sort, partial_sort, partial_sort_copy, stable_sort, nth_element
* set_difference, set_intersection, set_symmetric_difference, set_union 集合
* is_heap, is_heap_until, make_heap, push_heap, pop_heap, sort_heap
* max, max_element, min, min_element, minmax, minmax_element
* lexicographical_compare 区间比较大小
* is_permutation, next_permutation, prev_permutation 全排序
* is_partitioned, partition, partition_copy, stable_partition, partition_point 区间分成两半
* merge, inplace_merge
* for_each: 对区间内的元素执行谓词
* binary_search
* lower_bound, upper_bound, equal_range
* equal
* iota
* accumulate
* transform 转换结果到指定区间
* inner_product 内积
* adjacent_difference 连续元素的差值
* adjacent_find 查找相邻元素里, 第一个相同的元素
* partial_sum 前 n 项的和
* mismatch: 判断两个区间第一个不相同的位置
* includes 子序列
* find_end 最后一个子区间
* find_first_of 查找后区间内的任何元素在前区间第一次出现的位置
* search 第一个子区间
* search_n 查找前者包不包括几个连续的值

## 高级特性
* 对于普通程序员来说，模板元编程只需明白原理，实现能看懂即可, 一般也不会用到

cpp

定义
声明

赋值
初始化

## 面向过程
## 基于对象
## 面向对象
## 泛型
## 函数式


       const int i = 1; # 只在本文件内有效
extern const int i = 1; # 可以在其他文件中使用

顶层const: 变量本身是个常量
底层const: 变量所指向的值是个常量

std::getline(std::cin, str); // 读取一行, 包括换行符, str 不会存储换行符

整数除以整数, 无论正负, 小数部分直接舍弃
商的符号由除数和被除数决定
余数的符号只由被除数决定

     static_cast -- 不含底层const的转换, 明确定义, 比如, long -> int, void* -> int*
      const_cast --     底层const的转换, 比如, const int* => int*
reinterpret_cast -- 重新解释底层存储, 比如 long* -> double*
    dynamic_cast

std::initializer_list<> 可变参数

函数重载和默认参数

mutable 类可变成员

explicit

string 短字符串优化, 所以 swap 可能会真正交换元素, 而不是拷贝指针

## IO
iostream(istream, ostream)(控制台)
fstream(ifstream, ofstream)(文件)
sstream(istringstream, ostringstream)(string)

全缓冲(文件)
行缓冲(终端)
无焕冲(错误)

刷新缓冲
1. 程序正常结束
2. 缓冲区满
3. 使用 std::endl
4. 使用 flush
4. 使用 unitbuf , 使用 nounitbuf 重置流
5. 关联的流使用时, 会刷新缓冲, 比如, 输入输出关联到终端, 输入时会刷新输出流

## 迭代器
输入迭代器
输出迭代器
前向迭代器
双向迭代器
随机访问迭代器

插入迭代器(back_inserter, front_inserter, inserter)
流迭代器(istrean_iterator, ostrean_iterator)
反向迭代器

## 异常安全

## 可调用对象
函数
函数指针
lambda
std::bind (ref, cref 引用)
std::function

## 智能指针(引用计数)
* std::shared_ptr
	* 初始化
	    * std::shared_ptr<T>(p)    -- p 指向动态分配的内存 -- 不建议
		* std::shared_ptr<T>(q, d) -- p 可以是普通指针, d 为析构时的处理
		* std::make_shared -- 建议
	p.use_count()
	p.unique()
	p.get()
	p.reset(...)
std::unique_ptr
	* 初始化
	    * std::unique_ptr<T>(p)    -- p 指向动态分配的内存 -- 不建议
		* std::shared_ptr<T, D>(q, d) -- p 可以是普通指针, d 为析构时的处理, 处于效率的考虑, 删除器使用模板
		* std::make_unique -- 建议, C++14
	p.release() -- 放弃指针的占用, 并返回
	p.reset(...)
std::weak_ptr -- 不影响引用计数
	w.reset()
	w.unique()
	w.use_count()
	w.expired() -- 所关联的智能指针是否存在
	w.lock() -- 返回智能指针

使用动态分配内存的场景
1. 不知道有多少元素(std::vector)
2. 不知道对象的准确类型
3. 多个对象共享数据


* 申请了内存, 没有释放(内存泄漏)
* 释放了内存, 还在使用(野指针)
* 使用空指针
* 多次释放内存

## 类
delete
default
override
final

awk '
     BEGIN   { getline     } # 可选  读取一行
     pattern { commands    } # pattern 类型
                             #      * NR < 5        # 行号 [1,4] 的行
                             #      * NR==1,NR==4   # 行号 [1,4] 的行
                             #      * /linux/       #   包含 linux 的行, 支持正则
                             #      * !/linux/      # 不包含 linux 的行, 支持正则
                             #      * /start/,/end/ # [] 区间匹配, 支持正则
                             #      * $1  ~ /123/   # 使用正则表达式匹配
                             #      * $1 !~ /123/   # 使用正则表达式匹配, 排除匹配到的行
                             #      * $1 ==  123    # 数值匹配, 精确匹配
                             #      * $1 == "123"   # 字符串匹配, 精确匹配
     END     { print "end" } # 可选
    ' 1.txt

awk            '{ print $0 }' 1.txt #
awk -F:        '{ print $0 }' 1.txt # 以字符       : 作为字段分割符
awk -F123      '{ print $0 }' 1.txt # 以字符串   123 作为字段分割符
awk -F[123]    '{ print $0 }' 1.txt # 以字符   1 2 3 作为字段分割符
awk -f         1.awk          1.txt # 从文件中读取命令
awk -v lyb=... '{ print $0 }' 1.txt # 定义变量
    # * 数字:
    #     * 包括整数和浮点数
    #     * 整数除以整数，结果可能是小数
    #     * int(...) 将浮点数转换为整数，将舍弃小数部分，比如 int(1.9) == 1, int(-1.9) == -1
    #     * + 将对数字进行相加, 即使是字符串
    # * 字符串：以单引号 或 双引号 包含的字符串
    #     * tolower() -- 小写
    #     * toupper() -- 大写
    #     * length()  -- 长度
    #     * sub() -- 正则查找, 替换第一处
    #     * gsub() -- 正则查找, 替换所有
    #     * gensub() -- 正则查找, 可选择替换所有还是某一个, 不修改原字符串
    #     * index() -- 字符串查找
    #     * match() -- 字符串查找(正则表达式), 并将结果保存到数组
    #     * split() -- 字符串 => 数组
    #     * 字符串连接直接使用空分开即可
    # * 数组：awk 使用关联数组，下标使用数字或字符串都成
    #     * 添加或修改元素  : arr[i] = ...
    #     * 删除数组中的变量: delete arr[i]
    #     * 遍历数组: i 为数组下标，注意返回的顺序不固定
    #         for (i in arr) {
    #             ....
    #         }
    #     * asort()  -- 元素排序
    #     * asorti() -- 索引排序
    # * 变量:
    #     * 变量不需要声明，可以直接使用
    #     * 变量使用一般不用使用 $, 除非是数字型变量，为了和数字区分，需要加上 $ 符号
    # * 赋值：赋值号左右两边有无空格都成
    # * 语句使用分号分割
    # *       if 语句, 同 C语言
    # *    while 语句, 同 C语言
    # * do while 语句, 同 C语言
    # *      for 语句，同 C语言, 外加 for (i in arr) i 为索引, arr 为数组
    # * 时间函数
    #     * systime()  -- 获取当前的时间戳
    #     * strftime() -- 时间戳 --> 格式化
    #     * mktime()   -- 年月日等 --> 时间戳
    # * 其他常用函数
    #     * print    参数以逗号分割，输出的字段分割符默认为空格，结尾将输出换行符
    #     * printf   同 C 语言
    # * 常用变量
    #       * $0  整行
    #       * $1  第一列
    #       * FS  输入字段分隔符 默认值为空字符
    #       * RS  输入记录分隔符 默认值为换行符
    #       * OFS 输出字段分隔符 默认值为空格
    #       * ORS 输出记录分隔符 默认值为换行符
    #       * FILENAME   用作gawk输入数据的数据文件的文件名
    #       * FNR        当前数据文件中的数据行数
    #       * IGNORECASE 设成非零值时，忽略gawk命令中出现的字符串的字符大小写
    #       * NF         数据文件中的字段总数
    #       * NR         已处理的输入记录数
    #       * RLENGTH    由match函数所匹配的子字符串的长度
    #       * RSTART     由match函数所匹配的子字符串的起始位置
    # * 函数, 执行 shell 命令及测试 见: 301-04.sh


# 计算机语言-Bash
## 简介
* Bash 是脚本, 一门编程语言

## 特殊字符 -- 要使用原字符必须转义
```
* 没引号包含
    * {} # 变量分割符 或 块语句
    * [] # 通配符 或 数字计算等等
    * () # 子shell
    * $  # 读取变量, 无值时默认忽略
    * !  # 一些快捷的方式获取命令或参数
    * ;  # 命令的分割符
    * #  # 注释
    * -  # 字符串以 - 开头表示是可选参数
    * -- # 后面的字符串都不是可选参数
    * '  # 单引号
    * "  # 双引号
    * &  # 后台运行
* 单引号包含:
    * '  # 单引号, 需要在字符串开头加上 $ 符号
* 双引号包含:
    * $  # 读取变量, 无值时默认忽略
    * !  # 一些快捷的方式获取命令或参数
    * "  # 双引号
```

## 特殊变量
```
$HOME  # 主目录
$IPS   # 默认分隔符, 默认为: " \t\n", 包含转义字符时, 需要在开头添加 $, IFS=$'\n'
$PATH  # 命令路径
$PS1   # 提示符
$PWD   # 当前工作目录
$SHELL # 当前 shell
$?     # 上一命令执行是否成功
$$     # shell ID
$_     # 上一命令的最后一个参数
$!     # 后台最后一个进程的进程 ID
$0     # shell 名称
$-     # shell 启动参数
```

## 字符串(包括数字)
```
v=...   #   解析变量和转义字符
v="..." #   解析变量和转义字符
v='...' # 不解析变量和转义字符
v="...
...
"       # 字符串跨行
v='...
...
'       # 字符串跨行

${v:-w}              # v 不为空, 返回 $v, 否则, 返回 w
${v:=w}              # v 不为空, 返回 $v, 否则, 令 v=w, 返回 w
${v:+w}              # v 不为空, 返回  w, 否则, 返回空
${v:?w}              # v 不为空, 返回 $v, 否则, 输出 w, 退出
${#val}              # 输出字符串的长度
${val:起始位置:长度} # 获取子串
lyb=123
lyb=$lyb+123         # 字符串连接, lyb 将变成 123+123
lyb=123.456.txt
lyb=${lyb%.*}        # 后缀非贪婪匹配, lyb 为 123.456
lyb=${lyb%%.*}       # 后缀  贪婪匹配, lyb 为 123
lyb=${lyb#*.}        # 前缀非贪婪匹配, lyb 为 456.txt
lyb=${lyb##*.}       # 前缀  贪婪匹配, lyb 为 txt
lyb=${lyb/*./str}    # 全文  贪婪匹配, lyb 为 strtxt, 匹配一次
lyb=${lyb//*./str}   # 全文  贪婪匹配, lyb 为 strtxt, 匹配多次
lyb=${lyb^^}         # 变为大写
lyb=${lyb,,}         # 变为小写
```

## 索引数组
```
* v=(1 2 3)  # 初始化数组, 以空字符分割多个元素
* ${v[1]}    # 数组中指定元素的值
* ${v[-1]}   # 数组中最后一个元素的值
* ${v[@]}    # 数组中所有元素的值, "1" "2" "3"
* ${#v[@]}   # 数组中元素的个数
* ${!v[@]}   # 获取所有的 key
* v+=(1 2 3) # 添加数组元素
```

## 关联数组
```
* declare -A v # 声明
* v[a]=a       # 赋值
* v[-1]=b      # 以 -1 作为 key
               # 其他同索引数组
```

## 模拟命令的标准输入
```
解释变量
cat << EOF
    $lyb
EOF

解释变量
cat << "EOF"
    $lyb
EOF

不解释变量
cat << 'EOF'
    $lyb
EOF

cat <<<  $lyb  #   解释变量
cat <<< "$lyb" #   解释变量
cat <<< '$lyb' # 不解释变量
```

## 括号 -- 只列举常用的情况
```
* 命令替换使用 $() 而不是反引号
    * (ls)         # 子shell执行命令, 输出到屏幕上
    * lyb=$(ls)    # 子shell执行命令, 存入变量
* 整数运算
    * (())         # 整数运算, 变量不需要加 $
    * lyb=$((...)) # 将结果存储在变量中
* 使用 [[ ... ]] 测试
    * [[     -z "$lyb"   ]] # 判断是否空字符串
    * [[     -n "$lyb"   ]] # 判断是否不是空字符串
    * [[ !   -n "$lyb"   ]] # 非操作
    * [[ "111" =~ 1{1,3} ]] # 扩展的正则表达式匹配
    * [[     -a file     ]] # file 存在
    * [[     -e file     ]] # file 存在
    * [[     -f file     ]] # file 存在且普通文件
    * [[     -d file     ]] # file 存在且是目录
    * [[     -h file     ]] # file 存在且是符号链接
    * [[     -L file     ]] # file 存在且是符号链接
    * [[     -b file     ]] # file 存在且是  块文件
    * [[     -c file     ]] # file 存在且是字符文件
    * [[     -p file     ]] # file 存在且是一个命名管道
    * [[     -S file     ]] # file 存在且是一个网络 socket
    * [[     -s file     ]] # file 存在且其长度大于零, 可用于判断空文件
    * [[     -N file     ]] # file 存在且自上次读取后已被修改
    * [[     -r file     ]] # file 存在且可读
    * [[     -w file     ]] # file 存在且可写权
    * [[     -x file     ]] # file 存在且可执行
    * [[     -u file     ]] # file 存在且设置了 SUID
    * [[     -g file     ]] # file 存在且设置了 SGID
    * [[     -k file     ]] # file 存在且设置了 SBIT
    * [[     -O file     ]] # file 存在且属于有效的用户 ID
    * [[     -G file     ]] # file 存在且属于有效的组   ID
    * [[     -t fd       ]] # fd 是一个文件描述符，并且重定向到终端
    * [[ FILE1 -nt FILE2 ]] # FILE1 比 FILE2 的更新时间更近, 或者 FILE1 存在而 FILE2 不存在
    * [[ FILE1 -ot FILE2 ]] # FILE1 比 FILE2 的更新时间更旧, 或者 FILE2 存在而 FILE1 不存在
    * [[ FILE1 -ef FILE2 ]] # FILE1 和 FILE2 引用相同的设备和 inode 编号
* cat <(ls)                 # 将命令或函数的输出作为文件
```

## 脚本
```
$0 # 脚本名称
$1 # 第一个参数
$@ # 参数序列
$# # 参数个数

if for while

function

函数内建议使用 local 局部变量, 声明和使用放到不同的行
```

测试文件: [301-01.sh](./301-01.sh)

## 通配符
```
* ~           # 用户主目录
* ~lyb        # 用户 lyb 的主目录, 匹配失败的话, 不扩展
* ~+          # 当前目录
* ?           # 任意单个字符, 匹配失败的话, 不扩展
* *           # 任意多个字符, 匹配失败的话, 不扩展
* [123]       # [1,3] 中任意一个, 匹配失败的话, 不扩展
* [1-5]       # [1,5] 中任意一个, 匹配失败的话, 不扩展
* [!a]        # 非 a, 匹配失败的话, 不扩展
* [^a]        # 非 a, 匹配失败的话, 不扩展
* {1,2,3}     # [1,3] 匹配失败, 也会扩展
* {,1}        # 空 或 1, 匹配失败, 也会扩展
* {1..10}     # 匹配失败, 也会扩展
* {01..10}    # 匹配失败, 也会扩展(保证两位数)
* {1..10..3}  # 匹配失败, 也会扩展
```

## 常用快捷键
```
Ctrl+A      # 将光标移到行首
Ctrl+B      # 将光标向左移动一个字符
Ctrl+C      # 向前台进程组发送 SIGINT, 默认终止进程
Ctrl+D      # 删除光标前的字符 或 产生 EOF 或 退出终端
Ctrl+E      # 将光标移到行尾
Ctrl+F      # 将光标向右移动一个字符
Ctrl+G      # 响铃
Ctrl+H      # 删除光标前的一个字符
Ctrl+I      # 相当于TAB
Ctrl+J      # 相当于回车
Ctrl+K      # 删除光标处到行尾的字符
Ctrl+L      # 清屏
Ctrl+M      # 相当于回车
Ctrl+N      # 查看历史命令中的下一条命令
Ctrl+O      # 类似回车，但是会显示下一行历史
Ctrl+P      # 查看历史命令中的上一条命令
Ctrl+Q      # 解锁终端
Ctrl+R      # 历史命令反向搜索, 使用 Ctrl+G 退出搜索
Ctrl+S      # 锁定终端 -- TODO 历史命令正向搜索, 使用 Ctrl+G 退出搜索
Ctrl+T      # 交换前后两个字符
Ctrl+U      # 删除光标处到行首的字符
Ctrl+V      # 输入控制字符
Ctrl+W      # 删除光标左边的一个单词
Ctrl+X      #   TODO-列出可能的补全 ?
Ctrl+Y      # 粘贴被删除的字符
Ctrl+Z      # 前台运行的程序 --> 后台暂停
Ctrl+/      # 撤销之前的操作
Ctrl+\      # 产生 SIGQUIT, 默认杀死进程, 并生成 core 文件
Ctrl+xx     # 光标和行首来回切换

Esc+B              # 移动到当前单词的开头(左边)
Esc+F              # 移动到当前单词的结尾(右边)
Esc+.              # 获取上一条命令的最后的部分

Alt+B              # 向后（左边）移动一个单词
Alt+C              # 光标处字符转为大写
Alt+D              # 删除光标后（右边）一个单词
Alt+F              # 向前（右边）移动一个单词
Alt+L              # 光标处到行尾转为小写
Alt+R              # 取消变更
Alt+T              # 交换光标两侧的单词
Alt+U              # 光标处到行尾转为大写
Alt+BACKSPACE      # 删除光标前面一个单词，类似 Ctrl+W，但不影响剪贴板
Alt+.              # 使用上条命令的最后一个单词

Ctrl+X Ctrl+X      # 连续按两次 Ctrl+X，光标在当前位置和行首来回跳转
Ctrl+X Ctrl+E      # 用你指定的编辑器，编辑当前命令
Ctrl+insert        # 复制命令行内容
shift+insert       # 粘贴命令行内容
```

## 常用命令
```
!!    # 上一条命令
!l    # 执行最近使用的以 l 打头的命令
!l:p  # 输出最近使用的以 l 打头的命令
!num  # 执行历史命令列表的第 num 条命令
!$    # 上一条命令的最后一个参数
!*    # 上一条命令的所有参数
^1^2  # 将前一条命令中的 1 变成 2

\command # 忽略别名

basename $(readlink -f $0) # 获取脚本的名称
dirname  $(readlink -f $0) # 获取脚本的目录

bash file-name # 执行文件内的命令
bash -c "ls"   # 将字符串的内容交由 bash 执行, 字符串里可包含重定向和管道

bc <<< "scale=2; 10/2" # 使用两位小数, 输出: 5.00
bc <<< "ibase=2;  100" # 输入使用二进制, 输出: 4
bc <<< "obase=2;   10" # 输出使用二进制, 输出: 1010

bg %jobspec # 后台暂停 --> 后台运行, 有无 % 都成
fg %jobspec # 后台     --> 前台运行, 有无 % 都成

c++filt  a.out    # 可以解析动态库里的符号


clang-format    main.cc                                  # 预览规范后的代码
clang-format -i main.cc                                  # 直接在原文件上规范代码
clang-format -style=Google main.cc                       # 显示指明代码规范，默认为 LLVM
clang-format --dump-config -style=Google > .clang-format # 将代码规范配置信息写入文件 .clang-format
clang-format -style=file main.cc                         # 使用自定义代码规范,
                                                         # 规范位于当前目录或任一父目录的文件
                                                         # 的 .clang-format 或 _clang-format 中，
                                                         # (如果未找到文件，使用默认代码规范)
# 参考资源:
# clang-format  -> https://clang.llvm.org/docs/ClangFormat.html
# clang-format  -> https://clang.llvm.org/docs/ClangFormatStyleOptions.html
# askubuntu     -> https://askubuntu.com/questions/730609/how-can-i-find-the-directory-to-clang-format
# stackoverflow -> https://stackoverflow.com/a/39781747/7671328

           # 定期执行命令
crontab -l # 查询任务表
crontab -e # 编辑任务表
           # 格式为: 分钟 小时 日 月 星期 执行的程序
           # *     : 每分钟执行
           # 1-3   : 1 到 3分钟内执行
           # */3   : 每 3 分钟执行一次
           # 1-10/3: 1-10 分钟内, 每 3 分钟执行
           # 1,3,5 : 1,3,5 分钟执行
           # crontab 不会自动执行 .bashrc, 如果需要, 需要在脚本中手动执行
crontab -r # 删除任务表

curl -I ... # 只打印头部信息
                                      # 文件如果是符号链接, 将使用符号链接对应的文件
dd if=/dev/zero of=junk.data bs=1M count=1
dd if=/dev/zero bs=1M count=1000 | nc 127.0.0.1 9999 # 测速-客户端

df   -Th    # 文件系统挂载情况

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

dos2unix 1.txt # \r\n (windows) => \n (Linux/iOS)
unix2doc 1.txt # \n (Linux/iOS) => \r\n (windows)

du                      # 列出目录大小
du -0                   # 输出以 \0 分割, 默认是换行符
du -a                   # 列出目录和文件大小
du -d 1                 # 最大目录深度
du -sh                  # 只列出整体使用大小
du --exclude="*.txt"    # 忽略指定文件, 支持通配符

echo -n "123"                # 不换行
echo -e "\e[1;33m lyb \e[0m" # 文本黄色 加粗
echo  $'123\''               # 单引号内存在单引号的情况
echo  $(cal)                 # 输出字符以空格区分
echo "$(cal)"                # 保留输出字符的分割符
echo ${!S*}                  # 列出所有包含 S 的变量

env          # 设置环境变量, 然后执行程序

exec &>> 1.log  # 脚本内重定向
exec ls         # 替换当前 shell, 执行后不再执行之后的命令
exec &>  1.txt  # 打开文件描述符, 然后继续执行之后的命令

flock    1.c ls # 设置文件互斥锁 执行命令, 设置锁失败, 等待
flock -n 1.c ls # 设置文件互斥锁 执行命令, 设置锁失败, 退出

[[ "$FLOCKER" != "$0" ]] && exec env FLOCKER="$0" flock -en "$0" "$0" "$@" || :
                # 脚本内使用, 保证脚本最多执行一次
                # 解释:
                #   1. 第一次进入脚本, 由于变量未设置, 会执行 exec
                #   2. 调用 exec, 使用 env 设置 变量名
                #   3. 执行 flock, 重新执行这个脚本, 执行完脚本后会退出, 不会执行之后的命令
                #        * 使用脚本名作为 文件锁, 脚本名使用绝对路径, 所以不会重复
                #   4. 第二次进入脚本, 由于变量已设置, 直接往下执行就可以了
                # 5. 在此期间, 如果, 有其他脚本进入, 文件锁获取失败, 就直接退出了

file 1.txt # 查看换行符等

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

firewall-cmd --list-ports                      # 查看所有打开的端口
firewall-cmd --list-services                   # 查看所有打开的服务
firewall-cmd --get-services                    # 查看所有的服务
firewall-cmd --reload                          # 重新加载配置
firewall-cmd --complete-reload                 # 重启服务
firewall-cmd             --add-service=http    # 添加服务
firewall-cmd --permanent --add-service=http    # 添加服务, 永久生效, 需要重新加载配置
firewall-cmd             --remove-service=http # 移除服务
firewall-cmd             --add-port=80/tcp     # 添加端口
firewall-cmd --permanent --add-port=80/tcp     # 添加端口, 永久生效, 需要重新加载配置
firewall-cmd             --remove-port=80/tcp  # 移除端口
firewall-cmd             --query-masquerade    # 检查是否允许伪装IP
firewall-cmd               --add-masquerade    # 允许防火墙伪装IP
firewall-cmd --permanent   --add-masquerade    # 允许防火墙伪装IP, 永久生效, 需要重新加载配置
firewall-cmd            --remove-masquerade    # 禁止防火墙伪装IP
firewall-cmd --add-forward-port=proto=80:proto=tcp:toaddr=192.168.0.1:toport=8080
                                               # 端口转发, 0.0.0.0:80 --> 192.168.0.1:8080
firewall-cmd --add-forward-port=proto=80:proto=tcp:toaddr=192.168.0.1:toport=8080 --permanent
                                               # 端口转发, 永久生效, 需要重新加载配置
firewall-cmd --runtime-to-permanent            # 将当前防火墙的规则永久保存

free -h     # 内存使用情况

g++ -0g main.cc
g++ -01 main.cc
g++ -02 main.cc
g++ -03 main.cc
g++ -g  main.cc   # 生成 gdb 的文件

gdb [a.out] [pid]            # 启动 gdb               -- 常用
gdb> file a.out              # 设置可执行文件         -- 常用
gdb> set args	             # 设置程序启动命令行参数 -- 常用
gdb> show args	             # 查看设置的命令行参数
gdb> run [arguments]         # 运行程序(r)            -- 常用
gdb> attach pid              # gdb 正在运行的程序     -- 常用
gdb> info breakpoints        # 列出断点信息(i)        -- 常用
gdb> break file:line         # 在指定行设置断点(b)    -- 常用
gdb> break function          # 在制定函数设置断点(b)
gdb> break function if b==0  # 根据条件设置断点(b)
gdb> tbreak file:line        # 在指定行设置临时断点(tb)
gdb> disable breakpoints num # 禁用断点 num          -- 常用
gdb>  enable breakpoints num # 启用断点 num          -- 常用
gdb>  delete breakpoints num # 删除断点 num
gdb> clear   line            # 清除指定行的断点
gdb> continue [num]          # 继续运行到指定断点(c) -- 常用
gdb> until     line          # 运行到指定行(u)       -- 常用
gdb> jump      line          # 跳转到指定行(j), 和 until 的区别是跳过的代码不会执行
gdb> next     [num]          # 继续运行多次(n)       -- 常用
gdb> step                    # 进入函数(s)           -- 常用
gdb> finish                  # 退出函数(fin), 会执行完当前函数 -- 常用
gdb> return ...              # 退出函数, 并指定返回值, 和 finish 的区别是不会继续执行之后的代码, 直接返回
gdb> print v                 # 输出变量的值(p)       -- 常用
gdb> print v=123             # 修改变量的值(p)
gdb> p *pointer              # 输出指针指向的值
gdb> p arr[1]@3              # 输出数组 arr[1] 开始的3个元素
gdb> p/t var                 # 按  二进制格式显示变量
gdb> p/o var                 # 按  八进制格式显示变量
gdb> p/d var                 # 按  十进制格式显示变量
gdb> p/u var                 # 按  十进制格式显示无符号整型
gdb> p/x var                 # 按十六进制格式显示变量
gdb> p/a var                 # 按十六进制格式显示地址
gdb> p/c var                 # 按字符格式显示变量
gdb> p/f var                 # 按浮点数格式显示变量
gdb> p/s var                 # 字符串
gdb>         display v       # 和 p 类似, 但后续会自动输出变量的值
gdb> disable display num     # 暂时取消输出
gdb>  enable display num     # 恢复输出
gdb>  delete display num     # 删除自动输出变量的值的编号
gdb>       undisplay num     # 删除自动输出变量的值的编号
gdb> info    display         # 列出自动打印变量的值
gdb> x/8xb &v                # 输出 double 的二进制表示 -- 常用
gdb> x/nfu  v                # n 表示打印多少个内存单元
                             # f 打印格式, x d u o t a c f(默认8位)
                             # u 内存单元, b=1 h=2 w=4 g=8
                             # x 和 p 的区别
                             #   * p 的参数是变量的值, x 的参数是变量的地址
                             #   * p 打印的单位长度即是变量的长度, x 可以指定单位长度
                             #   * x 可以打印连续的多个单位长度(这个可以方便看 double 的每一个字节的内容)
gdb> list                    # 显示当前行之后的源程序(l) -- 常用
gdb> list -                  # 显示当前行之前的源程序
gdb> list 2,10               # 显示 2 - 10 行的源程序
gdb>  set listsize 20        # 设置列出源码的行数
gdb> show listsize           # 输出列出源码的行数
gdb> set  print elements 0   # 设置打印变量长度不受限制 -- 常用
gdb> show print elements
gdb> backtrace               # 显示堆栈信息(bt)        -- 常用
gdb> frame     n             # 查看指定层的堆栈信息(f) -- 常用
gdb> thread	                 # 切换到指定线程
gdb> watch	                 # 监视某一个变量的值是否发生变化
gdb> ptype	                 # 查看变量类型

getconf NAME_MAX / # 获取变量的值
getconf PATH_MAX /

getopts # 处理参数, -- 表示可选参数的终止

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
grep -P ..                # 使用 perl 风格的正则表达式
grep -W ..                # 单词匹配
grep -X ..                # 行匹配
grep ... --inclue "*.c"   # 指定文件
grep ... --exclue "*.c"   # 忽略文件
grep ... --exclue-dir src # 忽略目录

history

iconv -f gbk -t utf-8 1.txt -o 1.txt

id        # 输出实际或有效的用户和组信息

ifconfig -- 已过时, 被 ip addr  替代

ip a                                 # 显示网卡信息
ip addr    show                      # 显示指定网卡信息
ip address show dev   lo             # 显示指定网卡信息
ip address add 192.268.1.10 dev eth0 # 添加 IP 地址
ip address del 192.268.1.10 dev eth0 # 删除 IP 地址

ip link set dev eth0 multicast on  # 启用组播
ip link set dev eth0 multicast off # 禁用组播
ip link set dev eth0 up            # 启用网卡
ip link set dev eth0 down          # 禁用网卡
ip link set dev eth0 arp       on  # 启用 arp 解析
ip link set dev eth0 arp       off # 禁用 arp 解析
ip link set dev eth0 mtu      1500 # 设置最大传输单元
ip link set dev eth0 address  ...  # 设置 MAC 地址

ip route       # 路由信息
ip route show  # 路由信息
ip route get   # 查看指定 IP 的路由信息
ip route add   # 添加路由
ip route chage # 修改路由
ip route flush # 清空路由信息

ip neighbour  # 查看 arp 协议

ip -s link         # 查看统计信息
ip -s link ls eth0 # 查看统计信息, 指定网卡

ip maddr  # 广播
ip rule   # 路由策略, 和网卡有关
ip tunnel # 隧道

                              # 使用 iperf 测试的时候需要关掉防火墙: sudo systemctl stop firewalld
iperf -s                      # 服务器(TCP), 端口号为 5001
iperf -s -p 8080              # 服务器(TCP), 端口号为 8080
iperf -s -f MB                # 服务器(TCP), 端口号为 5001, 设置输出的单位
iperf -s -i 10                # 服务器(TCP), 端口号为 5001, 设置报告的时间间隔为 10s
iperf -s -D                   # 服务器(TCP), 端口号为 5001, 服务器在后台启动
iperf -s -1                   # 服务器(TCP), 端口号为 5001, 只接受一个客户端
iperf -s -N                   # 服务器(TCP), 端口号为 5001, 使用 TCP nodelay 算法
iperf -s -u                   # 服务器(UDP), 端口号为 5001
iperf -c 127.0.0.1            # 客户端(TCP), 服务器端口号为 5001
iperf -c 127.0.0.1 -p 8080    # 客户端(TCP), 服务器端口号为 8080
iperf -c 127.0.0.1 -i 1       # 客户端(TCP), 服务器端口号为 5001, 设置报告的时间间隔为 1s
iperf -c 127.0.0.1 -t 10      # 客户端(TCP), 服务器端口号为 5001, 设置测试时间为 10s
iperf -c 127.0.0.1 -f MB      # 客户端(TCP), 服务器端口号为 5001, 设置输出的单位
iperf -c 127.0.0.1 -b 100M    # 客户端(TCP), 服务器端口号为 5001, 设置发送速率
iperf -c 127.0.0.1 -n 100M    # 客户端(TCP), 服务器端口号为 5001, 设置测试的数据的大小
iperf -c 127.0.0.1 -k 100M    # 客户端(TCP), 服务器端口号为 5001, 设置测试的数据包的数量
iperf -c 127.0.0.1 -R         # 客户端(TCP), 服务器端口号为 5001, 反向测试, 服务端连客户端
iperf -c 127.0.0.1         -d # 客户端(TCP), 客户端连服务端的同时, 服务端同时连客户端, 端口号为 5001
iperf -c 127.0.0.1 -L 9090 -d # 客户端(TCP), 客户端连服务端的同时, 服务端同时连客户端, 端口号为 9090
iperf -c 127.0.0.1         -r # 客户端(TCP), 客户端连服务端结束后, 服务端连回客户端,   端口号为 5001
iperf -c 127.0.0.1 -L 9090 -r # 客户端(TCP), 客户端连服务端结束后, 服务端连回客户端,   端口号为 9090
iperf -c 127.0.0.1 -P 30      # 客户端(TCP), 客户端线程数为 30
iperf -c 127.0.0.1 -u         # 客户端(UDP)

jobs          # 列出后台作业
jobs %jobspec # 作业号有无 % 都成
jobs -l       #   列出后台作业的 PID
jobs -p       # 只列出后台作业的 PID
jobs -n       # 只列出进程改变的作业
jobs -s       # 只列出停止的作业
jobs -r       # 只列出运行中的作业

kill         pid # 通过进程ID发送信号给进程或进程组
kill -signal pid # 指定信号，默认值为 SIGTERM
kill -l          # 列出所有信号

killall             # 通过进程名称发送信号给进程或进程组, 进程名称精确匹配
killall -l          # 列出所有信号
killall -o 2m a.out # 发给 2 分钟前启动的 a.out
killall -y 2m a.out # 发给 2 分钟内启动的 a.out
killall -w    a.out # 等待进程结束

pkill         ... # 杀死进程, 扩展的正则表达式，参数和 pgrep 类似 -- 常用
pkill -signal ... # 指定信号，默认值为 SIGTERM

less # 空格   : 下一页
     # ctrl+F : 下一页
     # b      : 上一页
     # ctrl+b : 上一页
     # 回车   : 下一行
     # =      : 当前行号
     # y      : 上一行

ls &> /dev/null # 重定向

                   # lsof -- sudo yum install lsof
lsof -iTCP         # 查看 TCP 信息
lsof -i :22        # 查看指定 端口号 的信息
lsof -i@1.2.3.4:22 # 查看是否连接到指定 IP 和 端口号上
lsof -p 1234       # 指定 进程号
lsof -d 0,1,2,3    # 指定 文件描述符
lsof -t            # 仅获取进程ID

md5sum 1.txt # MD5 检验

more    # 空格   : 下一页
        # ctrl+F : 下一页
        # b      : 上一页
        # ctrl+b : 上一页
        # 回车   : 下一行
        # =      : 当前行号

mv a b # a 是符号链接时, 将使用符号链接本身
       # b 是指向文件  的符号链接时， 相当于 移到 b 本身
       # b 是指向目录  的符号链接时， 相当于 移到 b 最终所指向的目录下
       # b 是指向不存在的符号链接时， 相当于 重命名

                                        # 注意, 有不同版本的 nc, 参数不一定相同
nc -l             8080                  # 服务端(tcp), 接收单个连接
nc -lk            8080                  # 服务端(tcp), 接收多个连接
nc -lv            8080                  # 服务端(tcp), 显示连接信息
nc -lu            8080                  # 服务端(udp)
nc      127.0.0.1 8080                  # 客户端(tcp)
nc -n   127.0.0.1 8080                  # 客户端(tcp), 不进行域名解析, 节省时间
nc -N   127.0.0.1 8080                  # 客户端(tcp), 收到 EOF 后, 退出(有的版本不需要此参数, 会自动退出)
nc -w 3 127.0.0.1 8080                  # 客户端(tcp), 设置超时时间
nc -vz  127.0.0.1 8080                  # 客户端(tcp), 不发送信息, 只显示连接信息(测试单个端口)
nc -vz  127.0.0.1 8080-8090             # 客户端(tcp), 不发送信息, 只显示连接信息(测试多个端口)
nc -u   127.0.0.1 8080                  # 客户端(udp)
nc -lk            8080 | pv > /dev/null # 测速-服务端, 注意重定向, 否则会受限于终端的写速率
nc      127.0.0.1 8080      < /dev/zero # 测试-客户端

netstat  -- 已过时, 被 ss       替代

nmap             127.0.0.1 # 主机发现 -> 端口扫描, 默认扫描 1000 个端口
nmap -p  80      127.0.0.1 # 主机发现 -> 端口扫描, 指定端口号
nmap -p  80-85   127.0.0.1 # 主机发现 -> 端口扫描, 指定端口号
nmap -p  80,8080 127.0.0.1 # 主机发现 -> 端口扫描, 指定端口号
nmap -Pn         127.0.0.1 # 跳过主机发现, 直接端口扫描
nmap -sn         127.0.0.1 # 主机发现

nohup sleep 1000 & # 脱离终端, 在后台运行, 忽略信号 SIGHUP

nslookup baidu.com # 查询 域名 对应 的 IP

ntpdate -s time-b.nist.gov          # 使用时间服务器更新时间

patch     1.txt diff.pathc  # 恢复文件
patch -p1 1.txt diff.pathc  # 恢复文件, 忽略 diff.pathc 的第一个路径

ping      www.bing.com # 使用 ICMP ping 主机
ping -c 3 www.bing.com # 使用 ICMP ping 主机, 设置测试的次数
ping -i 3 www.bing.com # 使用 ICMP ping 主机, 设置间隔的秒数
ping -w 3 www.bing.com # 使用 ICMP ping 主机, 设置耗时的上限
ping -f   www.bing.com # 使用 ICMP ping 主机, 高速率极限测试, 需要 root 权限

                             # 多个命令之间取或
ps -U RUID -G RGID           # 实际的用户和组
ps -u EUID -g EGID           # 有效的用户和组
ps -p PID                    # 进程ID, 多个进程可以重复使用 -p 或者参数以分号分割 -- 常用
ps -s SID                    # 会话ID
ps --ppid PPID               # 父进程ID
ps -t ...                    # 终端
ps -C vim                    # 进程名称, 全名称 或 前 15 位

ps -o ruid,ruser,rgid,rgroup # 实际的用户和组
ps -o euid,euser,egid,egroup # 有效的用户和组
ps -o suid,suser,sgid,sgroup # 保存的用户和组
ps -o fuid,fuser,fgid,fgroup # 文件的用户和组, 一般和有效的相同
ps -o supgid,supgrp          # 附属组ID
ps -o pid,ppid,pgid,sid      # 进程ID, 父进程ID, 进程组ID, 会话ID
ps -o ouid                   # 会话ID所属用户ID
ps -o tty                    # 终端
ps -o tpgid                  # 输出前台进程的ID
ps -o luid,lsession          # 终端登录的用户ID和会话ID
ps -o stat,state             # 进程状态
                             # R 正在运行
                             # S 正在休眠(可被打断)
                             # D 正在休眠(不可被打断)
                             # T 后台暂停的作业
                             # t debug 调试中
                             # Z 僵尸进程
ps -o pmem,rsz,vsz           # 内存百分比,内存,内存(含交换分区)
ps -o pcpu,c,bsdtime,cputime # cpu: 百分比,百分比整数,user+system,system
ps -o lstart,etime,etimes    # 启动时间,运行时间,运行时间(秒), 无法对 etimes 进行排序
ps -o nice,pri,psr,rtprio    # 优先级
ps -o wchan                  # 进程休眠, 返回当前使用的内核函数
                             # 进程运行, 返回 -
                             # 列出线程, 返回 *
ps -o cmd                    # 启动命令
ps -o comm                   # 进程名称
ps -o fname                  # 进程名称的前 8 位

ps -e           # 所有进程
ps -H           # 输出进程树
ps -ww          # 不限制输出宽度
ps --no-headers # 不输出列头部
ps --headers    #   输出列头部
ps --sort -pcpu # cpu 使用率逆序

ps -o lwp,nlwp # 线程ID, 线程数
ps -L          # 列每一个线程

pstree     [PID] # 以进程 PID 为根画进程树, 默认为 1
pstree  -c [PID] # 展示所有子树
pstree  -p [PID] # 展示进程ID
pstree  -g [PID] # 展示进程组ID
pstree  -n [PID] # 使用 PID 排序而不是 进程名称
pstree  -l [PID] # 使用长行, 方便写入文件

              # 多个命令之间取且
pgrep         # 使用进程名称查找, 使用扩展的正则表达式
pgrep -f  ... # 使用启动命令匹配, 默认使用进程名称匹配(最多15位)
pgrep -c  ... # 输出匹配到的进程数目           -- 常用
pgrep -d，... # 设置输出的分割符，默认是换行符 -- 常用
pgrep -i  ... # 忽略大小写
pgrep -l  ... # 列出进程名称(最多15位)         -- 常用
pgrep -a  ... # 列出启动命令                   -- 常用
pgrep -n  ... # 仅列出最新的进程
pgrep -o  ... # 仅列出最旧的进程
pgrep -g  ... # 指定进程组ID
pgrep -G  ... # 指定实际组ID
pgrep -P  ... # 指定父进程ID
pgrep -s  ... # 指定会话ID
pgrep -t  ... # 指定终端
pgrep -u  ... # 指定有效用户ID
pgrep -U  ... # 指定实际用户ID
pgrep -v  ... # 反转结果
pgrep -x  ... # 精确匹配，默认不需要完全匹配
pgrep -w  ... # 列出线程ID

pidof    # 进程名称 => PID, 精确匹配, 没有长度限制
pwdx pid # 列出进程的当前工作目录

read name     # 读取, 如果参数值小于字段数, 多余的值放入最后一个字段

readlink    1.c.link  # 读取符号链接
readlink -f 1.c.link  # 读取符号链接, 递归

redis flushdb # 清空数据
redis -c ...  # 集群时需要使用 -c 启动, 否则查不到数据

route    -- 已过时, 被 ip route 替代

rz          #  windows 向 虚拟机  发送数据

sed    "p"                 1.txt #   正常使用
sed -e "p"                 1.txt #   使用 -e 添加脚本, -e 支持多次使用
sed -n "p"                 1.txt #   不输出模式空间的内容
sed -i "p"                 1.txt #   直接在原文件上修改
sed -r "p"                 1.txt #   使用扩展的正则表达式，默认使用基础的正则表达式 -- 推荐使用
sed -z "p"                 1.txt #   输入行以 \0 区分, 而不是 \n
sed -f 1.sed               1.txt #   从文件中读取脚本
sed -n "p"                 1.txt #   输出整个文件
sed -n "2p"                1.txt #   输出第二行
sed -n "2!p"               1.txt # 不输出第二行
sed -n "2,5p"              1.txt #   输出 [2,5] 行
sed -n "2,+4p"             1.txt #   输出 [2,6] 行
sed -n "$p"                1.txt #   输出最后一行
sed -n "/11/p"             1.txt #   输出匹配到 111 的行, 支持正则
sed -n "\c11cp"            1.txt #   输出匹配到 11 的行, c 可以使用任意字符, 便于处理包含 / 的情况
sed -n "/111/,/222/p"      1.txt #   输出匹配到 111 的行, 到匹配到 222 的行(包含)
                                 #       222 未匹配到时表示文件末尾
                                 #       开始匹配使用正则表达式时, 不能匹配同一行
sed -n "/111/,+4p          1.txt #   输出匹配到 111 的行以及接下来四行, 共五行
sed -n "0,/111/p"          1.txt #   输出文件开头到匹配到 111 的行
                                 #       如果 /111/ 可以匹配第一行，将输出第一行
sed -n "1,/111/p"          1.txt #   输出第一行到匹配到 111 的行
                                 #       /111/ 不会匹配第一行
sed -n ": ..."             1.txt # 定义标签
sed -n "="                 1.txt # 输出行号
sed -n "a ..."             1.txt # 行后插入
sed -n "b ..."             1.txt # 跳到标签处，如果标签未指定时，跳到脚本末尾
sed -n "c ..."             1.txt # 取代所选择的行
sed -n "d"                 1.txt # 删除模式空间的内容, 并进入下一循环
sed -n "D"                 1.txt # 删除模式空间的第一行内容
                                 #     如果模式空间变为空，开始下一循环
                                 #     否则，跳到脚本开始处继续
sed -n "g"                 1.txt # 将保持空间复制到模式空间
sed -n "G"                 1.txt # 将保持空间附加到模式空间
sed -n "h"                 1.txt # 将模式空间复制到保持空间
sed -n "H"                 1.txt # 将模式空间附加到保持空间
sed -n "i ..."             1.txt # 行前插入
sed -n "l"                 1.txt # 列出当前行，标明不可见字符
sed -n "n"                 1.txt # 读取下一行到模式空间
sed -n "N"                 1.txt # 将下一行添加到模式空间内容后
sed -n "p"                 1.txt # 打印模式空间的内容
sed -n "P"                 1.txt # 打印模式空间的第一行内容
sed -n "2q"                1.txt # 输出第一行，第二行后退出
sed -n "2Q"                1.txt # 输出第一行后退出
sed -n "r..."              1.txt # 每一行后添加文件的内容
                                 #     貌似无法在文件开头添加另一文件的内容
sed    "R2.txt"            1.txt # 第一行后插入 2.txt 的第一行
                                 # 第二行后插入 2.txt 的第二行, 如果 2.txt 已读完，则不插入
sed    "s/123/456/"        1.txt # 替换第一处
sed    "s/123/456/2"       1.txt # 替换第二处
sed    "s/123/456/2g"      1.txt # 替换第二处及以后
sed    "s/123/456/g"       1.txt # 替换所有
sed -n "s/123/456/gp"      1.txt # 打印替换后的结果
sed -n "s/123/456/gw2.txt" 1.txt # 替换后的结果写入文件 2.txt
sed    "s|123|456|"        1.txt # 使用不同的分割符
sed    "s/.*/[&]/"         1.txt # & 用于表示所匹配到的内容
sed    "s/\(1\)/[\1]/"     1.txt # \1 表示第一个字串
sed -r "s/(1)/[\1]/"       1.txt # \1 表示第一个字串
sed    "s/1/a \t b/"       1.txt # 可以包含 \n \t
sed -n "t abc              1.txt # 前一个 s 命令成功会跳转到指定标签   -- 这个一般用不上
sed -n "T abc              1.txt # 前一个 s 命令未成功会跳转到指定标签 -- 这个一般用不上
sed -n "w ..."             1.txt # 写模式空间的内容到文件
sed -n "W ..."             1.txt # 写模式空间的第一行的内容到文件
sed -n "x"                 1.txt # 交换模式空间和保持空间的内容
sed -n "y/123/456/"        1.txt
sed -n "y/1-3/456/"        1.txt
sed -n "y/123/4-6/"        1.txt
sed -n "y/1-3/4-6/"        1.txt
                                 # 测试 301-03.sh

set -o nounset  # 使用未初始化的变量报错, 同 -u
set -o errexit  # 只要发生错误就退出, 同 -e
set -o pipefail # 只要管道发生错误就退出
set -o errtrace # 函数报错时, 也处理 trap ERR, 同 set -E
set -o  xtrace  # 执行前打印命令, 同 -x
set -o verbose  # 读取前打印命令, 同 -v
set -o vi       # 使用 vi 快捷键
set -- ....     # 重新排列参数
                # 建议使用: set -ueo pipefail

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

ss       # 显示已连接的 UDP, TCP, unix domain sockets
ss -x    # unix domain sockets
ss -u    #          UDP
ss -t    # 已连接的 TCP
ss -tl   #   监听的 TCP
ss -ta   # 已连接和监听的 TCP
ss -tln  # 服务使用数字而不是名称
ss -tlnp # 列出监听的进程号, 需要root 权限
ss -s    # 显示统计
ss src   192.168.198.128:22  # 通过源  IP和端口号筛选信息
ss dst   192.168.198.1:51932 # 通过目的IP和端口号筛选信息
ss sport OP 22               # 通过源  端口号过滤数据
ss dport OP 22               # 通过目的端口号过滤数据
                             # OP 可以是空, >(gt) >=(ge) <(lt) <=(le) ==(eq) !=(ne), 注意转义

### 密钥登录
主目录权限不能是 777

### 常用命令
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

strace               # 追踪进程的系统调用和信号处理
strace cmd argv      # strace 和命令 同时启动
strace -p pid        # 追踪正在运行的程序, 多个进程, 指定 -p 多次
strace -c            # 统计系统调用的时间, 次数
strace -o ...        # 输出到指定的文件
strace -tt           # 显示调用时间 时分秒.毫秒
strace -T            # 显示系统调用的耗时
strace -f            # 跟踪子进程, 不包括 vfork
strace -F            # 跟踪 vfork
strace -e trace=...  # 跟踪指定信号调用
strace -s ...        # 参数是字符串时, 最大输出长度, 默认是32个字节
strace -e signal=... # 跟踪指定信号

su        # 切到 root
su -      # 切到 root, 更新主目录, 环境变量等, 相当于重新登录
su   lyb  # 切到 lyb

sudo                                          # 权限管理文件: /etc/sudoers, 使用 visudo 编辑
sudo -u USERNAME COMMAND                      # 指定用户执行命令
sudo -S date -s "20210722 10:10:10" <<< "123" # 脚本中免密码使用

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

tac               # 最后一行 => 第一行

tail -f * # 动态查看新增内容

tcpdump 可选项 协议(tcp udp icmp ip arp) 源(src dst) 类型(host net port portrange) 值
* [S]: SYN(发起连接), [P]: push(发送), [F]:fin(结束), [R]: RST(重置), [.](确认或其他)
* ack 表示下一个要接收的 seq 号
* length 有效数据的长度
* win 接收窗口的大小
* 为避免shell干扰, 可将内容用引号包含
* and  or 可以组合多个条件

tcpdump -D                      # 列出可以 tcpdump 的网络接口
tcpdump -i eth0                 # 捕捉某一网络接口
tcpdump -i any                  # 捕捉所有网络接口
tcpdump -i any -c 20            # 捕捉所有网络接口, 限制包的数量
tcpdump -i any -n               # 捕捉所有网络接口, 使用IP和端口号, 而不是域名和服务名称
tcpdump -i any -w ...           # 捕捉所有网络接口, 将数据保存在文件中
tcpdump -i any -r ...           # 捕捉所有网络接口, 从文件中读取数据
tcpdump -i any -A               # 捕捉所有网络接口, 打印报文 ASCII
tcpdump -i any -x               # 捕捉所有网络接口, 打印包的头部, -xx -X -XX 类似
tcpdump -i any -e               # 捕捉所有网络接口, 输出包含数据链路层信息
tcpdump -i any -l               # 捕捉所有网络接口, 使用行缓存, 可用于管道
tcpdump -i any -N               # 捕捉所有网络接口, 不打印域名
tcpdump -i any -Q in            # 捕捉所有网络接口, 指定数据包的方向 in, out, inout
tcpdump -i any -q               # 捕捉所有网络接口, 简洁输出
tcpdump -i any -s ...           # 捕捉所有网络接口, 设置读取的报文长度,0 无限制
tcpdump -i any -S ...           # 捕捉所有网络接口, 使用绝对 seq
tcpdump -i any -v               # 捕捉所有网络接口, 显示详细信息, -vv -vvv 更详细
tcpdump -i any -t               # 捕捉所有网络接口, 不打印时间
tcpdump -i any -tt              # 捕捉所有网络接口, 发送(绝对时间), 确认(绝对时间)(时间戳)
tcpdump -i any -ttt             # 捕捉所有网络接口, 发送(相对时间), 确认(相对间隔)(时分秒 毫秒)
tcpdump -i any -tttt            # 捕捉所有网络接口, 发送(绝对时间), 确认(绝对时间)(年月日-时分秒)
tcpdump -i any -ttttt           # 捕捉所有网络接口, 发送(相对时间), 确认(相对时间)(时分秒 毫秒)
tcpdump -l                      # 使用行缓存, 可用于管道
tcpdump src  host 192.168.1.100 # 指定源地址 可以使用 /8 表明网络
tcpdump dst  host 192.168.1.100 # 指定目的地址
tcpdump      host 192.168.1.100 # 指定主机地址
tcpdump       net 192.168.1     # 指定网络地址, 也可以使用 /8 表示
tcpdump src  port 22            # 指定源端口号
tcpdump dst  port 22            # 指定目的端口号
tcpdump      port 22            # 指定端口号, 可使用服务名称
tcpdump not  port 22            # 排除端口号
tcpdump tcp                     # 指定协议
tcpdump "tcp[tcpflags] == tcp-syn" # 基于tcp的flag过滤
tcpdump less 32                 # 基于包大小过滤
tcpdump greater 64              # 基于包大小过滤
tcpdump ether   host  ...          # 基于 MAC 过滤
tcpdump gateway host ...          # 基于网关过滤
tcpdump ether broadcast      # 基于广播过滤
tcpdump ether multicast      # 基于多播过滤
tcpdump ip broadcast         # 基于广播过滤
tcpdump ip multicast         # 基于多播过滤

tee    1.txt # 管道中把文件拷贝到文件
tee -a 1.txt # 管道中把文件添加到文件

top     # 第一行 系统时间 运行时间 用户数 平均负载
        # 第二行 进程总结
        # 第三行 CPU 总结
        # 第四行 物理内存总结
        # 第五行 虚拟内存总结
        # 交互命令
        #   空格 或 回车 刷新
        #   l 切换负载的显示
        #   t 切换任务的显示
        #   m 切换内存的显示
        #   f 选择展示的字段
        #   R 反向排序
        #   c 显示命令名称 或 完整命令行
        #   i 显示空闲任务
        #   u 显示特定用户的进程
        #   k 结束任务
        #   h 帮助
        #   L 搜索字符串
        #   H 显示线程
        #   0 不显示统计值为 0 的项
        #   1   显示所有的cpu信息
        #   < 排序字段左移
        #   > 排序字段右移
        #   M 内存排序
        #   P CPU 排序
        #   T 时间排序
top -n 1   # 刷新次数
top -b     # 方便写入文件
top -c     # 显示完整命令行
top -p ... # 指定 PID
top -u lyb # 指定用户

tr    'a-z' 'A-Z' # 小写转大写
tr -d 'a-z'       # 删除字符
tr -s ' '         # 压缩字符

traceroute: 查看数据包经过的路径

trap ... ERR  # 发生错误退出时, 执行指定命令
trap ... EXIT # 任意情况退出时, 执行指定命令

tree -p "*.cc"       # 只显示  匹配到的文件
tree -I "*.cc"       # 只显示没匹配到的文件
tree -H . -o 1.html  # 指定目录生成 html 文件

ulimit              # 限制资源使用, 包括:
                    #   内存, 虚拟内存, CPU
                    #   进程数, 线程数
                    #   文件锁数, 文件描述符数, 写入文件大小
                    #   待处理的信号数
                    #   core 文件大小
                    # 也可指定是硬限制还是软限制
ulimit -a           # 列出资源的限制
ulimit -c unlimited # 允许 core 文件

uname -a # 全部信息
uname -m # x86_64 等
uname -r # 内核版本

uniq    # 删除重复的行
uniq -c # 输出统计的次数
uniq -d # 只输出重复的行, 重复的项只输出一次
uniq -D # 只输出重复的行, 重复的项输出多次
uniq -i # 忽略大小写
uniq -u # 只输出没重复的行

uptime -s # 列出系统启动时间

cat lyb | xargs -i vim {} # 以此编辑 lyb 中的每一个文件

wc    # 输出 换行符数 字符串数 字节数
wc -l #   行数
wc -w # 字符串数
wc -c # 字节数
wc -m # 字符数

## 建议
* 使用 pgrep 获取 PID, 使用 ps 列出详细信息
* 使用 etimes 可以方便计算出启动时间, 并格式化 年-月-日 时-分-秒 时区
* 一般使用进程的前 15 位即可
* 使用 pkill 发送信号
```

## 简介：
* ClangFormat 是一个规范代码的工具
* ClangFormat 支持的语言有：C/C++/Java/JavaScript/Objective-C/Protobuf/C#
* ClangFormat 支持的规范有：LLVM，Google，Chromium，Mozilla 和 WebKit

## 安装：
$ sudo yum install clang-format -y
$ sudo apt install clang-format -y

## 作为单独的命令使用
```
$ clang-format    main.cc                                  # 预览规范后的代码
$ clang-format -i main.cc                                  # 直接在原文件上规范代码
$ clang-format -style=Google main.cc                       # 显示指明代码规范，默认为 LLVM
$ clang-format --dump-config -style=Google > .clang-format # 将代码规范配置信息写入文件 .clang-format
$ clang-format -style=file main.cc                         # 使用自定义代码规范,
                                                           # 规范位于当前目录或任一父目录的文件
                                                           # 的 .clang-format 或 _clang-format 中，
                                                           #（如果未找到文件，使用默认代码规范）
```

## 在 Vim 中使用
1. 查找文件 clang-format.py 所在的目录

    $ dpkg -L clang-format | grep clang-format.py

2. 在 .vimrc 中加入以下内容

    function! Formatonsave()
        let l:formatdiff = 1
        py3f <path-to-this-file>/clang-format.py
    endfunction
    autocmd BufWritePre *.h,*.cc,*.cpp call Formatonsave()

### 说明：
```
1. 上述的内容表示：当使用 Vim 保存文件时，
     会按照当前目录 或 任一父目录的文件 .clang-format 或 _clang-format 指定的规范来规范代码
    （如果未找到文件，使用默认代码规范）
2. 上述 `<path-to-this-file>` 指的是 clang-format.py 的目录
3. `let l:formatdiff = 1` 的意思是只规范修改过的部分，可以用 `let l:lines = "all"` 取代，表示规范所有的内容
4. 在 Ubuntu 18.04 LTS 下，clang-format 的默认版本为 clang-format-6.0，
   clang-format-6.0 的 clang-format.py 使用的是 Python 3，
   而 Ubuntu 18.04 LTS 默认的 Python 版本为 Python 2.7，所以上面使用的是 py3f 而不是 pyf
```

## 参考资源
* clang-format  -> https://clang.llvm.org/docs/ClangFormat.html
* clang-format  -> https://clang.llvm.org/docs/ClangFormatStyleOptions.html
* askubuntu     -> https://askubuntu.com/questions/730609/how-can-i-find-the-directory-to-clang-format
* stackoverflow -> https://stackoverflow.com/a/39781747/7671328


## 模式类别
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


vim -c 'set binary noeol' -c 'wq!' 1.txt # 移除文件末尾的换行符
vim -c 'set eol'          -c 'wq!' 1.txt # 添加文件末尾的换行符

vim -c "...." 1.txt # vim 启动时执行命令
vim    "+..." 1.txt # vim 启动时执行命令

set number                            # 默认显示行号
set cindent                           # 使用 C 风格的自动缩进
set expandtab                         # 自动扩展 Tab
set tabstop=4                         # 设置 Tab 所占的宽度
set shiftwidth=4                      # 自动缩进使用的空格数量
set softtabstop=4                     # 调整 缩进的 表现, 开启 expandtab 的时候, 此选项没用
autocmd FileType make set noexpandtab # Makefile 不扩展 Tab

set nobomb                            #  去掉 bomb, 在 vimrc 中不生效
set   bomb                            #  添加 bomb

set     encoding=utf-8     # vim 内部使用的编码, 一般用不到
set fileencoding=utf-8     # 编辑文件时, 设置文档保存时的编码
                           # 文件无乱码时, 可以使用此选项转换编码规则
set fileencodings=ucs-bom,utf-8,gbk,big5,gb18030,latin1
                           # 探测文件编码格式的顺序
set termencoding=utf-8     # 和终端显示有关, 一般不需要修改

set nohlsearch # 去掉高亮

edit ++enc=utf-8 ... # 以 utf-8 重新打开文件

w! ++enc=utf8 # 使用 utf-8 重新加载该文件, 使用 utf-8 保存该文件

vim
Ctrl+F 下翻一屏
Ctrl+B 上翻一屏


## 简介
* Git 是一个分布式版本管理的工具
* 本文只列举 Git 最常用的功能
* Git 只是版本管理的工具, 未必需要做到, 知其然并知其所以然, 够用就好

## 基本说明
### 三个工作区域：
1. Git 仓库
2. 暂存区域
3. 工作目录

### 文件和目录的分类：
1. 未跟踪的（untracked），位于工作目录
2. 已暂存的（staged），属于暂存区域，位于 Git 仓库目录
3. 已提交的（committed），位于 Git 仓库目录
4. 已修改的（modified），位于工作目录
5. 已忽略的文件或目录，位于工作目录

### 忽略文件或目录
在文件 .gitignore 中添加要忽略的文件或目录，规则如下：
1. 空行或以 `#` 开头的行将被忽略
2. 以 `/` 开头防止递归
3. 以 `/` 结尾表示目录
4. 以 `!` 开头，表示不忽略文件或目录
5. `*` 匹配任意字符（不包括 `/`）
6. `**` 匹配任意字符
7. `[abc]` 表示匹配方括号内的任意单个字符
8. `[0-9]` 表示匹配范围 [0, 9] 内的任意单个个字符
9. `?` 匹配任意单个字符

## 本地配置基础环境连接 GitHub
```
$ sudo apt install git                                 # 安装 Git
$                                                      #
$ git config --global user.name  liuyunbin             # 配置用户名
$ git config --global user.email yunbinliu@outlook.com # 配置邮箱
$ git config --global core.editor vim                  # 配置默认编辑器
$ git config --global log.date iso                     # 配置日志使用 年月日 时分秒 时区 的格式
$
$ git config --global alias.lg "log --pretty=format:'%Cgreen%ad%Creset %h %s %C(yellow)%d%Creset %Cblue%an%Creset'"                                                 # 添加别名
$                                                      #
$ git config --list --global                           # 查看当前用户的配置信息
$                                                      #
$ ssh-keygen -t rsa                                    # 生成密钥
$                                                      # 复制公钥到 GitHub
$                                                      #     将文件 `~/.ssh/id_rsa.pub` 里的公钥添加到
$                                                      #     https://github.com/settings/keys
$                                                      # 到此可以免密码使用 GitHub
$ ssh -T git@github.com                                # 测试是否成功
```

## 常用命令
```
git add README # 未跟踪 --> 已暂存
git add README # 已修改 --> 已暂存
git add README # 合并时把有冲突的文件标记为已解决状态
git add -u     # 添加所有已修改的文件

git blame  main.cc        # 查看文件每行的最后变更

git branch                                 # 列出所有的本地分支
git branch -v                              # 列出所有的本地分支, 以及最后一次提交
git branch -vv                             # 列出所有的本地分支, 以及最后一次提交, 跟踪的远程分支
git branch --merged                        # 列出已合并到 本分支  的本地分支
git branch --merged     develop            # 列出已合并到 develop 的本地分支
git branch --no-merged                     # 列出未合并到 本分支  的本地分支
git branch --no-merged  develop            # 列出未合并到 develop 的本地分支
git branch              test-branch        # 新建分支, 并不会切换分支
git branch -d           test-branch        #       删除分支, 如果该分支还未合并到当前分支,   会报错
git branch -D           test-branch        #   强制删除分支, 如果该分支还未合并到当前分支, 不会报错
git branch -m            new-branch        # 重命名当前分支, 如果新分支名已存在,   会报错
git branch -M            new-branch        # 重命名当前分支, 如果新分支名已存在, 不会报错
git branch -m old-branch new-branch        # 重命名指定分支, 如果新分支名已存在,   会报错
git branch -M old-branch new-branch        # 重命名指定分支, 如果新分支名已存在, 不会报错
git branch -r                              # 查看远程分支
git branch --set-upstream-to=orgin/develop # 本地分支和远程分支关联
git branch -u orgin/develop                # 本地分支和远程分支关联

git checkout    -- README                       # 使用暂存区的 README 替换当前目录的 README
git checkout HEAD~ README                       # 使用 HEAD~ 的 README 替换当前目录和暂存区域 的 README
git checkout    test-branch                     #       切换分支
git checkout -b test-branch                     # 新建并切换分支
git checkout --orphan test-branch               # 新建并切换到独立分支
git checkout -b      serverfix origin/serverfix # 新建并关联到远程分支
git checkout --track           origin/serverfix # 新建并关联到远程分支
git checkout         serverfix                  # 本地分支不存在, 且 远程分支存在, 新建并关联到远程分支

git clone                      https://github.com/liuyunbin/note # 克隆仓库
git clone --recurse-submodules https://github.com...             # 克隆包含子模块的项目
git clone git@github.com:liuyunbin/note     # ssh 协议
git clone git@github.com:liuyunbin/note.git # TODO: 和上一个有什么区别

git commit -a -m "message"   # 已修改 --> 已暂存 --> 已提交
git commit    -m "message"   #            已暂存 --> 已提交
git commit --amend           # 将要修改的内容合并到最后一次提交中, 并修改提交信息, 旧的提交将删除
git commit --amend -m ...    # 将要修改的内容合并到最后一次提交中, 并修改提交信息, 旧的提交将删除
git commit --amend --no-edit # 同上, 但不需要修改提交信息

                                                     # --system  为整个系统中的项目配置
                                                     # --global  为某个用户下的项目配置
                                                     # --local   为单独的某个项目配置 -- 这个是默认行为
git config --global user.name  liuyunbin             # 配置用户名
git config --global user.email yunbinliu@outlook.com # 配置邮箱
git config --global core.editor vim                  # 配置默认编辑器
git config --global log.date iso                     # 日志使用 年月日 时分秒 时区 的格式
git config --global color.status      auto
git config --global color.diff        auto
git config --global color.branch      auto
git config --global color.interactive auto
git config --global --list                           # 检查配置信息
git config --global --list --show-origin             # 检查配置信息 以及 所属文件
git config --global               user.name          # 检查某一项配置
git config --global --show-origin user.name          # 检查某一项配置 及其 所属文件

git config --global core.eol     lf # 设置工作目录的换行符为   \n
git config --global core.eol   crlf # 设置工作目录的换行符为 \r\n
git config --global core.eol native # 设置工作目录的换行符为 native, 使用平台默认的换行符 == 默认值

git config --global core.autocrlf true  # 提交时: CRLF --> LF, 检出时: LF --> CRLF
git config --global core.autocrlf input # 提交时: CRLF --> LF, 检出时: 不转换
git config --global core.autocrlf false # 提交时: 不转换,      检出时: 不转换 == Linux 下的默认值

git config --global core.safecrlf true  # 拒绝提交包含混合换行符的文件
git config --global core.safecrlf false # 允许提交包含混合换行符的文件  == Linux 下的默认值
git config --global core.safecrlf warn  # 提交包含混合换行符的文件时给出警告

git config --global core.quotepath false # 引用路径不使用八进制, 中文名不再乱码

                     # 有参数比较 已修改 与 Git 仓库的区别吗? TODO
git diff             # 暂存区域 和 已修改   的差异
git diff --staged    # 暂存区域 和 Git 仓库 的差异
git diff --cached    # 暂存区域 和 Git 仓库 的差异
git diff --submodule # 获取子模块的修改

git fetch [remote-name] # 从远程仓库获取数据
git fetch -a            # 从所有远程仓库获取数据

git for-each-ref --format='%(committerdate:iso) %(refname) %(authorname)'
                        # 查看所有远程分支最后一次的提交
git init                    # 初始化仓库

git log
git log --stat              # 显示简略统计信息
git log --shortstat         # 只显示添加移除信息
git log  -p                 # 显示修改的内容
git log --patch
git log  -2                 # 显示近两次的提交
git log --oneline           # 每个提交一行, 相当于 --pretty=oneline --abbrev-commit
git log --pretty=oneline    # 每个提交一行
git log --pretty=short      # 只有作者, 没有日期
git log --pretty=full       # 显示作者和提交者
git log --pretty=fuller     # 显示作者 作者提交的日期和提交者 提交者提交的日期
git log --pretty=format:"." # 指定显示格式
git log --pretty=format:'%Cgreen%ad%Creset %h %s %C(yellow)%d%Creset %Cblue%an%Creset'
                            # %h 提交的简写哈希值
                            # %t 树的简写哈希值
                            # %p 父提交的简写哈希值
                            # %an 作者名字
                            # %ae 作者的邮箱
                            # %ad 作者修订日期
                            # %cn 提交者的名字
                            # %ce 提交者的邮箱
                            # %cd 提交日期
                            # %d  ref名称 -- 包括tag等
                            # %s 提交说明
                            # %Cred	切换到红色
                            # %Cgreen 切换到绿色
                            # %Cblue  切换到蓝色
                            # %Creset 重设颜色
git log --graph             # 显示分支的合并
git log --name-only         # 显示修改的文件清单
git log --name-status       # 显示修改的文件信息, 增删改
git log --abbrev-commit     # 只显示提交hash的前几个字符
git log --after=2021-07-16
git log --since=2021-07-16
git log --before=2021-07-16
git log --until=2021-07-16
git log --author=liuyunbin            # 指定作者
git log --committer=54c7cd09          # 指定提交者
git log --grep=liuyunbin              # 搜索提交说明中包含该关键字的提交
git log --grep=A --grep=B             # 搜索提交说明中包含 A 或 B 的提交
git log --grep=A --grep=B --all-match # 搜索提交说明中包含 A 且 B 的提交
git log --no-merges                  # 不显示提交合并
git log a..b                         # 不在 a 中, 在 b 中的提交
git log ^a b                         # 不在 a 中, 在 b 中的提交
git log --not a b                    # 不在 a 中, 在 b 中的提交
git log a...b                        # 在 a 或 b 中, 但不同时在 a 且 b 中的提交
git log -L :main:main.cpp            # 查询某一函数的变更记录
git log -L :10:main.cpp              # 查询某一行的变更记录
git log -L 8,10:main.cpp             # 查询某几行的变更记录
git log -S main                      # 搜索字符串的增加 删除
git log -- ...                       # 指定路径
git log --decorate                   # 查看 HEAD 分支 tag 所属的提交

git ls-remote (remote)    # 查看远程分支

git merge test-branch # 将 test-branch 合并到 当前分支

git mv file_from file_to # 移动文件或目录

git pull            # 从远程仓库获取数据, 然后合并
git pull --rebase   # 从远程仓库获取数据, 然后合并, 自动 rebase

git push origin master                          # 推送提交到远程仓库
git push origin A:B                             # 推送本地分支A到远程分支B
git push origin --delete serverfix              # 删除远程分支
git push origin --set-upstream-to=orgin/develop # 本地分支和远程分支关联
git push origin -u orgin/develop                # 本地分支和远程分支关联
git push origin v1.0                            # 将指定 标签 推送到远程
git push origin --tags                          # 将所有 标签 推送到远程
git push origin --delete v1.0                   # 删除远程 标签
git push orign feature/test -f                  # 强推本地分支
git push origin --delete feature/test           # 删除远程分支

git rebase master server-branch        # 将 server-branch 分支变基到 master
git rebase -i HEAD~6                   # 之后，使用 f 取消掉不需要的内容，合并提交
git rebase orign/develop               # 将 orign/develop 上的内容，变基到 当前分支
git rebase --onto master server client # 将在 server 上存在, 不在 client 上的内容变基到 master

git remote                          # 查看远程仓库
git remote -v                       # 查看远程仓库
git remote add <shortname> <url>    # 添加远程仓库
git remote rm     origin            # 删除远程仓库
git remote remove origin            # 删除远程仓库
git remote rename origin new-origin # 重命名远程仓库
git remote show   origin            # 查看远程仓库的详细信息
git remote prune  origin            # 删除本地仓库中的远程分支(远程仓库里已删除)

git reset --soft  HEAD~           # 将 HEAD 指到 HEAD~, 暂存区和工作目录不变
                                  # 有可能会丢失 HEAD~ 之后的数据
                                  # 已提交 => 已暂存
git reset         HEAD~           #
git reset --mixed HEAD~           # 将 HEAD 指到 HEAD~, 使用 HEAD 指向的数据重置暂存区, 工作目录保持不变
                                  # 有可能会丢失 HEAD~ 之后的数据, 以及已暂存的数据
                                  # 已提交 => 已修改
git reset --hard  HEAD~           # 将 HEAD 指到 HEAD~, 使用 HEAD 指向的数据重置暂存区和工作目录
                                  # 会丢失 HEAD~ 之后的数据, 以及已暂存, 已修改的数据
                                  # 已提交 => 已删除
git reset --soft  HEAD~ -- README # 非法
git reset         HEAD~ -- README # 使用 HEAD~ 的 README 替换 暂存区 的 README, Git 仓库 和 工作目录保持不变
                                  # 有可能会丢失已暂存的数据, 有取消暂存的效果
git reset               -- README # 和 git reset HEAD~ -- README 等价
git reset --mixed HEAD~ -- README # 同上一个, 但已过时
git reset --hard  HEAD~ -- README # 非法

git restore                     README # 使用 暂存区 的 README 覆盖 当前目录 中 的 README
                                       # 和 git checkout -- README 意思相同
git restore --staged            README # 使用 HEAD   的 README 覆盖 暂存区 的 README
                                       # 和 git reset -- README 意思相同
git restore --staged --worktree README # 使用 HEAD   的 README 覆盖 暂存区 和 当前目录 中的 README
                                       # 和 git checkout HEAD README 意思相同
git restore --staged --worktree --source HEAD~2 README
                                       # 使用 HEAD~2 的 README 覆盖 暂存区 和 当前目录 中的 README
                                       # 如果 指定提交 或 暂存区域不含 README, 则删除对应的 README
                                       # 和 git checkout HEAD~2 README 意思相同
git restore --source HEAD~2 README     # 使用 HEAD~2 的 README 覆盖当前目录 中的 README, 暂存区的内容保持不变

git revert -m 1 HEAD # 撤销提交

git rm          README # 从 暂存区域 和 本地目录 中移除文件, 如果该文件已修改 或 已暂存,   会失败
git rm  -f      README # 从 暂存区域 和 本地目录 中移除文件, 如果该文件已修改 或 已暂存, 也会成功
git rm --cached README # 从 暂存区域 中移除文件, 本地目录保留

git show HEAD   # 展示指定提交
git show HEAD^  # 展示指定提交的第一父提交
git show HEAD^^ # 展示指定提交的第一父提交的第一父提交
git show HEAD^2 # 展示指定提交的第二父提交, 用于 merge
git show HEAD~  # 展示指定提交的第一父提交
git show HEAD~~ # 展示指定提交的第一父提交的第一父提交
git show HEAD~2 # 展示指定提交的第一父提交的第一父提交

git stash                     # 贮藏工作
git stash --keep-index        # 贮藏工作, 同时将暂存的内容存在索引内
git stash --include-untracked # 贮藏工作, 同时贮藏未跟踪的文件, 不包括忽略的文件
git stash  -u                 # 贮藏工作, 同时贮藏未跟踪的文件, 不包括忽略的文件
git stash --all               # 贮藏工作, 同时贮藏未跟踪的文件,   包括忽略的文件
git stash  -a                 # 贮藏工作, 同时贮藏未跟踪的文件,   包括忽略的文件
git stash list                # 列出已贮藏的工作
git stash apply               # 恢复已贮藏的工作
git stash apply --index       # 恢复已贮藏的工作, 同时恢复暂存区
git stash drop                # 丢弃贮藏区的工作
git stash pop                 # 恢复已贮藏的工作, 并丢弃贮藏区的工作

git status         # 列出文件状态
git status  -s     # 显示简短信息
git status --short # 显示简短信息

git submodule add https://github.com...      # 添加子模块
git submodule init                           # 初始化本地子模块的配置
git submodule update                         # 获取子模块远程数据, 相对于当前仓库中子模块的提交号
git submodule update --init                  # 等价于前两个命令
git submodule update --init --recursive      # 递归获取子模块的远程数据
git submodule update --remote DbConnector    # 在主目录更新子模块, 远程子模块仓库的最新数据
git submodule update --remote --merge        # 合并远程修改到本地
git submodule update --remote --rebase       # 变基远程修改到本地

git switch    test-branch #       切换到 test-branch
git switch -c test-branch # 创建并切换到 test-branch

git tag                       # 列出 标签
git tag -l "v*"               # 列出 标签
git tag v1.0                  # 创建 标签
git tag v1.0  提交号          # 在某次提交上, 创建 标签
git tag -d v1.0               # 删除本地 标签
git tag --contains 提交号     # 查看某个提交号在哪些 tag 中出现
```

## 参考资源
1. https://help.github.com/en/articles/set-up-git
2. https://git-scm.com/book/zh/v2

## 官网
* https://nginx.org/

## 安装 nginx, centos7
* 安装: sudo yum install nginx
* 默认的网站目录：/usr/share/nginx/html
* 默认的配置文件：/etc/nginx/nginx.conf

## 常用命令
* nginx -s stop    退出 nginx
* nginx -s quit    工作进程处理完当前请求后, 退出 nginx
* nginx -s reload  重新加载配置,
* nginx -s reopen  重新打开日志文件

* systemctl start      nginx   启动 nginx
* systemctl stop       nginx   停止 nginx
* systemctl restart    nginx   重启 nginx
* systemctl status     nginx   查看 nginx 状态
* systemctl enable     nginx   开机自动启动 nginx
* systemctl disable    nginx   开机禁止启动 nginx
* systemctl is-active  nginx   查看 nginx 是否已启动
* systemctl is-enabled nginx   查看 nginx 是否开机启动
* systemctl list-unit-files    列出所有可用单元

* firewall-cmd --add-service=http     添加服务

## 常用配置
* root /usr 指定工作目录
* location, 位于 server, location 中,
    * 匹配顺序如下
        * location  =  /kds {} 精确匹配, 如果匹配, 立即停止匹配其他
        * location ^~  /kds {} 前缀匹配, 如果匹配, 立即停止匹配其他
        * location  ~  /kds {} 正则匹配,   区分大小写
        * location  ~* /kds {} 正则匹配, 不区分大小写, 这两个正则匹配优先级相同, 先匹配的先返回
        * location     /kds {} 普通前缀匹配, 匹配的越长, 优先级越高
    * location @405 {} 内部匹配
* rewrite regex replacement [flag];
    * 使用正则匹配
    * 如果 replacement 以 http 或 https 打头, 将直接被重定向
    * flag 的类型:
        * last  重新匹配新的 location
        * break 忽略后续的 rewrite, 并顺序执行
        * redirect  返回302临时重定向
        * permanent 返回301永久重定向
        * 空, 顺序执行
## 实战
## TDOD
alias
rewrite

expires

mirror

internal

limit_req
limit_conn
limit_rate

return

proxy_pass
proxy_connect_timeout 90;  #nginx跟后端服务器连接超时时间(代理连接超时)
proxy_send_timeout 90;     #后端服务器数据回传时间(代理发送超时)
proxy_read_timeout 90;     #连接成功后,后端服务器响应时间(代理接收超时)
proxy_buffer_size 4k;      #代理服务器（nginx）保存用户头信息的缓冲区大小
proxy_buffers 4 32k;      #proxy_buffers缓冲区
proxy_busy_buffers_size 64k;     #高负荷下缓冲大小（proxy_buffers*2）
proxy_temp_file_write_size 64k;  #设定缓存文件夹大小


proxy_set_header：在将客户端请求发送给后端服务器之前，更改来自客户端的请求头信息；
proxy_connect_timeout：配置 Nginx 与后端代理服务器尝试建立连接的超时时间；
proxy_read_timeout：配置 Nginx 向后端服务器组发出 read 请求后，等待相应的超时时间；
proxy_send_timeout：配置 Nginx 向后端服务器组发出 write 请求后，等待相应的超时时间；
proxy_redirect：用于修改后端服务器返回的响应头中的 Location 和 Refresh。

autoindex               on;    # 开启静态资源列目录
autoindex_exact_size    off;   # on(默认)显示文件的确切大小，单位是byte；off显示文件大概大小，单位KB、MB、GB
autoindex_localtime     off;   # off(默认)时显示的文件时间为GMT时间；on显示的文件时间为服务器时间

sendfile on ;
tcp_nopush on;
tcp_nodelay on;
keepalive_timeout 65 :
client_body_timeout 60s;
send_timeout 60s;

sendfile on ; : 开启高效文件传输模式，sendfile指令指定nginx是否调用sendfile函数来输出文件，减少用户空间到内核空间的上下文切换。对于普通应用设为 on，如果用来进行下载等应用磁盘IO重负载应用，可设置为off，以平衡磁盘与网络I/O处理速度，降低系统的负载。开启 tcp_nopush on; 和tcp_nodelay on; 防止网络阻塞。
keepalive_timeout 65 : : 长连接超时时间，单位是秒，这个参数很敏感，涉及浏览器的种类、后端服务器的超时设置、操作系统的设置，可以另外起一片文章了。长连接请求大量小文件的时候，可以减少重建连接的开销，但假如有大文件上传，65s内没上传完成会导致失败。如果设置时间过长，用户又多，长时间保持连接会占用大量资源。
client_body_timeout 60s; : 用于设置客户端请求主体读取超时时间，默认是60s。如果超过这个时间，客户端还没有发送任何数据，nginx将返回Request time out(408)错误。
send_timeout : : 用于指定响应客户端的超时时间。这个超时仅限于两个连接活动之间的时间，如果超过这个时间，客户端没有任何活动，Nginx将会关闭连接。

https://www.nginx.org.cn/article/detail/217

proxy_set_header Host $host;
proxy_set_header X-Forwarder-For $remote_addr;  #获取客户端真实IP

#### 情况一

配置:
    location  /proxy/ {
        proxy_pass http://1.2.3.4;
    }
请求: http://0.0.0.0/proxy/index.html
相当于访问:  http://1.2.3.4/proxy/index.html

结论: proxy_pass 的 IP 什么都不跟时, 使用绝对路径, 匹配到的 /proxy/ 也会用到

#### 情况二

配置:
    location  /proxy/ {
        proxy_pass http://1.2.3.4/;
    }
请求: http://0.0.0.0/proxy/index.html

相当于访问:  http://1.2.3.4/index.html

#### 情况三

配置:
    location  /proxy/ {
        proxy_pass http://1.2.3.4/kds/;
    }
请求: http://0.0.0.0/proxy/index.html
相当于访问:  http://1.2.3.4/kds/index.html

#### 情况四

配置:
    location  /proxy/ {
        proxy_pass http://1.2.3.4/kds;
    }
请求: http://0.0.0.0/proxy/index.html
相当于访问:  http://1.2.3.4/kdsindex.html

结论: proxy_pass 的 IP 还有内容时, 使用相对路径, 匹配到的 /proxy/ 会被丢弃

#### 情况五

配置:
    location  /proxy/ {
        proxy_pass http://1.2.3.4/kds/;
    }
请求: http://0.0.0.0/proxy/
请求: http://0.0.0.0/proxy
相当于访问:  http://1.2.3.4/kds/

结论:
当 location 中使用 proxy_pass, fastcgi_pass, uwsgi_pass, scgi_pass, memcached_pass, 或 grpc_pass 时,
如果请求的内容未添加末尾的 /, 且 匹配失败时, 如果 添加 末尾的 / 可以匹配成功的话, 将导致重定向, 最终返回添加 / 后的结果

见: https://nginx.org/en/docs/http/ngx_http_core_module.html#location

#### 情况六
www.bing.com 和 www.bing.com/ 意思相同

## 参考资源
* https://nginx.org/en/docs/ngx_core_module.html

## 安装
$ wget https://openresty.org/package/centos/openresty.repo # 获取 openresty 源的仓库
$ sudo mv openresty.repo /etc/yum.repos.d/                 # 将该源拷入系统目录
$ sudo yum check-update                                    # 更新软件源索引
$ sudo yum install -y openresty                            # 安装
$ sudo yum install -y openresty-resty                      # 安装命令行工具?

## 配置
$ # 默认路径前缀: /usr/local/openresty/nginx/
$ # 默认配置文件: /usr/local/openresty/nginx/conf/nginx.conf
$ # 默认命令文件: /usr/local/openresty/nginx/sbin/nginx
$ echo export PATH=$PATH:/usr/local/openresty/nginx/sbin >> ~/.bashrc # 将路径写入 .bashrc
$ source ~/.bashrc                                                    # 配置生效

## 开启防火墙
$ sudo firewall-cmd --add-service=http # 添加 http 服务

## 常用命令
$ nginx            # 启动
$ nginx -s stop    # 退出
$ nginx -s quit    # 工作进程处理完当前请求后, 退出
$ nginx -s reload  # 重新加载配置
$ nginx -s reopen  # 重新打开日志文件

## 常用配置
user  nobody;                   # 用户名

worker_processes 1;             # 工作进程数

error_log logs/error.log;       # 日志路径, 默认级别是 error
error_log logs/error.log error; # debug, info, notice, warn, error 等

pid logs/nginx.pid;             # 进程号的存储位置

worker_rlimit_nofile 65535;     # 每个进程打开的最多文件描述符数目

events {
    worker_connections  1024;   # 每个进程允许的最多连接数
}

http {
    include       mime.types;  # 文件扩展名与文件类型映射表
    default_type  application/octet-stream; # 默认文件类型

    log_format main  ...; # 日志格式话 名称 格式

    access_log  logs/access.log  main; # 访问日志 路径 格式
    access_log  off;                   # 取消访问日志

    sendfile        on;

    #keepalive_timeout  0;
    keepalive_timeout  65; # 设置超时时间
    keepalive_requests 120; #单连接请求上限次数?

    upstream myself {
        server 127.0.0.1:1234;
    }

    server {
        listen       80;
        server_name  localhost;

        #access_log  logs/host.access.log  main;

        location / {
            root   html;
            index  index.html index.htm;
        }

        #error_page  404              /404.html;

        error_page   500 502 503 504  /50x.html;
        location = /50x.html { # 重定向错误页面
            root   html;       # 根目录
        }

        location / {
            root   html;       # 根目录
            index index.html   # 默认界面
            deny  all;         # 禁止所有用户访问
            deny  1.2.3.4;     # 禁止 1.2.3.4 访问
            allow 1.2.3.5;     # 允许 1.2.3.5 访问
        }

        location ~ \.lua$ { # 将 lua 脚本转发到 myself
            proxy_pass   http://myself; # 转发地址
        }

        # pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000
        #
        #location ~ \.php$ {
        #    root           html;
        #    fastcgi_pass   127.0.0.1:9000;
        #    fastcgi_index  index.php;
        #    fastcgi_param  SCRIPT_FILENAME  /scripts$fastcgi_script_name;
        #    include        fastcgi_params;
        #}

        location ~ /\.cc {
        }
    }
}

## 常用变量
$remote_addr # 客户端 IP
$remote_port # 客户端 端口号
$remote_user # 客户端用户名称?

$server_addr     # 服务器 IP
$server_port     # 服务器 端口号
$server_name     # 服务器 名称
$server_protocol # 服务器 HTTP 协议版本

$http_cookie     # 客户端 cookie
$http_user_agent # 客户端浏览器信息
$http_referer    # 客户端从那个页面链接访问过来的

与 $http_x_forwarded_for 用以记录客户端的ip地址；

3.$time_local ： 用来记录访问时间与时区；
4.$request ： 用来记录请求的url与http协议；
5.$status ： 用来记录请求状态；成功是200；
6.$body_bytes_s ent ：记录发送给客户端文件主体内容大小；

$host   请求信息中的 Host，如果请求中没有 Host 行，则等于设置的服务器名，不包含端口
$request_method 客户端请求类型，如 GET、POST
$args   请求中的参数
$arg_PARAMETER  GET 请求中变量名 PARAMETER 参数的值，例如：$http_user_agent(Uaer-Agent 值), $http_referer...
$content_length 请求头中的 Content-length 字段
$scheme HTTP 方法（如http，https）

## 简介
* sed 是一个流编辑器
* 模式空间：默认使用，每次读取都会刷新
* 保持空间：默认包含一个换行符，可以使用其做一些复杂操作

## 基本流程
1. 读取一行, 存入模式空间
2. 对模式空间的内容执行脚本
3. 输出模式空间的内容
4. 如果还有下一行，调到第一步，否则，退出

## 常用参数
```
sed    script                   1.txt # 正常使用
                                      # 若 1.txt 为符号链接, 将操作读取符号链接所指的文件
sed -e script  -e script        1.txt # 使用 -e 添加脚本, -e 支持多次使用
sed -f 1.sed                    1.txt # 从文件中读取脚本
sed -n script                   1.txt # 不输出模式空间的内容
sed -i                   script 1.txt # 直接在原文件上修改
sed -iabc script                1.txt # 直接在原文件上修改, 并备份到 1.txtabc 中
sed -i --follow-symlinks script 1.txt # 若 1.txt 为符号链接, 修改符号链接所指向的文件
                                      # 默认将修改符号链接, 即修改后不再是符号链接了
sed -r script                   1.txt # 使用扩展的正则表达式，默认使用基础的正则表达式
sed -z script                   1.txt # 输入行以 \0 区分, 而不是 \n
```

## 脚本说明
* script 有无引号，单双引号都行
* script 有空格的时候必须有引号或转义
* script 有 $ 表示末尾的时候需要使用单引号或转义
* script 有 ! 表示  非的时候需要使用单引号或转义
* script 可以使用 {} 包成块, 方便嵌套
* script 可以使用多个命令，用分号分割
* script 里转义字符会被解析

## 操作的范围
```
无说明时表示整个文件

* 2p     # 输出第二行
* 2,0p   # 输出第二行 -- 一般用不上
* 2,1p   # 输出第二行 -- 一般用不上
* 2,2p   # 输出第二行 -- 一般用不上
* 2,3p   # 输出第二行,第三行
* 2,5p   # 输出第二行,第三行,第四行,第五行
* 2,+4p  # 输出第二行以及接下来四行, 共五行
* 0~2p   # 每两行打印第二行, 将打印第 2 4 6 ... 行 -- 一般用不上
* 1~2p   # 每两行打印第一行，将打印第 1 3 5 ... 行 -- 一般用不上
* 2~2p   # 每两行打印第二行, 将打印第 2 4 6 ... 行 -- 一般用不上
* 3~2p   # 每两行打印第三行，将打印第 3 5 7 ... 行 -- 一般用不上

* $p     # 输出最后一行
* $,0p   # 输出最后一行 -- 一般用不上
* $,1p   # 输出最后一行 -- 一般用不上
* 2,$p   # 输出第二行到文件末尾
* 2,100p # 输出第二行到文件末尾, 假设文件小于 100 行

* /111/       # 输出匹配到 111 的行, 支持正则表达式
* \c111c      # 输出匹配到 111 的行, c 可以使用任意字符
              # 主要方便处理 正则表达式 包含 / 的情况
* /111/,/222/ # 输出匹配到 111 的行, 到匹配到 222 的行(包含)
              # 222 未匹配到时表示文件末尾
              # 开始匹配使用正则表达式时, 不能匹配同一行
* /111/,+4p   # 输出匹配到 111 的行以及接下来四行, 共五行
* 0,/111/     # 输出文件开头到匹配到 111 的行
              # 如果 /111/ 可以匹配第一行，将只输出第一行
* 1,/111/     # 输出第一行到匹配到 111 的行
              # /111/ 不会匹配第一行

操作范围后加 ! 表示不输出
* 2!p   # 不输出第二行

addr,~np # 输出匹配到的行直到第 N 行，N 为 n 的整数倍 -- 很复杂, 感觉一般用不上
```

## 命令说明
```
* # ... 注释
* : ... 定义标签
* =     输出行号
* a ... 行后插入, 忽略后面的空字符, 第一个 \ 不具有转义的效果
    * 1a123      # 在第一行(即第二行)后插入123
    * 1a\123     # 在第一行(即第二行)后插入123
    * 1a    123  # 在第一行(即第二行)后插入123, 将忽略空格
    * 1a\   123  # 在第一行(即第二行)后插入"    123"
    * 1a   \123  # 在第一行(即第二行)后插入"   \123"
    * 1a   \t2\t # 在第一行(即第二行)后插入"   t123"
                 # 不会解释第一个转义 \t
                 #   会解释第二个转义 \t
* b ... 跳到标签处，如果标签未指定时，跳到脚本末尾
* c ... 取代所选择的行, 使用和行后插入(a)类似
* d 删除模式空间的内容, 并进入下一循环
* D 删除模式空间的第一行内容, 如果此时模式空间为空，开始下一循环，否则，跳到脚本开始处继续
* e
* f
* g 将保持空间复制到模式空间
* G 将保持空间附加到模式空间
* h 将模式空间复制到保持空间
* H 将模式空间附加到保持空间
* i ... 行前插入, 使用和行后插入(a)类似
* j
* k
* l 列出当前行，标明不可见字符
* m
* n 读取下一行到模式空间
* N 将下一行添加到模式空间内容后
* o
* p 打印模式空间的内容
* P 打印模式空间的第一行内容
* q 退出, sed "2q" 1.txt # 输出第一行，第二行后退出
* Q 退出, sed "2Q" 1.txt # 输出第一行后退出
* r 添加文件的内容, 貌似无法在文件开头添加另一文件的内容
    * sed "r2.txt" 1.txt # 每一行后插入 2.txt 的内容
* R 行后添加文件中的一行
    * sed "R2.txt" 1.txt # 第一行后插入 2.txt 的第一行
                         # 第二行后插入 2.txt 的第二行， 如果 2.txt 已读完，则不插入
* s 取代
    * sed    "s/123/456/"        1.txt # 替换第一处
    * sed    "s/123/456/2"       1.txt # 替换第二处
    * sed    "s/123/456/2g"      1.txt # 替换第二处及以后
    * sed    "s/123/456/g"       1.txt # 替换所有
    * sed -n "s/123/456/gp"      1.txt # 打印替换后的结果
    * sed -n "s/123/456/gw2.txt" 1.txt # 替换后的结果写入文件 2.txt
    * sed    "s|123|456|"        1.txt # 使用不同的分割符
    * sed    "s/.*/[&]/"         1.txt # & 用于表示所匹配到的内容
    * sed    "s/\(1\)/[\1]/"     1.txt # \1 表示第一个字串
    * sed -r "s/(1)/[\1]/"       1.txt # \1 表示第一个字串
    * sed    "s/1/a \t b/"       1.txt # 可以包含 \n \t
* t abc 前一个 s 命令成功会跳转到指定标签   -- 这个有点儿复杂, 感觉一般用不上
* T abc 前一个 s 命令未成功会跳转到指定标签 -- 这个有点儿复杂，感觉一般用不上
* w ... 写模式空间的内容到文件
    * sed     "1w1.c"      1.txt # 第一行行保存到文件
* W ... 写模式空间的第一行的内容到文件
* x 交换模式空间和保持空间的内容
* y 字符替换, 可以指定操作的行，无法指定替换一行中的第几个
    * sed "y/123/456/" 1.txt
    * sed "y/1-3/456/" 1.txt
    * sed "y/123/4-6/" 1.txt
    * sed "y/1-3/4-6/" 1.txt
* z
```

## 特别说明
* a i r R 插入的内容不在模式空间，所以后续的 d 或 D 不会对插入的内容有影响

## 使用例子
```
* sed -n '1!G; h; $p'                      1.txt # 逆序输出文件的内容
                                                 # 可以用 tac 代替
* sed    '=' 1.txt | sed -n "N; s/\n/ /; p"      # 添加行号
                                                 # 可以用 cat  -n 代替
* sed    ':start; $q; N; 4,$D; b start'    1.txt # 输出最后的三行
                                                 # 可以用 tail -3 代替
* sed    '/./,/^$/!d'                      3.txt # 删除连续的空行
                                                 # 可以用 cat  -s 代替
* sed    '/./,$!d'                         3.txt # 删除文件开头的空行
* sed    ':start; /^\n*$/{$d; N; b start}' 3.txt # 删除文件末尾的空行 -- 能理解即可, 太绕了
* sed    's/<[^>]*>//g; /^$/d'             3.txt # 删除 html 标签
```

## 感悟
* 建议直接使用扩展的正则表达式，也不在乎这么点儿效率
* 保持空间, N D P 会基础使用即可, 复杂的能读懂即可
* 会使用基本命令就足够了，太复杂的一般也用不到

