; Test

Include ..\Irvine32.inc
Include ..\win32.inc
nColumns = 64
nRows = 16

; Sound Support
includelib Winmm.lib

PlaySound PROTO,
        pszSound:PTR BYTE, 
        hmod:DWORD, 
        fdwSound:DWORD
	
;  "Working functions"	
;	INVOKE PlaySound, OFFSET deviceConnect, NULL, SND_ALIAS
;   INVOKE PlaySound, OFFSET file, NULL, SND_FILENAME


.data
	; Display Matrixes
	matriz BYTE nColumns*nRows dup(00h)
	screen_buffer BYTE nColumns*nRows dup(0)
	
	; Miscellaneous Variables 
	carry BYTE ?
	Swap DWORD 0
	
	; Player Variables
	player_x DWORD 6  ; 6-62  // 0 - 63
	player_y DWORD 6  ; 0-15
	score DWORD 0
	
	; Enemy options
	enemytimer DWORD 20 ;20
	enemyposition DWORD 45 dup(0)
	
	; Difficulty
	foodwaitingtime DWORD 40  ; 40 - Easy, 30 - Medium, 20 - Hard, 10 - Pro, 5 - Prozera
	difficulty DWORD 20  ; 20 - Easy, 15 - Medium, 10 - Hard, 5 - Pro, 2 - Prozera
	DifSetting DWORD 1   ; 1 - Easy, 2 - Medium, 3 - Hard, 4 - Pro, 5 - Prozera
	
	; Screen Options
	GameState DWORD 0  ; 0 - Main Menu, 1 - In-game, 2 - Instructions, 3 - Difficulty
	MenuOption BYTE 00000001b
	
	; Text Memory
	tScore BYTE "Score: ", 0
	tTitle BYTE "Hungry Fish", 0
	tPlay BYTE "Play!", 0
	tInstructions BYTE "Instructions!", 0
	tDifficulty BYTE "Difficulty!", 0
	tQuit BYTE "Quit!", 0
	tInst1 BYTE "You objective is to guide your fish", 0
	tInst2 BYTE "through the sea.", 0
	tInst3 BYTE "Eat food (+) to increase your overall score.", 0
	tInst4 BYTE "Avoid bigger fishes. They kill you.", 0
	tInst5 BYTE "Hit SPACE to go back.", 0
	tDif1 BYTE "Easy", 0
	tDif2 BYTE "Medium", 0
	tDif3 BYTE "Hard", 0
	tDif4 BYTE "Pro", 0
	tDif5 BYTE "Prozera", 0
	tGO1 BYTE "You died!", 0
	TGO2 BYTE "Final Score: ", 0
	
	; Cursor Options
	cci CONSOLE_CURSOR_INFO <>
	chand dd ?
	
	; Sound Options
	deviceConnect BYTE "DeviceConnect",0

	SND_ALIAS    DWORD 00010000h
	SND_RESOURCE DWORD 00040005h
	SND_FILENAME DWORD 00020000h

	file BYTE ".\Requiem.wav",0
.code

; Rotates all elements in array. Inserts the first element into the last
; NO PARAMETERS
Rotate PROC
	push ecx
	push eax
	push ebx
	push edx
	mov ecx, LENGTHOF matriz
	dec ecx
	mov ebx, 0
	mov edx, 1
	mov al, matriz[0]
	mov carry, al ; Sets carry as first element

L1:	
	mov al, matriz[edx]
	mov matriz[ebx], al
	inc ebx
	inc edx
	cmp ebx, ecx
	jne L1
	
	mov al, carry
	mov matriz[ecx], al
	
	pop edx
	pop ebx
	pop eax 
	pop ecx
	ret
Rotate ENDP

; Moves all elements in an array to the left
; NO PARAMETERS
Shift PROC
	push ecx
	push eax
	push ebx
	push edx
	mov ecx, LENGTHOF matriz
	dec ecx
	mov ebx, 0
	mov edx, 1

L1:	
	mov al, matriz[edx]
	mov matriz[ebx], al
	inc ebx
	inc edx
	cmp ebx, ecx
	jne L1
	
	mov al, 0
	mov matriz[ecx], al
	
	; Clears back row
	mov matriz[63], 0 
	mov matriz[127], 0
	mov matriz[191], 0
	mov matriz[255], 0
	mov matriz[319], 0
	mov matriz[383], 0
	mov matriz[447], 0
	mov matriz[511], 0
	mov matriz[575], 0
	mov matriz[639], 0
	mov matriz[703], 0
	mov matriz[767], 0
	mov matriz[831], 0
	mov matriz[895], 0
	mov matriz[959], 0
	mov matriz[1023], 0
	
	;;; Shifts enemy positions ;;;
	; Gets a third of length of enemyposition array
	mov ebx, 1
	mov ecx, 3
	mov eax, LENGTHOF enemyposition
	idiv cl
	mov ecx, eax
	
L18:  ; Checks every x position field and decreases them
	mov eax, enemyposition[ebx]
	dec eax
	cmp eax, -12 ; If is out of screen
	jbe L19
	mov enemyposition[ebx-1], 0  ; Unallocates Enemy
	
L19:	
	mov enemyposition[ebx], eax
	add ebx, 3
	loop L18
	
	pop edx
	pop ebx
	pop eax
	pop ecx
	ret
Shift ENDP

; Draws screen_buffer to the terminal
; NO PARAMETERS
DrawScreen PROC
	push ecx
	push eax
	push edx
	push ebx
	
	; Posiciona o cursor ap?s o header
	mov edx, GameState
	cmp edx, 1
	jne skip
	call GameCursor	
skip:
	call SetColor_Blue
	
	mov edx, nRows
	mov ebx, 0
L3:
	mov ecx, nColumns
L2:
	mov al, screen_buffer[ebx]
	call WriteChar
	inc ebx
	loop L2
	
	call Crlf
	dec edx
	cmp edx, 0
	jne L3
	
	pop ebx
	pop edx
	pop eax
	pop ecx
	ret
DrawScreen ENDP

; Moves the fish to the screen_buffer
; NO PARAMETERS
DrawFish PROC
	push eax
	push ebx
	push ecx
	push edx
	
	mov eax,0  ; Writes screen to buffer
	mov ecx, LENGTHOF matriz
L4:
	mov bl, matriz[eax]
	mov screen_buffer[eax], bl 
	inc eax
	loop L4             ; ----------
	
	mov eax, nColumns ; Find Player position
	mul player_y
	add eax, player_x
	
	mov screen_buffer[eax], 62   ; Draw Fish
	mov screen_buffer[eax-1], 167
	mov screen_buffer[eax-2], 40
	mov screen_buffer[eax-3], 40
	mov screen_buffer[eax-4], 40
	mov screen_buffer[eax-5], 60
	mov screen_buffer[eax-6], 62
	
	pop edx
	pop ecx
	pop ebx
	pop eax
	ret
DrawFish ENDP

; Waits 50 ms. Used in keyboard key detection.
; NO PARAMETERS
Tickrate PROC
	push eax
	mov eax, 50
	call delay
	pop eax
	ret
Tickrate ENDP

; Waits 20 ms. Used in graphic rendering optimization
; NO PARAMETERS
FPSRate PROC
	push eax
	mov eax, 20
	call delay
	pop eax
	ret
FPSRate ENDP

; In-game key detection and fish movement
; NO PARAMETERS
Move PROC
	push eax
	push ebx
	push ecx
	push edx

	mov eax, 0
	call FPSRate
	call ReadKey
	jz sair
	
	cmp al, 77h
	je up
	cmp al, 61h
	je left
	cmp al, 64h
	je right
	cmp al, 73h
	je down
	cmp al, "q"
	jz q
	jmp sair
	
q:
	call SetColor_Default
	call Clrscr
	call ShowCursor
	exit
	
left:
	mov ebx, player_x
	cmp ebx, 6
	jbe sair
	dec ebx
	mov player_x, ebx
	jmp sair

right:
	mov ebx, player_x
	cmp ebx, nColumns-1
	jae sair
	inc ebx
	mov player_x, ebx
	jmp sair

up:
	mov ebx, player_y
	cmp ebx, 0
	jbe sair
	dec ebx
	mov player_y, ebx
	jmp sair

down:
	mov ebx, player_y
	cmp ebx, nRows-1
	jae sair
	inc ebx
	mov player_y, ebx
	
sair:
	pop edx
	pop ecx
	pop ebx
	pop eax
	ret
Move ENDP

; Clears the game screen fast
; NO PARAMETERS
Clear PROC
	push eax
	push ecx
	push ebx
	push edx
	
	mov ecx, LENGTHOF screen_buffer
	mov al, " "
	mov ebx, 0
	mov dx, 0200h 
L5:
	call GOTOXY
	call WriteChar
	inc dl
	cmp dl, nRows
	jne L5
	add dx, 0100h
	mov dl, 0
	cmp dx, 1000h
	je L6
L6:
	
	pop edx
	pop ebx
	pop ecx
	pop eax
	ret
Clear ENDP

; Sets cursor to the starting position of the terminal
; NO PARAMETERS
FixCursor PROC
	push edx
	
	mov edx, 0
	call GOTOXY
	
	pop edx
	ret
FixCursor ENDP

; Fixes cursor glitching all around the screen
; NO PARAMETERS
HoldCursor PROC
	push edx
	
	mov dx, 1200h
	call GOTOXY
	
	pop edx
	ret
HoldCursor ENDP

; Sets the cursor to the first pixel of the game screen
; NO PARAMETERS
GameCursor PROC
	push edx

	mov edx, 0200h
	call GOTOXY
	
	pop edx
	ret
GameCursor ENDP

; Generates food into the screen matrix
; Arguments: foodwaitingtime
CreateFood PROC
	push eax  ; + Ascii
	push ecx  ; Max waiting time
	push ebx  ; Row index

	mov ecx, foodwaitingtime
	dec ecx
	cmp ecx, 0  ; If it's not time yet
	ja L7	  ; Ends function
	
	; Else, allocates a food to the screen matrix
	mov eax, nRows  
	call RandomRange
	mov ah, 0
	mov bl, nColumns
	mul bl
	mov ebx, eax
	mov al, "+"
	mov matriz[ebx+63], al  ; nColumns-1
	mov eax, 50  ; Next waiting time
	call RandomRange
	mov ecx, eax
	
