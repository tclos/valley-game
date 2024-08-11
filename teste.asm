;---------------MODELO SIMPLIFICADO
		.model small
		.stack 
CR		equ		13
LF		equ		10

;---------------DADOS			
		.data

buffer db 60 dup('O')
endbuf db CR, LF, '$'
left	   db 20
largura      db 20 
shipPos    db 30
x	db 10
score db 0
dificulade_count db 0

f db 0
;---------------CODIGO
		.code
		.startup
		
;---------------INIT
		mov ax, ds		;inicializa o segmento de extradata igual ao segmento data
		mov es, ax
		

again:
		; Introduz um delay para diminuir a velocidade do jogo
		call delay		
		call delay
		call delay
	
		
		;preencher o vale com 'O' antes
		mov	al,'O'
		mov cx, 60		;nao funciona provavelmente, pq w é 8 e cx 16	
		lea DI,buffer
		rep stosb
		
		;Atualiza posicao dos vales
		call update_valley_position
		;call move_test
		
		; Desenha o vale
		call desenha_jogo
		
		; Desenha a nave
		;call desenha_nave
		
		

		; Captura a tecla pressionada diretamente
		in al, 60h            ; Read from keyboard port
		test al, 80h          ; Check if a key is pressed (highest bit is 1 if released)
		jnz again    ; If bit is set, the key has been released, so skip

		; Process only if key is being pressed down
		and al, 7Fh           ; Clear the highest bit to get the actual key code

		cmp al, 1Eh           ; Compare with 'a' (scan code for 'a')
		je move_left
		cmp al, 20h           ; Compare with 'd' (scan code for 'd')
		je move_right
		
	
		jmp again  ; Continua o loop
		
		
move_test proc near
    cmp left, 1     ; Verifica o limite esquerdo
    jle done
    dec left
    jmp done
	ret
move_test endp
update_valley_position proc near

	;---------------------------------------------------------------------
	; Funcao randomica

	cmp f, 0
	JE	esquerda
direita:
		cmp left, 39		;testar o limite
		jne  move_vale_right
		
		mov f, 0
		jmp done
esquerda:
		cmp left, 1
		jne move_vale_left
		mov f, 1
		jmp done
	
	;--------------------------------------------------------------------
    ; Atualiza a posição do vale de acordo com o resultado
    cmp al, 0
    je move_vale_left
    cmp al, 2
    je move_vale_right
    jmp done
	
move_vale_left:
    cmp left, 1     ; Verifica o limite esquerdo
    jle done
    dec left
    jmp done

move_vale_right:
    cmp left, 39    ; Verifica o limite direito
    jge done
    inc left
    jmp done

done:
    ret
update_valley_position endp
		
move_left:
	; Movimenta a nave para a esquerda
	mov bl, left
	cmp shipPos, bl      ; verifica se a nave colidiu com o vale esquerdo
	jl finish
	cmp shipPos, 1  ; Verifica se a nave está no limite esquerdo
	jle again  ; Se estiver no limite, não move
	dec shipPos
	jmp again

move_right:
	; Movimenta a nave para a direita
	mov bl, left
	add bl, largura
	cmp shipPos, bl      ; verifica se a nave colidiu com o vale direito
	jg finish
	cmp shipPos, 58  ; Verifica se a nave está no limite direito (considerando largura da tela de 60 colunas)
	jge again  ; Se estiver no limite, não move
	inc shipPos
	jmp again		
		

;---------------FIM PROGRAMA		
finish:
		call printbuf
		.exit
;---------------FIM PROGRAMA





;----------------FUNCOES

desenha_nave proc near     ;Nao esta sendo utilizado
	mov al, 'V'  ; Caractere da nave
	mov bl, shipPos  ; Posição da nave
	lea di, [buffer + bx]
	mov [di], al  ; Desenha a nave na posição
	inc score
	inc dificulade_count
	;-------------------
	mov bl, left
	cmp shipPos, bl      ; verifica se a nave colidiu com o vale esquerdo
	jle finish
	
	mov bl, left
	add bl, largura
	cmp shipPos, bl      ; verifica se a nave colidiu com o vale direito
	jge finish
	;-----------------
	;call printbuf
	ret
desenha_nave endp

desenha_jogo proc near

	;------------Desenha os vales--------------------------
	mov	al,' '
	mov cl, largura  ; Serve como contador, subtraido no rep stosb
	mov bh, 0
	mov bl, left
	lea DI,[buffer+bx]
	rep stosb
	;------------Desenha a nave------------------
	mov al, 'V'  ; Caractere da nave
	mov bl, shipPos  ; Posição da nave
	lea di, [buffer + bx]
	mov [di], al  ; Desenha a nave na posição
	inc score
	inc dificulade_count
	;*********************
	mov bl, left
	cmp shipPos, bl      ; verifica se a nave colidiu com o vale esquerdo
	jl finish
	
	mov bl, left
	add bl, largura
	cmp shipPos, bl      ; verifica se a nave colidiu com o vale direito
	jg finish
	;*********************
	;---------------------------------
	
	call printbuf
	ret
desenha_jogo endp

kbhit proc near
		;mov ah, 6h
		;mov dl, 0ffh
		;int 21h
	
		;ret
		
		;---------------------------
	mov ah, 1h        ; Check if a key is pressed (non-blocking)
    int 16h           ; Call BIOS keyboard service
    jz no_key         ; If no key is pressed, jump to no_key
    mov ah, 0h        ; If a key is pressed, read the key (and clear it from the buffer)
    int 16h           ; Call BIOS keyboard service
    ret
no_key:
    xor al, al        ; Clear AL (no key pressed)
    ret
		;---------------------------
kbhit endp

printbuf proc near
		mov ah, 9h
		lea dx, buffer
		int 21h
		ret
printbuf endp

; Função de Delay
delay proc near
    ; Defina o número de iterações desejado para o delay
    mov cx, 0FFFFh  ; Número de iterações para o delay (ajuste conforme necessário)
delay_loop:
    ; Apenas um loop vazio para criar o delay
    loop delay_loop
    ret
delay endp

aumentar_dificuldade proc near
	cmp dificulade_count, 100
	je aumentar
aumentar:
	cmp largura, 5
	je dificuldade_fim
	dec largura
	mov	dificulade_count, 0
dificuldade_fim:
	ret
aumentar_dificuldade endp


;---------------FIM_END
		end
		
		