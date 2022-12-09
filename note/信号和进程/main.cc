
#include <setjmp.h>
#include <signal.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>

#include <iostream>
#include <map>
#include <string>

std::map<int, std::string> m;
void init() {
    m[SIGHUP] = " 1-SIGHUP";
    m[SIGINT] = " 2-SIGINT";
    m[SIGQUIT] = " 3-SIGQUIT";
    m[SIGILL] = " 4-SIGILL";
    m[SIGTRAP] = " 5-SIGTRAP";
    m[SIGABRT] = " 6-SIGABRT";
    m[SIGBUS] = " 7-SIGBUS";
    m[SIGFPE] = " 8-SIGFPE";
    m[SIGKILL] = " 9-SIGKILL";
    m[SIGUSR1] = "10-SIGUSR1";
    m[SIGSEGV] = "11-SIGSEGV";
    m[SIGUSR2] = "12-SIGUSR2";
    m[SIGPIPE] = "13-SIGPIPE";
    m[SIGALRM] = "14-SIGALRM";
    m[SIGTERM] = "15-SIGTERM";
    m[SIGSTKFLT] = "16-SIGSTKFLT";
    m[SIGCHLD] = "17-SIGCHLD";
    m[SIGCONT] = "18-SIGCONT";
    m[SIGSTOP] = "19-SIGSTOP";
    m[SIGTSTP] = "20-SIGTSTP";
    m[SIGTTIN] = "21-SIGTTIN";
    m[SIGTTOU] = "22-SIGTTOU";
    m[SIGURG] = "23-SIGURG";
    m[SIGXCPU] = "24-SIGXCPU";
    m[SIGXFSZ] = "25-SIGXFSZ";
    m[SIGVTALRM] = "26-SIGVTALRM";
    m[SIGPROF] = "27-SIGPROF";
    m[SIGWINCH] = "28-SIGWINCH";
    m[SIGIO] = "29-SIGIO";
    m[SIGPWR] = "30-SIGPWR";
    m[SIGSYS] = "31-SIGSYS";
}

void log(const std::string& msg = "") {
    std::cout << "进程(" << getpid() << "): " << msg << std::endl;
}

void handle_signal(int sig, siginfo_t* sig_info, void*) {
    log("捕获信号 " + m[sig]);
}

void set_signal() {
    struct sigaction act;
    act.sa_sigaction = handle_signal;
    log("设置信号处理过程中阻塞所有信号");
    sigfillset(&act.sa_mask);
    act.sa_flags = SA_RESTART | SA_SIGINFO;
    for (auto key : m) {
        sigaction(key.first, &act, NULL);
    }
}

int main() {
    init();

    log("测试信号优先级");
    log("注册所有的信号处理");
    set_signal();
    log("阻塞所有信号");
    sigset_t mask;
    sigfillset(&mask);
    sigprocmask(SIG_SETMASK, &mask, NULL);

    sigset_t old_mask;
    sigprocmask(SIG_SETMASK, NULL, &old_mask);

    for (auto key : m)
        if (sigismember(&old_mask, key.first))
            log("已被阻塞的信号: " + m[key.first]);

    log("发送除 " + m[SIGKILL] + " 和 " + m[SIGSTOP] + " 外的所有信号");
    for (auto key : m)
        if (key.first != SIGKILL && key.first != SIGSTOP)
            kill(getpid(), key.first);

    sigset_t new_mask;
    sigsuspend(&new_mask);
    for (auto key : m)
        if (sigismember(&new_mask, key.first))
            log("待决的信号: " + m[key.first]);

    //    log("解除信号阻塞");
    //    sigprocmask(SIG_UNBLOCK, &mask, NULL);

    // sleep(1);
    sleep(10);

    log("主进程退出");

    return 0;
}
