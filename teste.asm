;---------------MODELO SIMPLIFICADO
		.model small
		.stack 
CR		equ		13
LF		equ		10

;---------------DADOS			
		.data

buffer db 65 dup('O')
score_str db 6 dup(0)
endbuf db CR, LF, '$'
left	   db 20
largura      db 20 
shipPos    db 30
x	dw 10
score dw 0
score_buffer db 10 dup('$')
scorenum dw 12345
scoretest db 'score: ', '$'
dificulade_count db 0
mult_variacao dw 1

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
		mov cx, mult_variacao
loop_variacao:
		call update_valley_position
		loop loop_variacao
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
	; Função para gerar um número pseudo-aleatório entre 0, 1 e 2
	call random_number


;-----------------------------------
; Vai da esquerda pra direita, zig-zag dos vales para teste
;	cmp f, 0
;	JE	esquerda
;direita:
;		cmp left, 39		;testar o limite
;		jne  move_vale_right
		
;		mov f, 0
;		jmp done
;esquerda:
;		cmp left, 1
;		jne move_vale_left
;		mov f, 1
;		jmp done
	
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
	;jl finish
	cmp shipPos, 1  ; Verifica se a nave está no limite esquerdo
	jle again  ; Se estiver no limite, não move
	dec shipPos
	jmp again

move_right:
	; Movimenta a nave para a direita
	mov bl, left
	add bl, largura
	cmp shipPos, bl      ; verifica se a nave colidiu com o vale direito
	;jg finish
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
	
	; aumenta dificuldade a cada 100 pts
	call aumentar_dificuldade
	;*********************
	mov bl, left
	cmp shipPos, bl      ; verifica se a nave colidiu com o vale esquerdo
	;jl finish
	
	mov bl, left
	add bl, largura
	cmp shipPos, bl      ; verifica se a nave colidiu com o vale direito
	;jg finish
	;*********************
	;---------------------------------
	call exibir_score
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
	jge aumentar_largura
	jmp dificuldade_fim
aumentar_largura:
	mov	dificulade_count, 0
	cmp largura, 5
	je aumentar_variacao
	dec largura
aumentar_variacao:
	cmp mult_variacao, 4
	je dificuldade_fim
	inc mult_variacao
	
dificuldade_fim:
	ret
aumentar_dificuldade endp



; Função para gerar um número pseudo-aleatório entre 0, 1 e 2
random_number proc near
    ; x = (x * 9 + 7) % 251
	;mov dx, 0
    mov ax, x            ; Carrega a semente em AX
    mov bx, 9           ; Multiplica por 9
	imul bx
    add ax, 9            ; Soma 7
    mov bx, 251          ; Divisor para o cálculo do módulo
    div bx               ; AX = AX / BX, DX = resto (módulo)
	
	mov bx, 250
	add dx, bx
	
    mov x, dx            ; Atualiza a semente com o valor de DX

    ; Gera um número entre 0 e 2
    mov ax, dx           ; Coloca o valor do módulo (que é entre 0 e 250) em AX
	xor dx, dx           ; Limpa o valor de DX antes da próxima divisão
    mov bx, 3            ; Queremos dividir por 3 para ter um número entre 0 e 2
    div bx               ; AX = AX / BX, DX = resto (módulo)
    mov al, dl           ; O resto (DX) será o número aleatório entre 0 e 2

    ret
random_number endp

exibir_score proc near
    ; Define a posição do cursor no topo direito (coluna 75, linha 0)
    mov ah, 02h
    mov bh, 0
    mov dh, 1         ; Linha 0 (topo da tela)
    mov dl, 65         ; Coluna 75 (direita da tela)
    int 10h            ; Chama a interrupção de vídeo para mover o cursor
	
	; Exibe a string "score: "
    lea dx, scoretest
    mov ah, 09h
    int 21h

    ; Converte o valor do score em string
    lea si, score_buffer  ; Aponta para o buffer onde será armazenada a string do score
    mov ax, score    ; Carrega o valor do score
    call int_to_str    ; Converte o valor em string

    ; Exibe a string do score
    mov ah, 09h
    ;lea dx, scoretest
	lea dx, score_buffer
    int 21h

    ; Retorna o cursor para a posição inicial do jogo (linha 1, coluna 0)
    mov ah, 02h
    mov bh, 0
    mov dh, 24          ; Linha 1, logo abaixo do score
    mov dl, 0          ; Coluna 0, início da linha
    int 10h            ; Chama a interrupção de vídeo para mover o cursor

    ret
exibir_score endp

; Função para converter um número de 16 bits em uma string
int_to_str proc near
    ; Supondo que o número esteja em AL e queremos convertê-lo para uma string
    xor cx, cx         ; Limpa CX (contador de dígitos)
    mov bx, 10         ; Divisor para a divisão por 10
    mov si, offset score_buffer ; Carrega o endereço de 'buffer' em SI
    mov di, si         ; DI será usado para armazenar o número final

convert_loop:
    xor dx, dx         ; Limpa AH para divisão correta
    div bx             ; Divide AL por 10, resto em AH
    add dl, '0'        ; Converte o dígito em caractere ASCII
    mov [di], dl       ; Armazena o dígito na string
    inc di             ; Move o ponteiro para a próxima posição
    inc cx             ; Incrementa o contador de dígitos
    test ax, ax        ; Verifica se AL é zero
    jnz convert_loop   ; Se não for zero, continua o loop

    ; Adiciona o terminador de string
    mov byte ptr [di], '$'

    ; Reverte a string, pois os dígitos estão na ordem inversa
    mov si, offset score_buffer
    dec di             ; Ajusta DI para o último caractere válido
    mov bx, cx         ; BX contém o número de dígitos

reverse_loop:
	cmp si, di         ; Verifica se os ponteiros se cruzaram
    jae reverse_fim   ; Se sim, termina a inversão
    mov al, [si]       ; Carrega o caractere atual
	mov dl, [di]
    mov [di], al       ; Armazena o caractere na posição final
	mov [si], dl
    inc si             ; Avança o ponteiro de início
    dec di             ; Retrocede o ponteiro de fim
    ;dec bx             ; Decrementa o contador de dígitos
    jnz reverse_loop   ; Continua até todos os dígitos serem revertidos

    mov byte ptr [di], '$' ; Termina a string com '$'
reverse_fim:
    ret
int_to_str endp

;---------------FIM_END
		end
		
		
