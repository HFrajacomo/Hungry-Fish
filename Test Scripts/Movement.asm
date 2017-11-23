; Test

Include ..\Irvine32.inc
Include ..\win32.inc
nColumns = 64
nRows = 16

.data
	matriz BYTE nColumns*nRows dup(00h)
	screen_buffer BYTE nColumns*nRows dup(0)
	
	carry BYTE ?
	
	Swap DWORD 0
	
	player_x DWORD 6  ; 6-62  // 0 - 63
	player_y DWORD 0  ; 0-31
	foodwaitingtime DWORD 30  ; 40 - Easy, 30 - Medium, 20 - Hard, 10 - Pro
	score DWORD 0
	difficulty DWORD 5  ; 20 - Easy, 15 - Medium, 10 - Hard, 5 - Pro
	enemytimer DWORD 20
	enemyposition DWORD 30 dup(0)
	
	tScore BYTE "Score: ", 0
	
									; <<*)))))>><  11 char long
	
	                               ; ><(((ยบ>     
								   
								   ; Ascii Characters
								   ; > = 62
								   ; < = 60
								   ; ( = 40
								   ; ยบ = 167
								   ; * = 42
								   ; + = 43

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
	call GameCursor
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
	cmp dx, 4200h
	je L6
L6:
	
	pop edx
	pop ebx
	pop ecx
	pop eax
	ret
Clear ENDP

; Fixes cursor glitching all around the screen
; NO PARAMETERS
FixCursor PROC
	push edx
	
	mov edx, 0
	call GOTOXY
	
	pop edx
	ret
FixCursor ENDP

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

	mov eax, red+(black*16)
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
	
	; Draws Scoreboard
	call FixCursor
	call SetColor_Default
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
	call SetColor_Default
	call Clrscr
	exit

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



main PROC
	call Clrscr
	call Randomize
	call SetColor_Blue
mLoop:
	call Clear
	call CreateFood
	call DrawHeader
	call Draw_Enemy
	call CreateEnemy
	call DrawFish
	call DrawScreen
	call FixCursor
	call FPSRate
	call Shift
	call Collision
	call Move
	jmp mLoop
	
	exit
main ENDP
END main
