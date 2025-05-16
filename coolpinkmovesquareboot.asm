[ORG 0x7c00]
	jmp start
%include "print.inc"
;------------------------------------
start:
	xor ax,ax
	mov ds,ax
	mov ss,ax
	mov sp,0x9c00
	mov ax,0xb800
	mov es,ax

	cli
	mov bx,0x09*4	;address of default keyboard interrupt hdler
	xor ax,ax
	mov gs,ax	;start of memory
	mov word[gs:bx],word keyhandler	;swap that hdler for keyhandler
	mov word[gs:bx+2],ds	;segment of keyhandler
	sti
	
	call paint_square

runloop:
	cmp word[port0x60],0x48
	je .up_arrow
	cmp word[port0x60],0x4B
	je .left_arrow
	cmp word[port0x60],0x4D
	je .right_arrow
	cmp word[port0x60],0x50
	je .down_arrow
	cmp word[port0x60],0x1F
	je .s_key
.reset_port:	mov word[port0x60],0
	jmp runloop

.up_arrow:
	cmp byte[trail_flag],0
	jnz .pink_up
	mov word[sq_color],0x0020
	call paint_square
.pink_up:
	sub byte[sq_ypos],1
	mov word[sq_color],0xDD20
	call paint_square
	jmp .reset_port
.down_arrow:
	cmp byte[trail_flag],0
	jnz .pink_down
	mov word[sq_color],0x0020
	call paint_square
.pink_down:
	add byte[sq_ypos],1
	mov word[sq_color],0xDD20
	call paint_square
	jmp .reset_port
.left_arrow:
	cmp byte[trail_flag],0
	jnz .pink_left
	mov word[sq_color],0x0020
	call paint_square
.pink_left:
	sub byte[sq_xpos],1
	mov word[sq_color],0xDD20
	call paint_square
	jmp .reset_port
.right_arrow:
	cmp byte[trail_flag],0
	jnz .pink_right
	mov word[sq_color],0x0020
	call paint_square
.pink_right:
	add byte[sq_xpos],1
	mov word[sq_color],0xDD20
	call paint_square
	jmp .reset_port
.s_key:
	not byte[trail_flag]
	jmp .reset_port
;-----------------------------------------
keyhandler:
	in al,0x60	;keyboard port	
	mov bl,al	;store keypress in bl
	mov byte[port0x60],al

	in al,0x61
	mov ah,al
	or al,0x80	;disable bit 7
	out 0x61,al
	xchg ah,al
	out 0x61,al

	mov al,0x20	;End of interrupt (EOI) command code
	out 0x20,al	;send EOI to master PIC command port

	and bl,0x80
	jnz .done

	mov al,byte[port0x60]
	mov byte[reg16],al
	call printreg16
.done:
	iret
;-----------------------------------------
paint_square:
.check_ypos:
	cmp byte[sq_ypos],0	;if past top of screen
	jl .reset_y_top
	cmp byte[sq_ypos],25	;if past bottom of screen
	jl .check_xpos
	mov byte[sq_ypos],24
.check_xpos:
	cmp byte[sq_xpos],0	;if past left edge
	jle .reset_x_left
	cmp byte[sq_xpos],80	;if past right edge
	jl .update_sq_pos
	mov byte[sq_xpos],79
	
.update_sq_pos:
	movzx ax,byte[sq_ypos]
	mov dx,80*2
	mul dx
	movzx bx,byte[sq_xpos]
	shl bx,1
	mov di,ax
	shl dx,4
	add di,dx
	add di,bx
	mov ax,word[sq_color]
	stosw
	ret

.reset_y_top:
	mov byte[sq_ypos],0
	jmp .check_xpos
.reset_x_left:
	mov byte[sq_xpos],0
	jmp .update_sq_pos
;------------------------------------
port0x60:	dw 0
sq_xpos:	db 20
sq_ypos:	db 0
sq_color:	dw 0xDD20
trail_flag:	db 0

	times 510-($-$$) db 0
	db 0x55
	db 0xAA
