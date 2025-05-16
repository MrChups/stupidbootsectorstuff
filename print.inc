goto_cprint:	call cprint
sprint:
	lodsb
	cmp al,0	;if the char is the NB
	jnz goto_cprint
.movecursor:
	mov al,byte[xinterm]
	mov byte[xpos],al	;move cursor's xpos to xinterm 
	add byte[ypos],1	;move cursor 1 line down
	ret

cprint:
	mov ah,0x1F	;white text, blue BG
	push ax		;free ax up for the mul instruction
	movzx ax,byte[ypos]
	mov dx,80*2	;80 cols*2 bytes/col
	mul dx
	shl dx,4	
	movzx bx,byte[xpos]
	shl bx,1

	mov di,0	;topleft of screen
	add di,ax	;go to ypos,xpos=0
	add di,dx
	add di,bx	;go to xpos
	
	pop ax		;restore char/attrib into ax
	stosw		;place it in the specified screen position
	
	add byte[xpos],1	;cursor 1 space to the right
	ret

printreg16:
	mov di,outregstr16
	mov ax,word[reg16]
	mov si,ASCII_CONV
	mov cx,4
.hexloop:	;Stores ASCII representation of reg16 in outregstr16
	rol ax,4
	mov bx,ax
	and bx,0x0F
	mov bl,byte[si+bx]
	mov byte[di],bl
	inc di
	loop .hexloop
;print outregstr16
	cmp byte[ypos],25	;when cursor hits bottom
	jl .printreg
	cmp byte[xpos],75	;when cursor hits right edge
	jge .resetcursor
	add byte[xinterm],5	;move move cursor 5 spaces right
.updatecursor:
	mov al,byte[xinterm]
	mov byte[xpos],al
	mov byte[ypos],0
.printreg:
	mov si,outregstr16
	call sprint
	ret
.resetcursor:
	mov byte[xinterm],0
	jmp .updatecursor
;---------------------------------
xpos: db 0
xinterm: db 0
ypos: db 0
outregstr16: db '0000',0	;for storing ASCII representation of reg16
reg16: dw 0	;for storing the value of a register
ASCII_CONV: db '0123456789ABCDEF'	;for converting values to ASCII
