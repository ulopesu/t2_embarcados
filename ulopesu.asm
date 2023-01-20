; Trabalho de Sistemas Embarcados I
; Usiel Ferreira Lopes Junior
; 2022/1
; Turma: 06.1

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
	call 	textos_fixos

l1:
	call  	ajustar_horas
	cmp 	byte [tique], 0
	jne 	ler_teclado
	call 	converte

ler_teclado:
	mov 	ah,0bh		
    int 	21h			; Le buffer de teclado
    cmp 	al,0
	je		l1			; nenhuma telha -> loop principal
	mov 	ah, 08
	int 	21h
	cmp		al, 'x'		; tecla x -> finaliza o programa
	je      fim
	cmp		al, 's'		; tecla s -> configura os segundos
	je      config_seg
	cmp		al, 'm'		; tecla m -> configura os minutos
	je      config_min
	cmp		al, 'h'		; tecla h -> configura as horas
	je      config_hrs
	jmp 	l1			; outras teclas -> loop principal

limpa_seg:
	mov byte [segundo], 0
	jmp ajustar_horas

limpa_min:
	mov byte [minuto], 0
	jmp ajustar_horas

limpa_hrs:
	mov byte [hora], 0
	jmp ajustar_horas

ajustar_horas:
	cmp byte [segundo], 60
	jnl	limpa_seg
	cmp byte [minuto], 60
	jnl	limpa_min
	cmp byte [hora], 24
	jnl	limpa_hrs
	ret

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

config_seg:
	call 	desenha_select_seg
	call 	ler_nums
	call 	w_seg
	call 	apaga_select
	jmp 	l1

config_min:
	call 	desenha_select_min
	call 	ler_nums
	call 	w_min
	call 	apaga_select
	jmp 	l1

config_hrs:
	call	desenha_select_hrs
	call 	ler_nums
	call 	w_hora
	call 	apaga_select
	jmp 	l1

ler_nums:		; 	Lê dois números
	xor cx, cx
	loop_ler_nums
		mov 	ah,0bh		
		int 	21h			; Le buffer de teclado
		cmp 	al, 0
		je		loop_ler_nums			; nenhuma telha -> loop principal
		call 	verificar_tecla
		cmp cx, 2
		jne loop_ler_nums
	ret

w_n1:
	mov byte[n1], dl
	ret

w_n2:
	mov byte[n2], dl
	ret

ler_num:
	inc cx
	mov dl, al
	sub dl, 30h
	cmp cx, 1
	je 	w_n1
	cmp cx, 2
	je 	w_n2
	ret

verificar_tecla:
	mov 	ah, 08
	int 	21h
	cmp		al, '0'
	je		ler_num
	cmp		al, '1'
	je		ler_num
	cmp		al, '2'
	je		ler_num
	cmp		al, '3'
	je		ler_num
	cmp		al, '4'
	je		ler_num
	cmp		al, '5'
	je		ler_num
	cmp		al, '6'
	je		ler_num
	cmp		al, '7'
	je		ler_num
	cmp		al, '8'
	je		ler_num
	cmp		al, '9'
	je		ler_num
	ret

pega_num:
	xor ax, ax
	mov al, byte[n1]
	mov cx, 10
	mul cx
	add al, byte[n2]
	ret

w_hora:
	call 	pega_num
	mov 	byte[hora], al
	ret

w_min:
	call 	pega_num
	mov 	byte[minuto], al
	ret

w_seg:
	call 	pega_num
	dec 	al
	mov 	byte[segundo], al
	ret

apaga_select:
	mov     	cx, 8					;numero de caracteres
	mov     	bx, 0
	mov     	dh, 15					;linha 0-29
	mov     	dl, 39					;coluna 0-79
	mov			byte[cor], preto
	loop_apaga_select:
		call	cursor
		mov     al, ' '
		call	caracter
		inc     bx			;proximo caracter
		inc		dl			;avanca a coluna
		loop    loop_apaga_select
	ret

desenha_select_seg:
	mov     dh, 15						;linha 0-29
	mov     dl, 46						;coluna 0-79
	mov		byte[cor], verde_claro
	call	cursor
	mov     al, 35
	call	caracter
	mov     dl, 45						;coluna 0-79
	call	cursor
	mov     al, 35
	call	caracter
	ret

desenha_select_min:
	mov     dh, 15						;linha 0-29
	mov     dl, 43						;coluna 0-79
	mov		byte[cor], verde_claro
	call	cursor
	mov     al, 35
	call	caracter
	mov     dl, 42						;coluna 0-79
	call	cursor
	mov     al, 35
	call	caracter
	ret

desenha_select_hrs:
	mov     dh, 15						;linha 0-29
	mov     dl, 40						;coluna 0-79
	mov		byte[cor], verde_claro
	call	cursor
	mov     al, 35
	call	caracter
	mov     dl, 39						;coluna 0-79
	call	cursor
	mov     al, 35
	call	caracter
	ret

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

	; ESCREVE HORARIO (00:00:00)
	call escreve_horario

	pop     ds
	pop     ax
	ret  

