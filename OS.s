	AREA oscode, CODE, READONLY
	THUMB
		
	;Includes definitions required for OS_InitContextSwitcher
	INCLUDE my_Constants.s
		
	IMPORT tcbsArray ;import array
	IMPORT RunThread ;import pointer

;This function sets up the systemclock with PIOSC 16MHz
OS_InitClock	PROC
		EXPORT OS_InitClock

	;RCC manipulations here to set base clocks
	PUSH {r4, LR}
	
	LDR r0, =SYS_CONTROL
	LDR r1,[r0, #RCC]
	
	;Set OSCRC. Select PIOSC
	;AND r1, r1, #(3<<4) ;clear bits 5 and 4. Change to BIC
	BFC r1, #4, #2
	ORR r1, r1, #(1<<4) ;OSCRC to set PIOSC as System clock
	
	;Set BYPASS. 
	;AND r1, r1, #(0<<11) ;clear bit 11
	ORR r1, r1, #(1<<11) ;BYPASS to set system clock to OSC
	
	;Set USESYSDIV. Selects no division
	AND r1, r1, #(0<<22) ;clear it 22
	ORR r1, r1, #(0<<22) ;No division for system clock. This line is for clarity
	
	
	
	STR r1,[r0, #RCC]
	
	POP {r4, LR}

	ENDP

;This function initiates the stack by subtracting sp by the total number 
;of words needed to fill in all registers. The stack location for PC is
;stored with the threads task location
;r0 = numThreads (THREADSIZE)
OS_InitStack	PROC
		EXPORT OS_InitStack
			
		PUSH {r4, LR}
		
		LDR r1,=tcbsArray ;Loading the task from the tcbsArray
		
		MOV r4, #0
loop	CMP r0, r4
		BEQ endloop
		SUB sp, #8 ;This is where task will be saved, in PC slot of stack
		
		;Store task from TCB to PC slot in stack
		LDR sp, [r1,#8]	;offset of 8 to reach task in TCB
		ADD r1, #32 ; assuming each data in tcb is 32 bits, total is 32 words in RAM for next tcb. tcbsArray[i], i = 1, 2, 3, ...
		
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
	PUSH {r4, LR}
	
	;RCGC used to etsablish base clock
	
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
	;LDR r1, [r0,#STCURRENT]
	
	;May not need this. Finish InitClock() first.
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
	;POP {LR}
	POP {r4, PC}
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