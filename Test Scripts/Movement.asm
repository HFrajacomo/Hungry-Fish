; Test

Include ..\Irvine32.inc
Include ..\win32.inc
nColumns = 64
nRows = 16

.data
	matriz BYTE nColumns*nRows dup(00h)
	
	screen_buffer BYTE nColumns*nRows dup(0)
	carry BYTE ?
	player_x DWORD 6  ; 6-62  // 0 - 63
	player_y DWORD 0  ; 0-31
	foodwaitingtime DWORD 30
	score DWORD 0

	tScore BYTE "Score: ", 0
	
	
	
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
	
	; Posiciona o cursor após o header
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
	sub ebx, 1
	mov player_x, ebx
	jmp sair

right:
	mov ebx, player_x
	cmp ebx, nColumns-1
	jae sair
	add ebx, 1
	mov player_x, ebx
	jmp sair

up:
	mov ebx, player_y
	cmp ebx, 0
	jbe sair
	sub ebx, 1
	mov player_y, ebx
	jmp sair

down:
	mov ebx, player_y
	cmp ebx, nRows-1
	jae sair
	add ebx, 1
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
	call SetColor_Red
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
	cmp matriz[eax-1], 0
	inc ebx
	ja L11
	cmp matriz[eax-2], 0
	inc ebx
	ja L11
	cmp matriz[eax-3], 0
	inc ebx
	ja L11
	cmp matriz[eax-4], 0
	inc ebx
	ja L11
	cmp matriz[eax-5], 0
	inc ebx
	ja L11
	cmp matriz[eax-6], 0
	inc ebx
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

EnemyHit:  ; Collided to enemy

L12:  ; Didn't Collide	
	pop ebx
	pop eax
	ret
Collision ENDP

; Reads player x and y information and returns the position index on the screen
; RETURNS: eax = matriz index value
Get_Index PROC
	
	mov eax, player_y
	shl eax, 6
	add eax, player_x
	
	ret
Get_Index ENDP

main PROC
	call Clrscr
	call Randomize
	call SetColor_Blue
las:
	call Clear
	call CreateFood
	call DrawFish
	call DrawHeader
	call DrawScreen
	call FixCursor
	call FPSRate
	call Shift
	call Collision
	call Move
	jmp las
	
	exit
main ENDP
END main
