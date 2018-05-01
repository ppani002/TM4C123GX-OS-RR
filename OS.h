#ifndef OS_H
#define OS_H

//to use uint32_t
#include <stdint.h>

//Change this value if you have different number of threads
#define THREADSIZE 3

//This structure is the Thread Control Block. It contains information
//on the thread, such as the stack location, it's time slice, it's task,
//and the next thread to execute
struct tcb
{
	int32_t *sp;
	int32_t time;
	void (*task)(void);
	struct tcb *next;
};
typedef struct tcb tcbs;

//Thread Control Block array. Also used in OS_StackInit in OS.s assembly file
extern tcbs tcbsArray[THREADSIZE];

//This pointer is used in the context switcher to load the next thread
extern tcbs *RunThread;

//This array contains the array of time slices for all threads in order
int32_t timeSlices[THREADSIZE];

//This array contains the array of thread tasks in order
//Note: void pointer arithmatic is not supported. 
void (*tasksArray[THREADSIZE])(void);


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
