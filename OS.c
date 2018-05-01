#include "OS.h"

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
