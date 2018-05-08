#include "OS.h"

//tcbs *tcbsArrayP = &tcbsArray[0];

int main(void)
{
	OS_InitClock();
	OS_InitTCB(&tasks);
	OS_InitStack();
	OS_InitScheduler_RR();
	OS_InitContextSwitcher();
	OS_Launch();
}