L7:
	mov foodwaitingtime, ecx   ; Saves time value
	
	; Fix for food jam effect
	mov eax, 11
	call RandomRange
	cmp eax, 0
	jne L8
	
	mov foodwaitingtime, 1
L8:	
	pop ebx
	pop ecx
	pop eax
	ret
CreateFood ENDP

; Sets foreground to red and background to black
; NO PARAMETERS
SetColor_Red PROC
	push eax

	mov eax, red+(blue*16)
	call SetTextColor
	
	pop eax
	ret
SetColor_Red ENDP


; Sets foreground to white and background to lightblue
; NO PARAMETERS
SetColor_Blue PROC
	push eax

	mov eax, White+(lightblue*16)
	call SetTextColor
	
	pop eax
	ret
SetColor_Blue ENDP

; Sets terminal colors back to default
; NO PARAMETERS
SetColor_Default PROC
	push eax

	mov eax, white+(black*16)
	call SetTextColor
	
	pop eax
	ret
SetColor_Default ENDP

; Draws score header above game screen
; NO PARAMETERS
DrawHeader PROC
	push edx
	push eax
	push ecx
	
	call FixCursor
	call SetColor_Default
	
	; Draws black spaces in front of scoreboard
	mov ecx, nColumns
	mov al, 0
L35:
	call WriteChar
	loop L35
	
	; Draws Scoreboard
	call FixCursor
	mov edx, OFFSET tScore
	call WriteString
	mov eax, score
	call WriteDec
	
	
	; Draws Upper Border
	mov al, 3Dh 
	mov edx, 0100h
	call GOTOXY
	mov ecx, nColumns
	
L9: 
	call WriteChar
	loop L9 
	
	;Draws Lower Border
	mov edx, 0
	mov dh, nRows
	add dh, 2
	call GOTOXY
	mov ecx, nColumns

L10: 
	call WriteChar
	loop L10 	
	
	pop ecx
	pop eax
	pop edx
	ret
DrawHeader ENDP

; Checks for collision with objects
; NO PARAMETERS
Collision PROC
	push eax
	push ebx

	call Get_Index  ; Gets overall player position
	mov ebx, 0
	
	; Merges screen_buffer with screen_matrix to find collisions
	cmp matriz[eax], 0
	ja L11
	inc ebx
	cmp matriz[eax-1], 0
	ja L11
	inc ebx
	cmp matriz[eax-2], 0
	ja L11
	inc ebx
	cmp matriz[eax-3], 0
	ja L11
	inc ebx
	cmp matriz[eax-4], 0
	ja L11
	inc ebx
	cmp matriz[eax-5], 0
	ja L11
	inc ebx
	cmp matriz[eax-6], 0
	ja L11
	jmp L12
	
L11: ; Found a collision
	sub eax, ebx
	cmp matriz[eax], "+"
	je HitFood
	jmp EnemyHit

HitFood: ; Collided to food
	mov matriz[eax], 0
	mov eax, score
	inc eax
	mov score, eax
	jmp L12

EnemyHit:  ; Collided to enemy
	mov GameState, 4

L12:  ; Didn't Collide	
	pop ebx
	pop eax
	ret
Collision ENDP

; Reads player x and y information and returns the position index on the screen
; RETURNS: eax = matriz index value
Get_Index PROC
	push ebx
	
	mov eax, player_y
	mov ebx, nColumns
	imul bl
	add eax, player_x
	
	pop ebx
	ret
Get_Index ENDP

; Reads enemy x and y information and returns the position index on the screen
; READS: ebx = index of status element of the object
; RETURNS: eax = matriz index value
Get_EnemyIndex PROC
	push ecx
	
	mov eax, 0
	mov eax, enemyposition[ebx+2]
	mov ecx, nColumns
	imul cl
	add eax, enemyposition[ebx+1]
	
	pop ecx
	ret
Get_EnemyIndex ENDP

; Creates enemy object
; NO PARAMETERS
CreateEnemy PROC
	push eax
	push ebx
	push ecx

	mov ecx, enemytimer
	dec ecx
	cmp ecx, 0  ; If it's not time yet
	ja L13	  ; Ends function
	
	; Else, allocates an enemy to the screen matrix
	call AllocateEnemy
	cmp ebx, 0
	je L13  ; Exits if allocation was unsuccessful
	mov ecx, eax  ; ecx contains index position to allocated element
	
	mov eax, nRows 
	call RandomRange ; Finds a Y position for the enemy
	mov ebx, nColumns
	mul bl
	mov ebx, eax
	mov al, "<"
	
	; Sets enemy information array
	mov matriz[ebx+63], al
	
	mov ecx, difficulty
	
L13:
	mov enemytimer, ecx
	pop ecx
	pop ebx
	pop eax
	ret
CreateEnemy ENDP

; Allocates an enemy object into the enemyposition array
; RETURNS: eax = index of status field of the object. ebx = boolean (if allocation was successful)
AllocateEnemy PROC
	push ecx
	push eax

	; Gets a third of length of enemyposition array
	mov ebx, 0
	mov ecx, 3
	mov eax, LENGTHOF enemyposition
	idiv cl
	mov ecx, eax
	
L14:  ; Checks every status position for an unallocated enemy
	mov eax, enemyposition[ebx]
	cmp eax, 0
	je L15
	add ebx, 3
	loop L14
	
L15: ; Found an unallocated position
	mov eax, ebx
	mov ebx, 1
	jmp L17

L16: ; No position found (VERY UNLIKELY)	
	mov ebx, 0
	pop eax
	pop ecx
	ret
L17: ; Exit function if allocated successfully
	pop ecx
	pop ecx
	ret
AllocateEnemy ENDP

COMMENT @

DrawEnemy PROC
	push eax
	push ebx
	push ecx
	push edx

	; Gets a third of enemies' array length
	mov eax, LENGTHOF enemyposition
	mov ecx, 3
	idiv cl
	mov ecx, eax ; number of iterations
	dec ecx
	mov ebx, 0  ; loop index
	
L20: ; Checks for the closest border
	mov edx, enemyposition[ebx]
	cmp edx, 0  ; Checks if object is allocated
	je L22 ; Not allocated, move to the next object
	
	cmp edx, 2 ; Checks if object was drawn already
	je L26

	mov edx, enemyposition[ebx+1] 
	cmp edx, 0      ; Checks if is next to right or left border
	jb L21     ; Goes to left border rendering part
	
	; Draws relative to right border
	mov Swap, ecx  ; Quick saves number of iterations to Swap memory
	cmp edx, nColumns  ; 1st Char
	jnb L22
	call Get_EnemyIndex
	mov cl, "<"
	mov matriz[eax], cl  ; BUG
	inc edx
	cmp edx, nColumns  ; 2nd Char
	jnb L22
	mov matriz[eax+1], cl
	inc edx
	cmp edx, nColumns  ; 3rd Char
	jnb L22
	mov cl, "*"
	mov matriz[eax+2], cl
	inc edx
	cmp edx, nColumns  ; 4th Char
	jnb L22
	mov cl, ")"
	mov matriz[eax+3], cl
	inc edx
	cmp edx, nColumns  ; 5th Char
	jnb L22
	mov matriz[eax+4], cl
	inc edx
	cmp edx, nColumns  ; 6th Char
	jnb L22
	mov matriz[eax+5], cl
	inc edx
	cmp edx, nColumns  ; 7th Char
	jnb L22
	mov matriz[eax+6], cl
	inc edx
	cmp edx, nColumns  ; 8th Char
	jnb L22
	mov matriz[eax+7], cl
	inc edx
	cmp edx, nColumns  ; 9th Char
	jnb L22
	mov cl, ">"
	mov matriz[eax+8], cl
	inc edx
	cmp edx, nColumns  ; 10th Char
	jnb L22
	mov matriz[eax+9], cl
	inc edx
	cmp edx, nColumns  ; 11th Char
	jnb L22
	mov cl, "<"
	mov matriz[eax+10], cl
	inc edx
	jmp L22  ; Jumps to next object iteration
	
L23:  ; Bridges far loop
	jmp L20
	
L21: ; Draws relative to left border
	call DrawEnemy_LeftBorder  ; Used to shorten jumps
	jmp L22
	
L26: ; Object was already drawn
	mov enemyposition[ebx], 2
	
L22: ; Goes to next object
	add ebx, 3
	cmp Swap, 0
	je L25
	mov ecx, Swap  ; Quick loads number of iterations to ecx
	jmp L25

L25:	
	loop L23
	
	pop edx
	pop ecx
	pop ebx
	pop eax
	ret
DrawEnemy ENDP

Debug PROC
	push ecx
	push eax
	push ebx
	
	mov ax, 3000h
	call GOTOXY
	mov eax, LENGTHOF enemyposition
	mov ecx, 3
	idiv cl
	mov ecx, eax
	dec ecx
	mov ebx, 0
	
LDebug:
	mov eax, enemyposition[ebx]
	call WriteDec
	call Crlf
	add ebx, 3
	loop LDebug
	
	pop ebx
	pop eax
	pop ecx
	ret
Debug ENDP

; Draws enemies that are against the left border. PROC made to purely shorten jump distances
; Used inside DrawEnemy PROC only
DrawEnemy_LeftBorder PROC
	mov Swap, ecx  ; Quick saves number of iterations to Swap memory
	add edx, 10  ; Starts drawing from right to left
	cmp edx, 0  ; 1st Char
	jb L24
	call Get_EnemyIndex
	mov cl, "<"
	mov matriz[eax+10], cl
	dec edx
	cmp edx, 0  ; 2nd Char
	jb L24
	mov cl, ">"
	mov matriz[eax+9], cl
	dec edx
	cmp edx, 0  ; 3rd Char
	jb L24
	mov matriz[eax+8], cl
	dec edx
	cmp edx, 0  ; 4th Char
	jb L24
	mov cl, ")"
	mov matriz[eax+7], cl
	dec edx
	cmp edx, 0  ; 5th Char
	jb L24
	mov matriz[eax+6], cl
	dec edx
	cmp edx, 0  ; 6th Char
	jb L24
	mov matriz[eax+5], cl
	dec edx
	cmp edx, 0  ; 7th Char
	jb L24
	mov matriz[eax+4], cl
	dec edx
	cmp edx, 0  ; 8th Char
	jb L24
	mov matriz[eax+3], cl
	dec edx
	cmp edx, 0  ; 9th Char
	jb L24
	mov cl, "*"
	mov matriz[eax+2], cl
	dec edx
	cmp edx, 0  ; 10th Char
	jb L24
	mov cl, "<"
	mov matriz[eax+1], cl
	dec edx
	cmp edx, 0  ; 11th Char
	jb L24
	mov matriz[eax], cl
	dec edx	
	
