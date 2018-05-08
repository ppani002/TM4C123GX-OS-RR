#ifndef OS_H
#define OS_H

//to use uint32_t
#include <stdint.h>

//Change this value if you have different number of threads
#define THREADSIZE 3

//Values for the semaphore
#define TO_COMPLETION 0 //When a thread needs to finish to completion 
#define THREAD_SYNC 1		//When 2 threads need to be synched (done in specific order)
#define MAILBOX 2				//When you have producer & consumer threads. 

//Importing assembly functions here
extern void OS_InitClock(void);
extern void OS_InitStack(int numT);
extern void OS_InitContextSwitcher(void);
extern void OS_Launch(void);
extern void OS_DisableInterrupts(void);
extern void OS_EnableInterrupts(void);
extern int32_t OS_CriticalSectionS(void);
extern void OS_CriticalSectionE(int32_t tBit);
extern int32_t OS_SemaphoreInit(int32_t semType);
extern void OS_SemaphoreWait(int32_t sem);
extern void OS_SemaphoreSignal(int32_t sem);

//This initiates the tcb structs 
void OS_InitTCB(void (*tasks)(void));

//This initiates the stack for each thread
//void OS_InitStack(tcbs *tcbP);

//This initiates the scheduler by setting up the threads to work in
//Round Robin
void OS_InitScheduler_RR(void);

//This is the OS scheduler. This is a simple Round Robin scheduler that moves
//to the next tcb
void OS_Scheduler_RR(void);

#endif
