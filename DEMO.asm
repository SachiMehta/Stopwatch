; =================================================================
; MULTI-LAP RUNNING & LED DISPLAY TEST FOR SCOMP
; LEDs   (&H001): Displays running status of laps 12..1 (bits 11..0)
; Hex1   (&H005): Displays current lap number
; Hex0   (&H004): Displays Lap 1 timer value
; =================================================================



ORG     0

START:
	; 1. Reset everything
	LOADi    0
	OUT     SW_RESET
	
	
	; start the first timer
	CALL	SHOW1
	OUT 	SW_PLAY
	
	CALL	DELAY ;let it run for a bit
	
	;lap to next timer
	OUT 	SW_LAP
	CALL	SHOW2
	CALL	DELAY2 ; let 2 run for a bit
	
	
	LOAD 	lap_play ;Start the first one again
	OUT 	LAP1
	
	
finish:
	CALL	SHOW1
	JUMP 	finish
	
	

; =================================================================
; Subroutines
; =================================================================

SHOW1:
		; --- 1. Update LEDs with running status of all laps ---
		IN      SW_STATUS     ; Reads B11-B0 = run bit of laps 12..1 from stopwatch (&H072)
		OUT     LEDs          ; Light up corresponding LEDs on the board
		
		; --- 2. Update Hex Displays ---
		LOADI   1 	
		;IN      LAP_Num   ; Read current lap number from &H073
		OUT     HEX1          

		IN      LAP1       ; Read Lap 1 time
		OUT     HEX0          

		Return
	
SHOW2:
		; --- 1. Update LEDs with running status of all laps ---
		IN      SW_STATUS     ; Reads B11-B0 = run bit of laps 12..1 from stopwatch (&H072)
		OUT     LEDs          ; Light up corresponding LEDs on the board
		
		; --- 2. Update Hex Displays ---
		LOADI   2 	
		;IN      LAP_Num   ; Read current lap number from &H073
		OUT     HEX1          

		IN      LAP2       ; Read Lap 1 time
		OUT     HEX0          

		Return
		
SHOW3:
		; --- 1. Update LEDs with running status of all laps ---
		IN      SW_STATUS     ; Reads B11-B0 = run bit of laps 12..1 from stopwatch (&H072)
		OUT     LEDs          ; Light up corresponding LEDs on the board
		
		; --- 2. Update Hex Displays ---
		LOADI   3	
		;IN      LAP_Num   ; Read current lap number from &H073
		OUT     HEX1          

		IN      LAP3       ; Read Lap 3 time
		OUT     HEX0          

		Return

;SHOW2:
;		; --- 1. Update LEDs with running status of all laps ---
;		IN      SW_STATUS     ; Reads B11-B0 = run bit of laps 12..1 from stopwatch (&H072)
;		OUT     LEDs          ; Light up corresponding LEDs on the board
;		
;		; --- 2. Update Hex Displays ---
;		IN      LAP_Num   ; Read current lap number from &H073
;		OUT     HEX1          
;
;		IN      SW_LAP1       ; Read Lap 1 time
;		OUT     HEX0          
;
;		Return
DELAY:
		CALL SHOW1 
		IN LAP1
		AND mask
		ADDI -50
		;OUT  HEX0
		
		JNEG DELAY ;loop if not 500 deciseconds
		RETURN 
		
DELAY2:
		CALL SHOW2 
		IN LAP2
		AND mask
		ADDI -40
		;OUT  HEX0
		
		JNEG DELAY2 ;loop if not 500 deciseconds
		RETURN 
		
		
; =================================================================
; Constants 
; =================================================================
ORG     &H0F0

; --- I/O Address Definitions ---
LEDs            EQU &H001    ; LED output port (16-bit, lowest 12 bits = laps 12..1)
HEX0            EQU &H004    ; Hex display 0 (Lap timer)
HEX1            EQU &H005    ; Hex display 1 (Lap number)

;--- consts----
mask: DW &B0111111111111111

;OUT commands to run 
SW_RESET        EQU &H070    ; Write: Reset all
SW_PLAY   		EQU &H071    ; Write: Play current lap
SW_PAUSE        EQU &H072    ; Write: Pause
SW_LAP   		EQU &H073    ; Write: Next lap

;IN commands to read info
SW_STATUS       EQU &H072    ; Read: Run bit of laps 12..1 (B11-B0)
LAP_Num     	EQU &H073    ; Write: Next lap, Read: Current lap number

LAP1         	EQU &H074    ; Lap 1 Timer (0x74)
LAP2         	EQU &H075
LAP3         	EQU &H076

lap_play: 			DW &B0100000000000000
lap_pause: 			DW &B1000000000000000