L24:

	ret
DrawEnemy_LeftBorder ENDP
@

Draw_Enemy PROC ; Coloca antes do Create Enemy
	push eax
	push ebx
	push ecx
	push edx
	
	mov eax, nColumns  ; iteration index
	sub eax, 2
	mov ecx, nRows
	mov ebx, 0

L27:  ; Reads last element of every row
	mov bl, matriz[eax]
	cmp bl, 0
	je L28
	cmp bl, "+"
	je L28
	cmp matriz[eax-1], 0
	je State1
	cmp matriz[eax-1], ">"
	je State11
	cmp matriz[eax-1], "<"
	je State2
	cmp matriz[eax], "*"
	je State3
	cmp matriz[eax-1], "*"    ;;;;;;;;;;;;;;;;;
	je State4
	cmp matriz[eax-2], "*"
	je State5
	cmp matriz[eax-3], "*"
	je State6
	cmp matriz[eax-4], "*"
	je State7
	cmp matriz[eax-5], "*"
	je State8
	cmp matriz[eax-1], ")"
	je State9
	cmp matriz[eax-1], ">"
	je State10
	jmp L28
	
L29:  ; Jump extend
	jmp L27
State1:
	mov dl, "<"
	mov matriz[eax+1], dl
	jmp L28
State2:
	cmp matriz[eax], 0
	je L28
	cmp matriz[eax], "*"
	je State3
	mov dl, "*"
	mov matriz[eax+1], dl
	jmp L28
State3:
	mov dl, ")"
	mov matriz[eax+1], dl
	jmp L28
State4:
	mov dl, ")"
	mov matriz[eax+1], dl
	jmp L28
State5:
	mov dl, ")"
	mov matriz[eax+1], dl
	jmp L28
State6:
	mov dl, ")"
	mov matriz[eax+1], dl
	jmp L28
State7:
	mov dl, ")"
	mov matriz[eax+1], dl
	jmp L28
State8:
	mov dl, ">"
	mov matriz[eax+1], dl
	jmp L28

L30: ; Jump Extend
		jmp L29

State9:
	mov dl, ">"
	mov matriz[eax+1], dl
	jmp L28
State10:
	mov dl, "<"
	mov matriz[eax+1], dl
	jmp L28
State11:
	mov dl, ")"
	cmp matriz[eax-2], dl
	je State10
	
State12:
	mov dl, 0
	mov matriz[eax+1], dl
	
L28: ; Not Enemy
	add eax, nColumns
	loop L30
	
	pop edx 
	pop ecx
	pop ebx
	pop eax
	ret
Draw_Enemy ENDP

; Writes screen background for main screen
; NO PARAMETERS
SetMainScreen PROC
	push eax
	push ecx
	push edx
	
	mov ecx, nRows-1  ; Loop Index
	mov al, "#"
	mov edx, 0  ; Screen Index
	
L31: ; Draws Sides
	mov screen_buffer[edx], al
	add edx, nColumns-1
	mov screen_buffer[edx], al
	inc edx
	loop L31

	mov edx, 1
	mov ecx, nColumns-2

L32: ; Draws upper border
	mov screen_buffer[edx], al
	inc edx
	loop L32

	mov edx, nColumns
	mov ecx, nColumns-2
	mov eax, nRows-1
	mul dl
	mov edx, eax
	mov al, "#"
	
L33: ; Draws bottom border
	mov screen_buffer[edx], al
	inc edx
	loop L33
	mov screen_buffer[edx], al
	inc edx
	mov screen_buffer[edx], al
	
	; Draws Fishes
	mov eax, 135
	call FishBackground
	mov eax, 324 
	call FishBackground
	mov eax, 579 
	call FishBackground
	mov eax, 774
	call FishBackground
	mov ebx, 1
	mov eax, 174
	call FishBackground
	mov eax, 372 
	call FishBackground
	mov eax, 627
	call FishBackground
	mov eax, 816  
	call FishBackground
	
	
	pop edx
	pop ecx
	pop eax
	ret
SetMainScreen ENDP

; Draws text in the main screen
; NO PARAMETERS
DrawMainScreenText PROC
	push edx
	push eax
	push ecx
	push ebx
	
	; Draw Title
	mov edx, 021Ah
	call GOTOXY
	mov edx, OFFSET tTitle
	call WriteString
	
	; Draw Play
	mov dx, 061Ah
	call GOTOXY
	mov edx, OFFSET tPlay
	call WriteString

	; Draw Instructions
	mov dx, 081Ah
	call GOTOXY
	mov edx, OFFSET tInstructions
	call WriteString
	
	; Draw Difficulty
	mov dx, 0A1Ah
	call GOTOXY
	mov edx, OFFSET tDifficulty
	call WriteString
	
	; Draw Quit
	mov dx, 0C1Ah
	call GOTOXY
	mov edx, OFFSET tQuit
	call WriteString

	pop ebx
	pop ecx
	pop eax
	pop edx
	ret
