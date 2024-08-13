;-------------------------------------MODELO SIMPLIFICADO----------------------------
	.model small
	.stack 

CR		equ		13
LF		equ		10

;-----------------------------------------DADOS-------------------------------------------------------------
		.data

buffer db 65 dup('O')		; buffer com o desenho do vale
endbuf db CR, LF, '$'
left	   db 20			; armazena o limite esquerdo do vale
largura      db 20 			; largura do vale
nave_pos    db 30			; posicao nave
x	dw 10					; var usada para geração do num aleatorio
score dw 0					; armazena o score (profundidade)
score_str db 10 dup('$')	; armazena a conversão para string do score
score_title db 'score: ', '$'    ;  Titulo que precede o score no display
dificuldade_count db 0			; conta 100 linhas e reseta
mult_variacao dw 1				; é incrementado a cada 100 linhas e indica quantas vezes atualizar_posicao_vale sera chamado
hp dw 100					; Health Points
hp_str db 5 dup('$')		; armazena a conversão para string do hp
hp_title db 'HP ', '$'		; titulo que precede o hp no display
cor db 01h					; var para efeito cromático quando powerup ativo
powerup_flag db 0			; indica se o powerup esta ativado
powerup_available db 0		; indica se o powerup esta disponive pra ser ativado (começa indisponivel)
powerup_count db 0  		; conta até chegar 500pts, disponibiliza o powerup ou conta 100 linhas e desativa powerup
powerup_title db 'POWERUP', '$'	; Titulo que indica no display quando o powerup esta disponivel
gameover_title db 'Final Score: ', '$'    ; Display do score final quando o jogo acaba


;--------------------------------------CODIGO---------------------------------------------------
	.code
	.startup
		
;-----------------------------------------INIT------------------------------------------------------
	mov ax, ds		;inicializa o segmento de extradata igual ao segmento data
	mov es, ax
		
;***************************************************************************************
again:
	; Introduz um delay para diminuir a velocidade do jogo
	call delay		
	call delay
	call delay
	
		
	; Preencher o vale (buffer) com 'O'
	mov	al,'O'
	mov cx, 60
	lea DI,buffer
	rep stosb
		
		
	; mult_variacao aumenta com a dificuldade, aumentando a variacao
	mov cx, mult_variacao		; carrega cx com o numero de vezes que a posicao do vale sera atualizada
loop_variacao:
	call atualizar_posicao_vale 		;Atualiza posicao dos vales
	loop loop_variacao


	; Desenha o vale
	call atualiza_jogo
	; Desenha a nave
	call desenha_nave
		
;-----------------Tratamento do teclado---------------------------------
	; Captura a tecla pressionada diretamente
	in al, 60h            ; Le diretamente da porta do teclado
	test al, 80h          ; Checa se a tecla foi liberada (bit mais significante é 1 se liberada)
	jnz again             ; Se o bit for 1, a tecla foi liberada, então pula

	; apenas se a tecla estiver sendo pressionada
	and al, 7Fh           ; zera o bit mais significante pra ficar apenas com o codigo da tecla digitada

	cmp al, 1Eh           ; compara com o código da tecla para 'a'
	je move_left
	cmp al, 4Bh           ; compara com o código da tecla correspondente a <-
	je move_left
	cmp al, 20h           ; compara com o código da tecla para 'd'
	je move_right
	cmp al, 4Dh           ; compara com o código da tecla correspondente a ->
	je move_right
		
	cmp al, 39h			  ; Compara com o codigo da tecla espaço (ativa o powerup)
	jne again
	call ativar_powerup
;---------------------------------------------------------------------------
		
	jmp again  ; Continua o loop
		
;***************************************************************************************

move_left:
	; Movimenta a nave para a esquerda
	mov bl, left
	cmp nave_pos, 1  ; Verifica se a nave está no limite esquerdo
	jle again  ; Se estiver no limite, não move
	dec nave_pos
	jmp again

move_right:
	; Movimenta a nave para a direita
	mov bl, left
	add bl, largura
	cmp nave_pos, 58  ; Verifica se a nave está no limite direito (considerando largura da tela de 60 colunas)
	jge again  ; Se estiver no limite, não move
	inc nave_pos
	jmp again	

	

;---------------FIM PROGRAMA-------------------------------		
finish:	
	; Display do score no final do jogo
	call printbuf
	mov ah, 09h
	lea dx, gameover_title
	int 21h
		
	lea si, score_str  ; Aponta para o buffer onde será armazenada a string do score
	mov ax, score    ; Carrega o valor do score
	call int_to_str    ; Converte o valor em string
		
	mov ah, 09h
	lea dx, score_str
	int 21h
		
	.exit
;---------------FIM PROGRAMA-------------------------------



;---------------------------------------FUNCOES-----------------------------------------------------------------

; Funcao que atualiza os limites do vale
atualizar_posicao_vale proc near
	call random_number			; Função para gerar um número pseudo-aleatório entre 0, 1 e 2
    ; Atualiza a posição do vale de acordo com o resultado (0-esquerda, 1-nada, 2-direita)
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
	mov bl, 65       ; 65 eh a qntd de colunas usadass
	sub bl, largura
    cmp left, bl    ; Verifica o limite direito
    jge done
    inc left
    jmp done
	
done:
    ret
atualizar_posicao_vale endp




; Funcao para desenhar a nave (efeito cromatico se powerup ativo)
desenha_nave proc near     
	; Configuração do registrador para a posição da nave na tela
    mov ah, 02h               ; Função para mover o cursor
    mov bh, 0                 ; pagina 0
    mov dh, 23                ; penultima linha mais de baixo
    mov dl, nave_pos           ; Coluna 
    int 10h                   ; Chama a interrupção para mover o cursor

	cmp powerup_flag, 0		  ; Checa se o powerup esta ativado, se sim, a nave fica indestrutivel
	je desenha_nave_normal
	
	; Desenhar a nave quando powerup ativo
	mov ah, 09h               ; Função para escrever caractere e cor
    mov al, 'V'               
    mov bh, 0                 ; pagina 0
    mov bl, cor               
	inc cor					  ; efeito cromático
	cmp cor, 10h			  
	je muda_cor				  ; volta para o inicio das cores
	jmp desenha_nave_continue

desenha_nave_normal:	
	; Desenhar a nave powerup desativado
    mov ah, 09h               ; Função para escrever caractere e cor
    mov al, 'V'               
    mov bh, 0                 ; pagina 0
    mov bl, 0Eh               ; 0=background preto, E=cor amarela

desenha_nave_continue:	
    mov cx, 1                 ; Escreve 1 caractere
    int 10h                   ; Chama a interrupção para desenhar o caractere
	
	; Retorna o cursor para a posição inicial do jogo
    mov ah, 02h
    mov bh, 0
    mov dh, 24          ; Linha 24, a mais de baixo
    mov dl, 0          ; Coluna 0, início da linha
    int 10h            ; Chama a interrupção para mover o cursor
	
	ret

muda_cor:				; resetar a cor
	mov cor, 01h
	jmp desenha_nave_continue
	
desenha_nave endp





; gera o vale no buffer, checa colisao, exibe score e hp, aumenta dificuldade e desenha o jogo
atualiza_jogo proc near

	;------------Desenha o vale--------------------------
	mov	al,' '       ; ' ' representa o vale
	mov cl, largura  ; Serve como contador, subtraido no rep stosb
	mov bh, 0
	mov bl, left	; carregando o limite esquerdo no reg. b
	lea DI,[buffer+bx]  ; carregando o EA de onde o vale começa
	rep stosb
	
	inc score            ; a cada linha, incrementa a pontuacao
	inc dificuldade_count   ; variavel que conta até 100 pra aumentar a dificuldade
	
	; aumenta dificuldade a cada 100 pts
	call aumentar_dificuldade
	
	; checa se a nave colidiu com as montanhas
	call checar_colisao
	
	; poe na tela o score, o hp e se o powerup esta disponivel
	call exibir_info
	
	; desenha o vale na tela
	call printbuf
	
	; faz a contagem para disponibilizar o powerup novamente
	call powerup_counter

	ret
atualiza_jogo endp




; Poe na tela uma string (string formada pelas montanhas e vale)
printbuf proc near
		mov ah, 9h
		lea dx, buffer
		int 21h
		ret
printbuf endp




; Função de Delay
delay proc near
    mov cx, 0FFFFh
delay_loop:
    loop delay_loop
    ret
delay endp




; Funcao para aumentar dificuldade a cada 100 linhas percorridas (- largura, + variacao)
aumentar_dificuldade proc near
	cmp dificuldade_count, 100		;dificuldade_count conta até 100 linhas
	jge aumentar_largura			; se 100 linhas passaram, aumenta largura
	jmp dificuldade_fim
aumentar_largura:
	mov	dificuldade_count, 0
	cmp largura, 5					; Verificação para a largura não ser menor que 5
	je aumentar_variacao
	dec largura
