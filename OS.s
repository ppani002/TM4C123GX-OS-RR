	AREA oscode, CODE, READONLY
	THUMB
		
	;Includes definitions required for OS_InitContextSwitcher
	INCLUDE my_Constants.s
		
	IMPORT tcbsArrayP ;import array
	IMPORT RunThread ;import pointer

;This function sets up the systemclock
OS_InitClock	PROC
		EXPORT OS_InitClock

	ENDP

;This function initiates the stack by subtracting sp by the total number 
;of words needed to fill in all registers. The stack location for PC is
;stored with the threads task location
OS_InitStack	PROC
		EXPORT OS_InitStack
			
		PUSH {r4, LR}
		
		LDR r1,=tcbsArrayP ;Loading the task from the tcbsArray
		
		MOV r4, #0
loop	CMP r0, r4
		BEQ endloop
		SUB sp, #8 ;This is where task will be saved, in PC slot of stack
		
		;Load task from TCB
		STR sp, [r1,#8]	;offset of 8
		ADD r1, #32 ; assuming each data in tcb is 32 bits, total is 32 words in RAM for next tcb
		
		SUB sp, #56
		SUB r4, #1
		B loop
endloop	POP {r4, PC}

		ENDP 

;This function initiates SysTick, the mechanism used to perform the context switch.
;It sets the base frequency to 1ms.
OS_InitContextSwitcher PROC
		EXPORT OS_InitContextSwitcher

			;Push LR onto stack first
	PUSH {LR}
	
	;Clear ENABLE bit. STCTRL
	LDR r0, =SYS_PERIPH
	LDR r1, [r0,#STCTRL]
	AND r1, r1, #0	;Clear bit 0
	STR r1, [r0, #STCTRL]
	
	;Set reload value. STRELOAD
	LDR r0, =SYS_PERIPH
	LDR r1, [r0,#STRELOAD]
	ORR r1, r1, #(1<<5);23) ;Set interrupt period here
	STR r1, [r0,#STRELOAD]
	
	;Clear timer and interrupt flag. STCURRENT
	LDR r0, =SYS_PERIPH
	LDR r1, [r0,#STCURRENT]
	ORR r1, r1, #1 ;Write any value to reset
	STR r1, [r0,#STCURRENT]
	LDR r1, [r0,#STCURRENT]
	
	;Set CLK_SRC bit to use the system clock (PIOSC). STCTRL
	LDR r0, =SYS_PERIPH
	LDR r1, [r0,#STCTRL]
	ORR r1, r1, #(1<<2) ;bit 2
	STR r1, [r0,#STCTRL]
	
	;Set INTEN bit to enable interrupts. STCTRL
	LDR r0, =SYS_PERIPH
	LDR r1, [r0,#STCTRL]
	ORR r1, r1, #(1<<1) ;bit 1
	STR r1, [r0,#STCTRL]
	
	;Set ENABLE bit to turn SysTick on again. STCTRL
	
	
	;Set TICK priority field. SYSPRI3
	LDR r0, =SYS_PERIPH
	LDR r1, [r0,#SYSPRI3]
	ORR r1, r1, #(1<<29) ;priority 1. TICK begins at bit 29
	STR r1, [r0,#SYSPRI3]
	
	;Set ENABLE bit to turn SysTick on again. STCTRL
	LDR r0, =SYS_PERIPH
	LDR r1, [r0,#STCTRL]
	ORR r1, r1, #1 ;bit 0
	STR r1, [r0,#STCTRL]
	
	
	;Pop LR and return to __main
	POP {LR}
	BX LR
	
	ENDP
				
;This function starts the RTOS by loading the context of the first
;thread
OS_Launch PROC
		EXPORT OS_Launch

	LDR r0, =RunThread
	LDR r1, [r0]
	LDR sp, [r1]
	
	POP {r4-r11}
	POP {r0-r3}
	POP {r12}
	POP {r14}
	POP {r15}
	;POP {xPSR} ;?
	
	CPSIE I
	BX LR
	
	ENDP

	END
	;write code for OS_InitStack here, and OS_ContextSwitcher and OS_Launch