DrawMainScreenText ENDP	

; Moves the selection arrow in menu
	
UpdateMenuArrow PROC
	push edx
	push eax
	push ecx
	push ebx

	; Draws Arrow
	mov al, ">"
	mov bl, MenuOption
	cmp bl, 00000001b
	je play
	cmp bl, 00000100b
	je inst
	cmp bl, 00010000b
	je diff
	cmp bl, 01000000b
	je quit
	jmp sair
	
play:
	mov dx, 0618h
	call GOTOXY
	call WriteChar
	mov al, 0
	mov dx, 0818h
	call GOTOXY
	call WriteChar
	mov dx, 0C18h
	call GOTOXY
	call WriteChar
	
	jmp sair
	
inst:
	mov dx, 0818h
	call GOTOXY
	call WriteChar	
	mov al, 0
	mov dx, 0618h
	call GOTOXY
	call WriteChar
	mov dx, 0A18h
	call GOTOXY
	call WriteChar	
	jmp sair

diff:
	mov dx, 0A18h
	call GOTOXY
	call WriteChar
	mov al, 0
	mov dx, 0818h
	call GOTOXY
	call WriteChar
	mov dx, 0C18h
	call GOTOXY
	call WriteChar	
	jmp sair

quit:
	mov dx, 0C18h
	call GOTOXY
	call WriteChar
	mov al, 0
	mov dx, 0A18h
	call GOTOXY
	call WriteChar
	mov dx, 0618h
	call GOTOXY
	call WriteChar	
	
sair:
	pop ebx
	pop ecx
	pop eax
	pop edx
	ret
UpdateMenuArrow ENDP

; Menu key detection
; NO PARAMETERS
MenuSelection PROC
	push eax
	push ebx
	push ecx
	push edx

	mov eax, 0
	call FPSRate
	call ReadKey
	jz sairFunc
	
	cmp al, "w"
	je up
	cmp al, "s"
	je down
	cmp al, "q"
	je quit2
	cmp al, " "
	je space
	jmp sairFunc

quit2:
	call SetColor_Default
	call Clrscr
	call ShowCursor
	exit
	
up:
	ror MenuOption, 2 
	call UpdateMenuArrow
	jmp sairFunc
	
down:
	rol MenuOption, 2
	call UpdateMenuArrow
	jmp sairFunc

space:
	mov bl, MenuOption
	cmp bl, 00000001b
	je play
	cmp bl, 00000100b
	je inst
	cmp bl, 00010000b
	je diff
	jmp quit
	
play:
	mov GameState, 1
	jmp sairFunc

inst:
	mov GameState, 2
	jmp sairFunc
	
diff:
	mov GameState, 3
	jmp sairFunc

quit:
	call SetColor_Default
	call Clrscr
	call ShowCursor
	exit

sairFunc:
	pop edx
	pop ecx
	pop ebx
	pop eax
	ret
MenuSelection ENDP

; Inserts "0" to all positions in screen matrix
; NO PARAMETERS
ClearMatrix PROC
	push ecx
	push edx
	
	mov edx, 0
	mov ecx, LENGTHOF matriz
L34:
	mov matriz[edx], 0
	mov screen_buffer[edx], 0
	inc edx
	cmp edx, ecx
	jne L34
	
	pop edx
	pop ecx
	ret
ClearMatrix ENDP

; Draws a fish to the background layer
; INPUT: eax = index of matriz to write; bl = if 1, writes an inverted fish.
FishBackground PROC
	push eax
	push ebx

	cmp ebx, 1
	je Inverted
	mov screen_buffer[eax], 62
	mov screen_buffer[eax+1], 60
	mov screen_buffer[eax+2], 40
	mov screen_buffer[eax+3], 40
	mov screen_buffer[eax+4], 40
	mov screen_buffer[eax+5], 167
	mov screen_buffer[eax+6], 62
	jmp quit

Inverted:
	mov screen_buffer[eax], 60
	mov screen_buffer[eax+1], 167
	mov screen_buffer[eax+2], 41
	mov screen_buffer[eax+3], 41
	mov screen_buffer[eax+4], 41
	mov screen_buffer[eax+5], 62
	mov screen_buffer[eax+6], 60
quit:
	
	pop ebx
	pop eax
	ret
FishBackground ENDP

; Writes screen borders
; NO PARAMETERS
SetScreenBorders PROC
	push eax
	push ecx
	push edx
	
	mov ecx, nRows-1  ; Loop Index
	mov al, "#"
	mov edx, 0  ; Screen Index
	
L31: ; Draws Sides
	mov screen_buffer[edx], al
	add edx, nColumns-1
	mov screen_buffer[edx], al
	inc edx
	loop L31

	mov edx, 1
	mov ecx, nColumns-2

L32: ; Draws upper border
	mov screen_buffer[edx], al
	inc edx
	loop L32

	mov edx, nColumns
	mov ecx, nColumns-2
	mov eax, nRows-1
	mul dl
	mov edx, eax
	mov al, "#"
	
L33: ; Draws bottom border
	mov screen_buffer[edx], al
	inc edx
	loop L33
	mov screen_buffer[edx], al
	inc edx
	mov screen_buffer[edx], al
	
	pop edx
	pop ecx
	pop eax
	ret
SetScreenBorders ENDP

; Draws background text in Instruction Screen
; NO PARAMETERS
DrawInstructionsText PROC
	push edx
	
	; Draw Instructions
	mov dx, 050Dh
	call GOTOXY
	mov edx, OFFSET tInst1
	call WriteString
	mov dx, 060Dh
	call GOTOXY
	mov edx, OFFSET tInst2
	call WriteString
	mov dx, 070Dh
	call GOTOXY
	mov edx, OFFSET tInst3
	call WriteString
	mov dx, 080Dh
	call GOTOXY
	mov edx, OFFSET tInst4
	call WriteString
	mov dx, 0D15h
	call GOTOXY
	mov edx, OFFSET tInst5
	call WriteString

	pop edx
	ret
DrawInstructionsText ENDP

; Draws background text in Difficulty Screen
; NO PARAMETERS
DrawDifficultyText PROC
	push edx
	
	; Draw Difficulty
	
	mov dx, 050Dh
	call GOTOXY
	mov edx, OFFSET tDif1
	cmp DifSetting, 1
	jne skip1
	call SetColor_Red
skip1:
	call WriteString
	call SetColor_Blue
	
	mov dx, 060Dh
	call GOTOXY
	mov edx, OFFSET tDif2
	cmp DifSetting, 2
	jne skip2
	call SetColor_Red
skip2:
	call WriteString
	call SetColor_Blue


	mov dx, 070Dh
	call GOTOXY
	mov edx, OFFSET tDif3
	cmp DifSetting, 3
	jne skip3
	call SetColor_Red
skip3:
	call WriteString
	call SetColor_Blue

	
	mov dx, 080Dh
	call GOTOXY
	mov edx, OFFSET tDif4
	cmp DifSetting, 4
	jne skip4
	call SetColor_Red
skip4:
	call WriteString
	call SetColor_Blue

	
	mov dx, 090Dh
	call GOTOXY
	mov edx, OFFSET tDif5
	cmp DifSetting, 5
	jne skip5
	call SetColor_Red
skip5:
	call WriteString
	call SetColor_Blue

	pop edx
	ret
DrawDifficultyText ENDP


; Waits for a key to be pressed
; NO PARAMETERS
WaitKey PROC
	push eax

	mov eax, 0
	call FPSRate
	call ReadKey
	jz sairFunc
	
	cmp al, "q"
	je quit
	cmp al, " "
	je space
	jmp sairFunc
	
quit:
	call SetColor_Default
	call Clrscr
	call ShowCursor
	exit

space:
	mov GameState, 0
	
sairFunc:
	pop eax
	ret
WaitKey ENDP

; Controls the entire Difficulty Screen
; NO PARAMETERS
SelectDifficulty PROC
	push eax
	push ebx

	mov eax, 0
	call FPSRate
	call ReadKey
	jz sairFunc

	cmp al, "w"
	je up
	cmp al, "s"
	je down	
	cmp al, "q"
	je quit
	cmp al, " "
	je space
	jmp sairFunc	
	
up:
	cmp DifSetting, 1
	jne skip
	mov DifSetting, 5
	jmp continue
	skip:
	mov eax, DifSetting
	dec eax
	mov DifSetting, eax
	jmp continue
	
down:
	cmp DifSetting, 5
	jne skip2
	mov DifSetting, 1
	jmp continue
	skip2:
	mov eax, DifSetting
	inc eax
	mov DifSetting, eax
	jmp continue	

	; Write Arrow
continue:
	mov al, ">"
	mov ebx, DifSetting
	cmp bl, 1
	je easy
	cmp bl, 2
	je med
	cmp bl, 3
	je hard
	cmp bl, 4
	je pro
	jmp prozera
	
easy:
	mov dx, 050bh
	call GOTOXY
	call WriteChar
	mov al, 0
	mov dx, 060bh
	call GOTOXY
	call WriteChar
	mov dx, 090bh
	call GOTOXY
	call WriteChar
	
	jmp sairFunc

med:
	mov dx, 060bh
	call GOTOXY
	call WriteChar
	mov al, 0
	mov dx, 070bh
	call GOTOXY
	call WriteChar
	mov dx, 050bh
	call GOTOXY
	call WriteChar
	
	jmp sairFunc

hard:
	mov dx, 070bh
	call GOTOXY
	call WriteChar
	mov al, 0
	mov dx, 080bh
	call GOTOXY
	call WriteChar
	mov dx, 060bh
	call GOTOXY
	call WriteChar
	
	jmp sairFunc

pro:
	mov dx, 080bh
	call GOTOXY
	call WriteChar
	mov al, 0
	mov dx, 070bh
	call GOTOXY
	call WriteChar
	mov dx, 090bh
	call GOTOXY
	call WriteChar
	
	jmp sairFunc

