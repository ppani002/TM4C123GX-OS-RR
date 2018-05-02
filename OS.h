#ifndef OS_H
#define OS_H

//to use uint32_t
//#include <stdint.h>

//Change this value if you have different number of threads
#define THREADSIZE 3

//This initiates the tcb structs 
void OS_InitTCB(int *tSlices, void (*tasks)(void));

//This initiates the stack for each thread
//void OS_InitStack(tcbs *tcbP);

//This initiates the scheduler by setting up the threads to work in
//Round Robin
void OS_InitScheduler_RR(void);

//This is the OS scheduler. This is a simple Round Robin scheduler that moves
//to the next tcb
void OS_Scheduler_RR(void);

#endif
