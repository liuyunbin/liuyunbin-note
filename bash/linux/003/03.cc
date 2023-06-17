
#ifndef LOG_H_
#define LOG_H_

#include <setjmp.h>
#include <signal.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>

#include <algorithm>
#include <bitset>
#include <cctype>
#include <cfenv>
#include <cfloat>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <iomanip>
#include <iostream>
#include <limits>
#include <map>
#include <sstream>
#include <string>

std::string get_time() {
    time_t now = time(NULL);
    struct tm* info = localtime(&now);
    char buf[1024];
    strftime(buf, sizeof(buf), "%Y-%m-%d %H:%M:%S %z", info);
    return buf;
}

void log(const std::string& msg = "") {
    std::cout << get_time() << " " << msg << std::endl;
}

#endif
#include "00.h"

int main() {
    log();
    log("测试新建子进程对应的进程组(子进程属于不同的会话)");
    log();

    pid_t child = fork();
    if (child == 0) {
        log("子进程新建会话");
        setsid();
        for (;;)
            ;
    }
    sleep(1);
    log("父进程会话: " + std::to_string(getsid(getpid())));
    log("子进程会话: " + std::to_string(getsid(child)));
    log("新建子进程(" + std::to_string(child) + ")的进程组");
    test(child, child);
    kill(child, SIGKILL);

    sleep(1);
    log("主进程退出");
    log();

    return 0;
}
