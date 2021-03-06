; Test

Include ..\Irvine32.inc

.data
	matriz BYTE 01h, 12 dup(00h), 01h , 00h, 01h
	carry BYTE ?
	player_x DWORD ?  ; 0-15
	player_y DWORD ?  ; 0-7

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
; Moves all elements in an array to the left and puts the first one into the last
Shift PROC
	push ecx
	push eax
	push ebx
	push edx
	mov ecx, LENGTHOF matriz
	dec ecx
	mov ebx, 0
	mov edx, 1
	mov al, matriz[0]

L1:	
	mov al, matriz[edx]
	mov matriz[ebx], al
	inc ebx
	inc edx
	cmp ebx, ecx
	jne L1
	
	mov al, 0
	mov matriz[ecx], al
	
	pop edx
	pop ebx
	pop eax
	pop ecx
	ret
Shift ENDP

WriteArray PROC
	push ecx
	push eax
	push edx
	
	mov edx, 0
	mov ecx, LENGTHOF matriz
L2:
	movzx eax, matriz[edx]
	call WriteInt
	call Crlf
	inc edx
	cmp edx, ecx
	jne L2
	
	pop edx
	pop eax
	pop ecx
	ret
WriteArray ENDP

main PROC
	call Shift
	call WriteArray

	call ReadChar

	exit
main ENDP
END main