prozera:
	mov dx, 090bh
	call GOTOXY
	call WriteChar
	mov al, 0
	mov dx, 080bh
	call GOTOXY
	call WriteChar
	mov dx, 050bh
	call GOTOXY
	call WriteChar
	jmp sairFunc
	
quit:
	call SetColor_Default
	call Crlf
	Call ShowCursor
	exit
	
	; Space key log

space:
	cmp DifSetting, 1
	je KeyE
	cmp DifSetting, 2
	je KeyM
	cmp DifSetting, 3
	je KeyH
	cmp DifSetting, 4
	je KeyP
	jmp KeyPZ
	
KeyE:
	mov difficulty, 20
	mov foodwaitingtime, 40
	mov GameState, 0
	jmp sairFunc
KeyM:
	mov difficulty, 15
	mov foodwaitingtime, 30
	mov GameState, 0
	jmp sairFunc
KeyH:
	mov difficulty, 10
	mov foodwaitingtime, 20
	mov GameState, 0
	jmp sairFunc
KeyP:
	mov difficulty, 5
	mov foodwaitingtime, 10
	mov GameState, 0
	jmp sairFunc
KeyPZ:
	mov difficulty, 2
	mov foodwaitingtime, 5
	mov GameState, 0
	
sairFunc:
	pop ebx
	pop eax
	ret
SelectDifficulty ENDP

; Draws background text in Game Over Screen
; NO PARAMETERS
DrawGameOver PROC
	push edx
	
	; Draw Texts
	
	mov dx, 0612h
	call GOTOXY
	mov edx, OFFSET tGO1
	call WriteString
	
	mov dx, 0A12h
	call GOTOXY
	mov edx, OFFSET tGO2
	call WriteString

	mov eax, score
	call WriteDec
	
	pop edx
	ret
DrawGameOver ENDP

; Hides terminal cursor
; NO PARAMETERS
HideCursor PROC

	invoke GetStdHandle,STD_OUTPUT_HANDLE
	mov chand,eax
	invoke GetConsoleCursorInfo,chand,addr cci
	mov cci.bVisible,FALSE
	ret
HideCursor ENDP

; Hides terminal cursor
; NO PARAMETERS
ShowCursor PROC

	invoke GetStdHandle,STD_OUTPUT_HANDLE
	mov chand,eax
	invoke GetConsoleCursorInfo,chand,addr cci
	mov cci.bVisible,TRUE
	ret
ShowCursor ENDP

; MAIN EXECUTION FLOW
main PROC
	call HideCursor
	call Clrscr
	call Randomize
	call SetColor_Default
	call SetColor_Blue
	
MainLoop:  ; Main screen Loop
	call SetMainScreen
	call DrawScreen
	call FixCursor
	call DrawMainScreenText
	call UpdateMenuArrow
MenuLoop:
	call TickRate
	call MenuSelection
	call FixCursor
	
	cmp GameState, 0  ; Switches to another screen if not in main menu state anymore
	jne LoadScreen
	
	jmp MenuLoop

InstructionLoop:  ; Instructions screen loop
	call SetScreenBorders
	call DrawScreen
	call DrawInstructionsText

HelpLoop:	
	call FPSRate
	call WaitKey
	
	cmp GameState, 2
	jne LoadScreen
	
	jmp HelpLoop
	
DifficultyLoop:   ; Difficulty screen loop
	call SetScreenBorders
	call DrawScreen
	call DrawDifficultyText
	
ProLoop:
	call SelectDifficulty
	call FixCursor
	call FPSRate
	
	cmp GameState, 3
	jne LoadScreen
	
	jmp ProLoop
	
GameOverLoop:  ; Gameover Screen loop
	call SetColor_Default
	call Clrscr
	call SetColor_Blue
	call FixCursor
	call ClearMatrix
	call SetScreenBorders
	call DrawScreen
	call DrawGameOver
	call FixCursor
Overloop:
	call FPSRate
	call ReadKey
	jnz Restart
	jmp Overloop
	
Restart:
	mov score, 0
	mov GameState, 0
	mov player_x, 6
	mov player_y, 6
	jmp LoadScreen
	
	
LoadScreen:  ; Transition between screens
	call FixCursor
	call ClearMatrix
	mov ebx, 0
	cmp GameState, 1
	je GameLoop
	cmp GameState, 0
	je MainLoop
	cmp GameState, 2
	je InstructionLoop
	cmp GameState, 3
	je DifficultyLoop
	cmp GameState, 4
	je GameOverLoop
	jmp MainLoop
	
GameLoop:  ; In-game loop
	call HideCursor
	call Clear
	call HoldCursor
	call CreateFood
	call DrawHeader
	call HoldCursor
	call Draw_Enemy
	call HoldCursor
	call CreateEnemy
	call HoldCursor
	call DrawFish
	call HoldCursor
	call DrawScreen
	call HoldCursor
	call HideCursor
	call FPSRate
	call Shift
	call HoldCursor
	call Move
	call HoldCursor
	call Collision
	call HoldCursor
	
	cmp GameState, 1 ; Switches to another screen if not on the in-game state anymore
	jne LoadScreen
	jmp GameLoop
main ENDP
END main
