#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/fs.h"


void example_kill_system(int interval, int loop_size) {
    int pid = getpid();
    for (int i = 0; i < loop_size; i++) {
        if (i % interval == 0 && pid == getpid()) {
            printf("kill system %d/%d completed.\n", i, loop_size);
        }
        if (i == loop_size / 2) {
            kill_system();
        }
    }
    printf("\n");
}

void pause_system_dem(int interval, int pause_seconds, int loop_size) {
    int pid = getpid();
    for (int i = 0; i < loop_size; i++) {
        if (i % interval == 0 && pid == getpid()) {
            printf("pause system %d/%d completed.\n", i, loop_size);
        }
        if (i == loop_size / 2) {
            pause_system(pause_seconds);
        }
    }
    printf("\n");
}

int main(int argc, char** argv)
{
  pause_system_dem(10,10,100);
  example_kill_system(10,100);
  exit(0);
}
