
#include <setjmp.h>
#include <signal.h>
#include <sys/types.h>
#include <unistd.h>

#include <iostream>
#include <map>
#include <string>

void log(const std::string& msg = "") {
    std::cout << "进程(" << getpid() << "): " << msg << std::endl;
}

void handle_signal(int sig, siginfo_t* sig_info, void*) {
    log("捕获来自 " + std::to_string(sig_info->si_pid) + " 的信号 SIGABRT");
}

void set_signal() {
    struct sigaction act;
    sigemptyset(&act.sa_mask);
    act.sa_sigaction = handle_signal;
    act.sa_flags = SA_SIGINFO;
    sigaction(SIGABRT, &act, NULL);
}

int main() {
    log("测试 SIGABRT 处理为 捕获信号并返回");
    log();

    log("设置 SIGABRT 处理为 捕获信号并返回");
    set_signal();

    log("调用 abort()");
    abort();

    log();
    log("主进程正常退出");

    return 0;
}