aumentar_variacao:
	cmp mult_variacao, 4            ; Verificação para a variacao max não ser maior que 4
	je powerup_check
	inc mult_variacao
	
powerup_check:
	cmp powerup_flag, 1				; se o powerup estiver ativado, nao fazer nada
	je dificuldade_fim
	inc powerup_count				
	cmp powerup_count, 5			; contagem até 500 linhas para disponibilizar o POWERUP
	jne dificuldade_fim
	mov powerup_count, 0			; Chegou em 500 -> reseta contador do powerup e torna ele disponivel
	mov powerup_available, 1
	
dificuldade_fim:
	ret
aumentar_dificuldade endp






ativar_powerup proc near
	cmp powerup_available, 0		; pra ativar o powerup, checa se ele está disponivel
	je ativar_powerup_fim
	mov powerup_flag, 1				; ativa powerup
	mov powerup_available, 0        ; torna o powerup indisponivel
ativar_powerup_fim:
	ret
ativar_powerup endp






; Funcao para contar 100 linhas a partir do momento que powerup é ativado, e depois desativar
powerup_counter proc near
	cmp powerup_flag, 1
	jne powerup_counter_fim			; Se não estiver ativado, nao faz nada
	inc powerup_count
	cmp powerup_count, 100			; conta até 100
	jne powerup_counter_fim
	mov powerup_count, 0			; se for 100, zera tudo
	mov powerup_available, 0
	mov powerup_flag, 0
powerup_counter_fim:
	ret
powerup_counter endp





; Função para gerar um número pseudo-aleatório entre 0, 1 e 2
random_number proc near
    ; x = (x * 9 + 7) % 251
    mov ax, x            ; Carrega x em ax
    mov bx, 9           ; Multiplica por 9
	imul bx
    add ax, 9            ; soma 9
    mov bx, 251          ; divisor para o cálculo do módulo
    div bx               ; ax = ax/bx, dx = resto 
	
	
	mov bx, 250			 
	add dx, bx			 ; soma o resto da divisao com 250
	
    mov x, dx            ; Atualiza x com o valor de dx

    ; x % 3 (Gera um número entre 0 e 2)
    mov ax, dx           ; Coloca o valor do módulo (que é entre 0 e 250) em ax
	mov dx, 0            ; limpa o valor de dx antes da próxima divisão
    mov bx, 3            ; divide por 3 para ter um número entre 0 e 2
    div bx               ; ax = ax/bx, dx = resto 
    mov al, dl           ; resto (em dx) será o número aleatório entre 0 e 2

    ret
random_number endp





; Funcao para colocar no canto superior direito o score, o hp e o powerup
exibir_info proc near
	;---------------------------Score-----------------------------------------
    ; Define a posição do cursor no topo direito (coluna 70, linha 1)
    mov ah, 02h
    mov bh, 0
    mov dh, 1         ; Linha 1
    mov dl, 70         ; Coluna 70 (direita da tela)
    int 10h            ; Chama a interrupção para mover o cursor
	
	; Exibe a string "score: "
    lea dx, score_title
    mov ah, 09h
    int 21h

    ; Converte o valor do score em string
    lea si, score_str  ; Aponta para o buffer onde será armazenada a string do score
    mov ax, score    ; Carrega o valor do score
    call int_to_str    ; Converte o valor em string

    ; Exibe a string do score
    mov ah, 09h
	lea dx, score_str
    int 21h
	;---------------------------------------------------------------------------

	;--------------------------Health Points (HP)---------------------------------
	; Define a posição do cursor no topo direito (coluna 70, linha 2)
	mov ah, 02h
    mov bh, 0
    mov dh, 2         ; Linha 2
    mov dl, 70         ; Coluna 70
    int 10h            ; Chama a interrupção mover o cursor
	
	; Exibe a string "HP "
	lea dx, hp_title
    mov ah, 09h
    int 21h
	
	; Converte o valor da resistencia em string
	lea si, hp_str
	mov ax, hp
	call int_to_str
	
	; Exibe a string da resistencia
    mov ah, 09h
	lea dx, hp_str
    int 21h
	;----------------------------------------------------------------------------------

	;----------------------------------POWERUP-----------------------------------------
	cmp powerup_available, 1		; se o powerup nçao estiver disponivel, nao mostrar nada
	jne reiniciar_cursor
	
	; Define a posição do cursor no topo direito (coluna 70, linha 5)
	mov ah, 02h
    mov bh, 0
    mov dh, 5         ; Linha 5
    mov dl, 70         ; Coluna 70 (direita da tela)
    int 10h            ; Chama a interrupção para mover o cursor
	
	; Exibe a string 'POWERUP'
	mov ah, 09h
	lea dx, powerup_title
    int 21h
	;----------------------------------------------------------------------------------
   
reiniciar_cursor:		 ; Retorna o cursor para a posição inicial do jogo (linha 24, coluna 0)
    mov ah, 02h
    mov bh, 0
    mov dh, 24          ; Linha 24
    mov dl, 0          ; Coluna 0, início da linha
    int 10h            ; Chama a interrupção para mover o cursor
    ret
exibir_info endp






; Função para converter um número de 16 bits em uma string
int_to_str proc near
    ; o número deve estar em al, em si deve estr o endereço da string final
    mov bx, 10         ; Divisor para a divisão por 10
    mov di, si         ; di será usado para armazenar o número final

convert_loop:
    mov dx, 0          ; Limpa dx para divisão correta
    div bx             ; Divide ax por 10, resto em dx
    add dl, '0'        ; Converte o dígito em caractere ASCII
    mov [di], dl       ; Armazena o dígito na string
    inc di             ; Move o ponteiro para a próxima posição
	
    cmp ax, 0        ; Verifica se al é zero
    jnz convert_loop   ; Se não for zero, continua o loop

    ; Adiciona o terminador de string '$'
	mov bl, '$'
	mov [di], bl
	

    ; inverte a string, ja queos dígitos estão na ordem inversa
    dec di             ; Ajusta di para o último caractere

reverse_loop:
	cmp si, di         ; Verifica se os ponteiros do inicio e fim da string se cruzaram
    jae reverse_fim   ; se sim, termina
    mov al, [si]       ; Carrega o caractere atual
	mov dl, [di]	   ; carrega o ultimo caractere
    mov [di], al       ; Armazena o caractere atual na posição final
	mov [si], dl	   ; Armazena o ultimo caractere no inicio
    inc si             ; incrementa o ponteiro do início
    dec di             ; decrementa o ponteiro do fim
    jnz reverse_loop   ; loop até todos os digitos forem invertidos

    ; Termina a string com '$'
	mov bl, '$'
	mov [di], bl
	
reverse_fim:
    ret
int_to_str endp





; Funcao para verificar se houve colisão entre a nave e as montanhas
checar_colisao proc near

	cmp powerup_flag, 1			; se powerup ativo, nave indestrutivel
	je checar_colisao_false

	mov bl, left
	cmp nave_pos, bl     	 ; verifica se a nave colidiu com a montanha esquerda
	jl checar_colisao_true
	
	mov bl, left
	add bl, largura
	sub bl, 1               ; left + largura - 1 para a posicao da montanha direita
	cmp nave_pos, bl      	; verifica se a nave colidiu com a montanha direita
	jg checar_colisao_true   
	jmp checar_colisao_false
	
checar_colisao_true: 		
	call cor_vermelha		; Quando há colisão, os caracteres ficam vermelho, indicando dano
	cmp hp, 0		
	je finish				; Jogo acaba quando hp chega a 0
	dec hp
	ret

checar_colisao_false:      ; não há colisão
	call reset_cor			; cor dos chars de volta ao normal
	ret
	
checar_colisao endp





cor_vermelha proc near
	; Define a cor vermelha para todos os caracteres na tela
	mov ah, 09h           ; Função para mudar cor do caractere
    mov al, ' '           ; char passado pra funcao (poderia ser qualquer caractere)
    mov bh, 0             ; Pagina 0
    mov cx, 2000          ; num de caracteres a serem mudados (80x25 = 2000 caracteres na tela)
    mov bl, 0Ch           ; cor: 0 -> background preto, C -> char vermelho
    int 10h               ; Chama a interrupção para mudar cor
    ret
cor_vermelha endp





reset_cor proc near
	
    mov ah, 09h           ; Função para mudar cor do caractere
    mov al, ' '           ; char passado pra funcao (poderia ser qualquer caractere)
    mov bh, 0             ; Pagina 0
    mov cx, 2000          ; num de caracteres a serem mudados (80x25 = 2000 caracteres na tela)
    mov bl, 02h           ; cor: 0 -> background preto, C -> char vermelho
    int 10h               ; Chama a interrupção para mudar cor
    ret
reset_cor endp


;---------------------------------------------------------------------------------------------------

;********************* FIM ************************************
	end
		
		