textos_fixos:
	call escreve_textohora
	call escreve_alunoturma
	call escreve_titulomenu
	call escreve_textox
	call escreve_textoseg
	call escreve_textomin
	call escreve_textohrs
	ret

escreve_horario:
	mov word[num_chars], 8
	mov byte[linha_str], 14
	mov byte[coluna_str], 39
	xor bx, bx
	loop_cp_horario:
		mov al, byte[horario + bx]
		mov byte[main_str + bx], al
		inc bx
		cmp bx, word[num_chars]
		jl loop_cp_horario
	call escreve_str
	ret

escreve_textohora:
	mov word[num_chars], 5
	mov byte[linha_str], 14
	mov byte[coluna_str], 33
	xor bx, bx
	loop_cp_textohora:
		mov al, byte[texto_hora + bx]
		mov byte[main_str + bx], al
		inc bx
		cmp bx, word[num_chars]
		jl loop_cp_textohora
	call escreve_str
	ret

escreve_alunoturma:
	mov word[num_chars], 52
	mov byte[linha_str], 2
	mov byte[coluna_str], 13
	xor bx, bx
	loop_cp_alunoturma:
		mov al, byte[aluno_turma + bx]
		mov byte[main_str + bx], al
		inc bx
		cmp bx, word[num_chars]
		jl loop_cp_alunoturma
	call escreve_str
	ret

escreve_titulomenu:
	mov word[num_chars], 15
	mov byte[linha_str], 22
	mov byte[coluna_str], 32
	xor bx, bx
	loop_cp_titulomenu:
		mov al, byte[titulo_menu + bx]
		mov byte[main_str + bx], al
		inc bx
		cmp bx, word[num_chars]
		jl loop_cp_titulomenu
	call escreve_str
	ret

escreve_textox:
	mov word[num_chars], 7
	mov byte[linha_str], 24
	mov byte[coluna_str], 17
	xor bx, bx
	loop_cp_textox:
		mov al, byte[texto_x + bx]
		mov byte[main_str + bx], al
		inc bx
		cmp bx, word[num_chars]
		jl loop_cp_textox
	call escreve_str
	ret

escreve_textoseg:
	mov word[num_chars], 53
	mov byte[linha_str], 25
	mov byte[coluna_str], 17
	xor bx, bx
	loop_cp_textoseg:
		mov al, byte[texto_s + bx]
		mov byte[main_str + bx], al
		inc bx
		cmp bx, word[num_chars]
		jl loop_cp_textoseg
	call escreve_str
	ret

escreve_textomin:
	mov word[num_chars], 52
	mov byte[linha_str], 26
	mov byte[coluna_str], 17
	xor bx, bx
	loop_cp_textomin:
		mov al, byte[texto_m + bx]
		mov byte[main_str + bx], al
		inc bx
		cmp bx, word[num_chars]
		jl loop_cp_textomin
	call escreve_str
	ret

escreve_textohrs:
	mov word[num_chars], 50
	mov byte[linha_str], 27
	mov byte[coluna_str], 17
	xor bx, bx
	loop_cp_textohrs:
		mov al, byte[texto_h + bx]
		mov byte[main_str + bx], al
		inc bx
		cmp bx, word[num_chars]
		jl loop_cp_textohrs
	call escreve_str
	ret

escreve_str:
	mov     	cx, word[num_chars]						;numero de caracteres
	mov     	bx, 0
	mov     	dh, byte[linha_str]						;linha 0-29
	mov     	dl, byte[coluna_str]					;coluna 0-79
	mov			byte[cor], branco_intenso
	loop_escreve_str:
		call	cursor
		mov     al, byte[bx+main_str]
		call	caracter
		inc     bx			;proximo caracter
		inc		dl			;avanca a coluna
		loop    loop_escreve_str
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
	; CONFIGURAÇÃO PARA ALTERAR HORÁRIO
	select_smh		db		0		; 	0->nenhum, 1->segundos, 2->minutos, 3->horas
	n1				db		0
	n2				db		0
	; CONFIGURAÇÃO PARA STRING GENERICA
	num_chars		dw		0
	linha_str		db		0
	coluna_str		db		0
	main_str		times 	500		db	0

	; CONFIGURAÇÃO DE CORES
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
	texto_hora    	db  	'Hora:'													; 5 caracteres
	horario			db  	0,0,':',0,0,':',0,0,' ', 13,'$'							; 8 caracteres
	aluno_turma    	db  	'TL_2022/2 - Usiel Ferreira Lopes Junior - Turma 06.1' 	; 52 caracteres
	titulo_menu    	db  	'Menu de teclas:'										; 15 caracteres
	texto_x    		db  	'x: sair'												; 7 caracteres
	texto_s    		db  	's: para o contador dos segundos e aguarda novo valor.'	; 53 caracteres
	texto_m    		db  	'm: para o contador dos minutos e aguarda novo valor.'	; 52 caracteres
	texto_h    		db  	'h: para o contador das horas e aguarda novo valor.'	; 50 caracteres
segment stack stack
    resb 256
stacktop:
