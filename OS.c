#include "OS.h"
#include <stdint.h>

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
tcbs tcbsArray[THREADSIZE];

//This pointer is used in the context switcher to load the next thread
//Initialized to 0 because variables imported to assembly must be initialized
tcbs *RunThread;// = 0;

//This array contains the array of time slices for all threads in order
int32_t timeSlices[THREADSIZE];

//This array contains the array of thread tasks in order
//Note: void pointer arithmatic is not supported. 
void (*tasksArray[THREADSIZE])(void);

void OS_InitTCB(int *tSlices, void (*tasks)(void))
{
	int i = 0;
	for(/*int i = 0*/; i<THREADSIZE; i++)
	{
		//Set fields for each thread context in TCB
		tcbsArray[i].time = *(tSlices+i);
		tcbsArray[i].task = tasksArray[i];//*(tasks+i);
	}
}

void OS_InitScheduler_RR()
{
	int i = 0;
	for(/*int i = 0*/; i<THREADSIZE; i++)
	{
		//Set up the linked lists
		tcbsArray[i].next = &tcbsArray[(i+1)%THREADSIZE];
	}
	//Set the first thread to run
	RunThread = &tcbsArray[0];
	
}

void OS_Scheduler_RR(void)
{
	//Changes pointer to the next tcb
	RunThread = RunThread->next;
}
