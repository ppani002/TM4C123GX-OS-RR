	AREA oscode, CODE, READONLY
	THUMB
		
	;Includes definitions required for OS_InitContextSwitcher
	INCLUDE my_Constants.s
		
	IMPORT tcbsArray ;import array
	IMPORT RunThread ;import pointer

;This function sets up the systemclock with PIOSC 16MHz
;Change this if you wish to use a different clock, with divisor, etc
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
	BFC r1, #11, #1
	ORR r1, r1, #(1<<11) ;BYPASS to set system clock to OSC
	
	;Set USESYSDIV. Selects no division
	;AND r1, r1, #(0<<22) ;clear it 22
	BFC r1, #22, #1
	ORR r1, r1, #(0<<22) ;No division for system clock. This line is for clarity
	
	
	
	STR r1,[r0, #RCC]
	
	POP {r4, LR}

	ENDP

;This function initiates the stack by subtracting sp by the total number 
;of words needed to fill in all registers. The stack location for PC is
;stored with the threads task location. xPSR not needed.
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
	
	;RCC used to etsablish base clock
	
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
	

	;Set CLK_SRC bit to use the system clock (look at InitClock). STCTRL
	LDR r0, =SYS_PERIPH
	LDR r1, [r0,#STCTRL]
	BFC r1, #2, #1
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

	;Get SP to the first tcb and load into SP register
	LDR r0, =RunThread
	LDR r1, [r0]
	LDR sp, [r1]
	
	;Pop the context
	POP {r4-r11}
	POP {r0-r3}
	POP {r12}
	POP {r14}
	POP {r15}
	
	;Ignore xPSR (r"16", right after PC r15)
	ADD sp, sp, #4
	
	;Add CPSIE I as another function
	CPSIE I
	BX LR
	
	ENDP


;This function is used to disable interrupts. Use it for large critical sections without
;a shared resource
OS_DisableInterrupts	PROC
		EXPORT OS_DisableInterrupts
			
	CPSID I
	
	BX LR
	
	ENDP
	
;This function is used to enable interrupts after disabling them. Use this when you use 
;OS_DisableInterrupts
OS_EnableInterrupts	PROC
		EXPORT OS_EnableInterrupts

	CPSIE I
	
	BX LR
	
	ENDP
		
;This function is used to disable interrupts. Use this for critical sections that
;share resources
;r0 (return value) = PRIMASK (reenables interrupts later)
OS_CriticalSectionS	PROC
		EXPORT OS_CriticalSectionS
		
	MRS r0, PRIMASK
	CPSID I
	
	BX LR
	
	ENDP
		
;This function is used to enable interrpts. Use it after using OS_CriticalSection
;r0 (input) = PRIMASK value from OS_CriticalSectionS
OS_CriticalSectionE	PROC
		EXPORT OS_CriticalSectionE
			
	MSR PRIMASK, r0
	
	BX LR
	
;This function is used to get a semaphore. 

		
	END
		