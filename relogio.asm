segment code
..start:
    mov 	ax,data
    mov 	ds,ax
    mov 	ax,stack
    mov 	ss,ax
    mov 	sp,stacktop

	; salvar modo atual de video
	mov  		ah,0Fh
	int  		10h
	mov  		[modo_anterior],al   

	; alterar modo de video para gráfico 640x480 16 cores
	mov     	al,12h
	mov     	ah,0
	int     	10h
	; preparando relogio
	XOR 	AX, AX
    MOV 	ES, AX
    MOV     AX, [ES:intr*4];carregou AX com offset anterior
    MOV     [offset_dos], AX        ; offset_dos guarda o end. para qual ip de int 9 estava apontando anteriormente
    MOV     AX, [ES:intr*4+2]     ; cs_dos guarda o end. anterior de CS
    MOV     [cs_dos], AX
    CLI     
    MOV     [ES:intr*4+2], CS
    MOV     WORD [ES:intr*4],relogio
    STI

l1:
	cmp 	byte [tique], 0
	jne 	ab
	call 	converte
ab: mov 	ah,0bh		
    int 	21h			; Le buffer de teclado
    cmp 	al,0
    jne 	fim	
    jmp 	l1
fim:
	mov  	AH, 0   					; set video mode
	mov  	AL, [modo_anterior]   		; modo anterior
	int  	10h
	CLI
    XOR     AX, AX
    MOV     ES, AX
    MOV     AX, [cs_dos]
    MOV     [ES:intr*4+2], AX
    MOV     AX, [offset_dos]
    MOV     [ES:intr*4], AX
	mov     AX, 4C00H
	int     21h

relogio:
	push	ax
	push	ds
	mov     ax,data	
	mov     ds,ax	
    
    inc	byte [tique]
    cmp	byte[tique], 18	
    jb		Fimrel
	mov byte [tique], 0
	inc byte [segundo]
	cmp byte [segundo], 60
	jb   	Fimrel
	mov byte [segundo], 0
	inc byte [minuto]
	cmp byte [minuto], 60
	jb   	Fimrel
	mov byte [minuto], 0
	inc byte [hora]
	cmp byte [hora], 24
	jb   	Fimrel
	mov byte [hora], 0	
Fimrel:
    mov		al,20h
	out		20h,al
	pop		ds
	pop		ax
	iret
	
converte:
    push 	ax
	push    ds
	mov     ax, data
	mov     ds, ax
	xor 	ah, ah
	MOV     BL, 10
	mov 	al, byte [segundo]
    DIV     BL
    ADD     AL, 30h                                                                                          
    MOV     byte [horario+6], AL
    ADD     AH, 30h
    mov 	byte [horario+7], AH
    
	xor 	ah, ah
	mov 	al, byte [minuto]
    DIV     BL
    ADD     AL, 30h                                                                                          
    MOV     byte [horario+3], AL
    ADD     AH, 30h
    mov 	byte [horario+4], AH
	
	xor 	ah, ah
	mov 	al, byte [hora]
    DIV     BL
    ADD     AL, 30h                                                                                          
    MOV     byte [horario], AL
    ADD     AH, 30h
    mov 	byte [horario+1], AH

	; ESCRECVE HORARIO (00:00:00)
	mov     	cx,8			;numero de caracteres
	mov     	bx,0
	mov     	dh,14			;linha 0-29
	mov     	dl,35			;coluna 0-79
	mov			byte[cor], verde
	l_w_horario:
		call	cursor
		mov     al,[bx+horario]
		call	caracter
		inc     bx			;proximo caracter
		inc		dl			;avanca a coluna
		loop    l_w_horario

	pop     ds
	pop     ax
	ret  

;***************************************************************************
;
;   funcao cursor
;
; dh = linha (0-29) e  dl=coluna  (0-79)
cursor:
		pushf
		push 		ax
		push 		bx
		push		cx
		push		dx
		push		si
		push		di
		push		bp
		mov     	ah,2
		mov     	bh,0
		int     	10h
		pop		bp
		pop		di
		pop		si
		pop		dx
		pop		cx
		pop		bx
		pop		ax
		popf
		ret
;_____________________________________________________________________________
;
;   fun��o caracter escrito na posi��o do cursor
;
; al= caracter a ser escrito
; cor definida na variavel cor
caracter:
		pushf
		push 		ax
		push 		bx
		push		cx
		push		dx
		push		si
		push		di
		push		bp
    	mov     	ah,9
    	mov     	bh,0
    	mov     	cx,1
   		mov     	bl,[cor]
    	int     	10h
		pop		bp
		pop		di
		pop		si
		pop		dx
		pop		cx
		pop		bx
		pop		ax
		popf
		ret
;_____________________________________________________________________________


segment data
	cor		db		branco_intenso	;	I R G B COR
	preto			equ		0		;	0 0 0 0 preto
	azul			equ		1		;	0 0 0 1 azul
	verde			equ		2		;	0 0 1 0 verde
	cyan			equ		3		;	0 0 1 1 cyan
	vermelho		equ		4		;	0 1 0 0 vermelho
	magenta			equ		5		;	0 1 0 1 magenta
	marrom			equ		6		;	0 1 1 0 marrom
	branco			equ		7		;	0 1 1 1 branco
	cinza			equ		8		;	1 0 0 0 cinza
	azul_claro		equ		9		;	1 0 0 1 azul claro
	verde_claro		equ		10		;	1 0 1 0 verde claro
	cyan_claro		equ		11		;	1 0 1 1 cyan claro
	rosa			equ		12		;	1 1 0 0 rosa
	magenta_claro	equ		13		;	1 1 0 1 magenta claro
	amarelo			equ		14		;	1 1 1 0 amarelo
	branco_intenso	equ		15		;	1 1 1 1 branco intenso

	eoi     		EQU 	20h
    intr	   		EQU 	08h
	modo_anterior	db		0
	char			db		0
	offset_dos		dw		0
	cs_dos			dw		0
	tique			db  	0
	segundo			db  	0
	minuto 			db  	0
	hora 			db  	0
	horario			db  	0,0,':',0,0,':',0,0,' ', 13,'$'
segment stack stack
    resb 256
stacktop:
