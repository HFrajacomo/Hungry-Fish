; Test

Include ..\Irvine32.inc
Include ..\win32.inc

.data
	matriz BYTE 32*16 dup(00h)
	
	screen_buffer BYTE 32*16 dup(0)
	carry BYTE ?
	player_x DWORD 10  ; 6-30  // 0 - 31
	player_y DWORD 14  ; 0-31
	
	
	
	                               ; ><(((º>     
								   
								   ; Ascii Characters
								   ; > = 62
								   ; < = 60
								   ; ( = 40
								   ; º = 167
								   ; * = 42
								   ; + = 43

.code

; NO PARAMETER! ecx is size of array, eax is the carry variable and ebx is length of array constant
; Moves all elements in an array to the left and puts the first one into the last
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

; NO PARAMETER!
; Moves all elements in an array to the left
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
	mov matriz[31], 0 
	mov matriz[63], 0
	mov matriz[95], 0
	mov matriz[127], 0
	mov matriz[159], 0
	mov matriz[191], 0
	mov matriz[223], 0
	mov matriz[255], 0
	
	pop edx
	pop ebx
	pop eax
	pop ecx
	ret
Shift ENDP


DrawScreen PROC
	push ecx
	push eax
	push edx
	push ebx
	
	mov edx, 16  ; Screen y Size
	mov ebx, 0
L3:
	mov ecx, 32
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
	
	mov eax, 32 ; Find Player position
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

Tickrate PROC
	push eax
	mov eax, 50
	call delay
	pop eax
	ret
Tickrate ENDP

FPSRate PROC
	push eax
	mov eax, 40
	call delay
	pop eax
	ret
FPSRate ENDP

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
	jmp sair
	
left:
	mov ebx, player_x
	cmp ebx, 6
	jbe sair
	dec ebx
	mov player_x, ebx
	jmp sair

right:
	mov ebx, player_x
	cmp ebx, 30
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
	cmp ebx, 16
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

; Zera o buffer da tela
Clear PROC
	push eax
	push ecx
	push ebx
	
	mov ecx, LENGTHOF screen_buffer
	mov al, " "
	mov ebx, 0
L5:
	mov screen_buffer[ebx], al
	inc ebx
	cmp ebx, ecx
	jne L5
	
	pop ebx
	pop ecx
	pop eax
	ret
Clear ENDP

main PROC
las:
	call Clrscr
	call DrawFish
	call DrawScreen
	;call TickRate
	call Move
	call Shift
	jmp las

	exit
main ENDP
END main
