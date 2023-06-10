
#include "log.h"

int main() {
    log("测试销毁僵尸进程");
    log();

    if (fork() == 0) {
        pid_t child = fork();

        if (child == 0) {
            // 子进程
            log("子进程已启动");
            for (;;)
                ;
        } else if (fork() == 0) {
            // 控制进程
            log("控制进程已启动");
            sleep(1);
            std::string cmd = "ps -o pid,ppid,comm,state -p ";
            cmd += std::to_string(child);
            log("子进程状态");
            system(cmd.data());
            log("杀死子进程");
            kill(child, SIGKILL);
            sleep(1);
            log("子进程状态");
            system(cmd.data());
            log("杀死父进程 " + std::to_string(getppid()));
            kill(getppid(), SIGKILL);
            sleep(1);
            log("子进程状态");
            system(cmd.data());
            return 0;
        } else {
            // 父进程
            log("父进程已启动");
            for (;;)
                ;
        }
    }

    sleep(4);
    log();
    log("主进程退出");

    return 0;
}