
INCLUDE Irvine32.inc
include winmm.inc
includelib winmm.lib

plotaCenario	PROTO
animaTela		PROTO
printaMenu		PROTO
jogoPrincipal	PROTO
imprimeArquivo	PROTO
telaOpcoes		PROTO


.data?
aux1  dword ?
aux2  dword ?

.const
SND_ASYNC                            equ 1h
SND_FILENAME                         equ 20000h
SND_LOOP                             equ 8h

.data
strTitulo			byte		"Mov bloc, 0", 0
strInstrucoes		byte		"Instrucoes:",0
strNivel			byte		"Nivel ", 0
strJogar			byte		"Jogar", 0
strOpcoes			byte		"Opcoes", 0
strAjuda			byte		"Ajuda", 0
strVidas			byte		"Vidas: ", 0
strPontos			byte		"Pontuacao: ", 0
strQqrTecla			byte		"Pressione qualquer tecla para continuar",0

instrucoesIn		byte		50 dup (?),0

BUFFER_SIZE = 5000
buffer				byte		BUFFER_SIZE dup(?)
cenarioAnim			byte		BUFFER_SIZE dup(?)
bytesRead			dword		0

inFilename			byte		"telas\cxx.txt", 0
inFileTitulo		byte		"telas\movbloc0.txt", 0
inFileFim			byte		"telas\fim.txt", 0
inFileOver			byte		"telas\gameOver.txt", 0
inFileHey			byte		"telas\hey.txt", 0
inFileOpcoes		byte		"telas\opcoes.txt", 0
inFileAjuda			byte		"telas\ajuda.txt", 0
inFilePontos		byte		"telas\pontuacao.txt", 0
infileH				dword		0

playGame			byte		"sons\level.wav", 0
playMenu			byte		"sons\menu.wav", 0
playEnd				byte		"sons\end.wav", 0

tamc				dword		0	;tamanho do cenario em colunas 
taml				dword		0	;tamanho do cenario em linhas
vitoria				byte		0	;controla vitoria. funciona como  Bool
velocidade			dword		100	;controla
tema				byte		1	;1=p/b, 2 = b/p, 3 = matrix, 4 = X
nivelAtual			byte		1
vidas				byte		3
pontuacao			sdword		0 


.code
main PROC
	
	mov edx, OFFSET strTitulo
	INVOKE SetConsoleTitle, edx
	mov eax, SND_FILENAME;; pszSound is a file name
	or eax, SND_LOOP;; Play in a loop
	or eax, SND_ASYNC;; Play in the background
	invoke sndPlaySound, ADDR playMenu, eax
	INVOKE printaMenu
	exit

main ENDP

;################################################################################
jogoPrincipal PROC
;################################################################################
LOCAL pontosDoNivel:dword, instrucoesMin:byte, qtdInstrucoes:byte, perdaVidas:byte, negativo:byte
	
	mov perdaVidas, 0
	mov qtdInstrucoes, 0
	mov negativo, 0

	;abre o nivel atual do jogador
	.if(nivelAtual < 10)
		mov [inFileName + 7], '0'
	.elseif(nivelAtual < 20)
		mov [inFileName + 7], '1'
	.elseif(nivelAtual < 30)
		mov [inFileName + 7], '1'
	.endif
	mov al, nivelAtual
	add al, '0'
	mov[inFileName + 8], al


	; abre o arquivo
	mov  edx, OFFSET inFilename
	call OpenInputFile
	mov     infileH, eax

	; le o arquivo
	mov  edx, OFFSET buffer
	mov  ecx, BUFFER_SIZE
	call ReadFromFile
	mov  bytesRead, eax

	; fecha o arquivo
	mov     eax, infileH
	call        CloseFile	

	.while(vitoria == 0) && (vidas > 0)
		mov qtdInstrucoes, 0
		call Clrscr
		
		;escreve "Nivel x" no topo do cenario
		mov dl, 10
		mov dh, 1
		call Gotoxy
		mov edx, OFFSET strNivel
		call WriteString
		mov al, [inFilename + 7]
		call WriteChar
		mov al, [inFilename + 8]
		call WriteChar

		;escreve quantidade de vidas
		mov dl, 55
		mov dh, 1
		call Gotoxy
		mov edx, OFFSET strVidas
		call WriteString		
		mov al, vidas
		add al, '0'
		call WriteChar

		;escreve quantidade de pontos
		mov dl, 30
		mov dh, 3
		call Gotoxy
		mov edx, OFFSET strPontos
		call WriteString		
		mov eax, pontuacao
		call WriteInt

		invoke plotaCenario

		mov edx, OFFSET strInstrucoes
		call WriteString
		mov al, 0
		mov aux1, 0
		mov ecx, 0
		INVOKE getTickCount  ;comeca variacao de tempo 
		mov pontosDoNivel, eax
		.while(al != 13) && (ecx <= 50)
			mov al, 32
			call WriteChar
	LookforKey:
			mov  eax, 10; espera para nao pular entradas de teclado
			call Delay

			call ReadKey
			jz   LookForKey ;fica no loop ate receber entrada
			.if (al == 0h) ;recebeu caracter especial. 
				.if (ah == 72) 
					mov al, 94
				.elseif (ah == 75) 
					mov al, 60
				.elseif (ah == 80) 
					mov al, 118
				.elseif (ah == 77)
					mov al, 62
				.endif
			.else ;recebeu caracter ascii normal
				.if (al == 'w') || (al == 'W')
					mov al, 94
				.elseif(al == 'a') || (al == 'A')
					mov al, 60
				.elseif(al == 's') || (al == 'S')
					mov al, 118
				.elseif(al == 'd') || (al == 'D')
					mov al, 62
				.elseif (al == 27) ;apertando ESC, volta pro menu
					mov eax, SND_FILENAME  ;; pszSound is a file name
					or eax, SND_LOOP       ;; Play in a loop
					or eax, SND_ASYNC      ;; Play in the background
					invoke sndPlaySound, ADDR playMenu, eax
					INVOKE printaMenu
				.elseif (al !=13)
					mov al, 0h
				.endif
			.endif
			.if (al!= 0h) ;se o caracter for valido, imprime e salva
				call WriteChar
				.if(al != 13)
					mov ebx, OFFSET instrucoesIn
					mov esi, aux1
					mov [ebx + esi], al
					inc aux1
					inc ecx
					inc qtdInstrucoes
				.else
					mov ebx, OFFSET instrucoesIn
					mov esi, aux1
					mov al, 0
					mov [ebx + esi], al
					mov al, 13				
				.endif	
			
			.else
				mov al, 8
				call WriteChar
			.endif
		.endw
		call Crlf

		INVOKE GetTickCount
		sub eax, pontosDoNivel
		mov pontosDoNivel, eax
		
		mov eax, tamc
		mul taml
		add eax, 4
		mov ecx, eax
		movzx ebx, [buffer+ecx]
		sub ebx, '0'
		mov eax, 10
		mul ebx
		mov instrucoesMin, al
		movzx ebx, [buffer + ecx + 1]
		sub ebx, '0'
		add instrucoesMin, bl

		mov bl, instrucoesMin
		sub qtdInstrucoes, bl   ;qtdInstrucoes agora tem quantas instrucoes a mais foram feitas
		
		
	
		INVOKE Str_copy, ADDR buffer, ADDR cenarioAnim

		INVOKE animaTela
		;daqui, volta se teve vitoria (vitoria=1) ou nao (vitoria=0)


		.if (vitoria == 1)

			;sequencia para mostrar pontuacao do nivel

			;normaliza a pontuacao, ja que eh em milissegundos
			.if(pontosDoNivel < 50000)
				mov eax, 50000
				sub eax, pontosDoNivel
				mov pontosDoNivel, eax
				shr pontosDoNivel, 5
			.else
				mov pontosDoNivel, 0
			.endif

			call Clrscr
			mov dl, 32
			mov dh, 6
			call Gotoxy
			mov edx, OFFSET strNivel
			call WriteString
			movzx eax, nivelAtual
			call WriteDec
			mov dl, 30
			mov dh, 13
			call Gotoxy
			mov edx, OFFSET strPontos
			call WriteString
			mov dl, 26
			mov dh, 14
			call Gotoxy
			mov eax, 1000
			movzx ebx, perdaVidas
			mul ebx
			mov ebx, pontuacao
			add ebx, eax
			mov eax, ebx
			call WriteInt
			mov al, ' '
			call WriteChar
			mov al, '+'
			call WriteChar
			mov al, ' '
			call WriteChar
			mov eax, pontosDoNivel
			call WriteDec
			add pontuacao, eax
			mov al, ' '
			call WriteChar

			.if(perdaVidas > 0)
				mov al, '-'
				call WriteChar
				mov al, ' '
				call WriteChar
				mov eax, 1000
				call WriteDec
				mov al, ' '
				call WriteChar
			.endif
			.if(perdaVidas > 1)
				mov al, '-'
				call WriteChar
				mov al, ' '
				call WriteChar
				mov eax, 1000
				call WriteDec
				mov al, ' '
				call WriteChar
			.endif

			;calcula pontuacao por quantidade de instrucoes
			mov ebx, 1000
			.while (qtdInstrucoes > 0) && (ebx > 0)
				sub ebx, 100				
				dec qtdInstrucoes
			.endw
			.if (qtdInstrucoes > 0)
				mov negativo, 1
			.endif
			.while (qtdInstrucoes > 0)
				add ebx, 100
				dec qtdInstrucoes
			.endw

			.if(negativo == 0)
				mov al, '+'
				call WriteChar
				mov al, ' '
				call WriteChar
				mov eax, ebx
				call WriteDec
				add pontuacao, ebx
			.else
				mov al, '-'
				call WriteChar
				mov al, ' '
				call WriteChar
				mov eax, ebx
				call WriteDec
				sub pontuacao, ebx
			.endif
			mov negativo, 0

			mov al, ' '
			call WriteChar
			mov al, '='
			call WriteChar
			mov al, ' '
			call WriteChar
			mov eax, pontuacao
			call WriteInt			
			mov dl, 25
			mov dh, 20
			call Gotoxy
			mov edx, OFFSET strQqrTecla
			call WriteString
			call ReadChar
			;fim da sequencia
			.if(nivelAtual != 3)  ;ultimo nivel permitido
				inc nivelAtual
				mov vitoria, 0
				mov perdaVidas, 0
				INVOKE JogoPrincipal				
			.else
				mov eax, SND_FILENAME  ;; pszSound is a file name
				or eax, SND_LOOP       ;; Play in a loop
				or eax, SND_ASYNC      ;; Play in the background
				invoke sndPlaySound, ADDR playEnd, eax
				mov edx, OFFSET inFileHey
				INVOKE imprimeArquivo
				call ReadChar
				mov edx, OFFSET inFileFim
				INVOKE imprimeArquivo
				call ReadChar
				mov edx, OFFSET inFilePontos
				INVOKE imprimeArquivo
				mov dl, 53
				mov dh, 14
				call Gotoxy
				mov eax, pontuacao
				call WriteInt
				call ReadChar
				mov nivelAtual, 1
				mov vitoria, 0
				mov vidas, 3
				mov pontuacao, 0
				mov eax, SND_FILENAME  ;; pszSound is a file name
				or eax, SND_LOOP       ;; Play in a loop
				or eax, SND_ASYNC      ;; Play in the background
				invoke sndPlaySound, ADDR playMenu, eax
				INVOKE printaMenu
			.endif
		.else ;(vitoria == 0)
			dec vidas 
			inc perdaVidas
			sub pontuacao, 1000
			.if (vidas == 0)
				mov vidas, 3
				mov nivelAtual, 1
				mov pontuacao, 0
				mov eax, SND_FILENAME  ;; pszSound is a file name
				or eax, SND_LOOP       ;; Play in a loop
				or eax, SND_ASYNC      ;; Play in the background
				invoke sndPlaySound, ADDR playMenu, eax
				INVOKE printaMenu
			.endif
		.endif
	.endw

	ret
jogoPrincipal ENDP









;################################################################################
animaTela PROC
; Anima o cenario na tela
; Recebe: nada, mas usa um mondicoisa
;################################################################################
	mov esi, 4
	mov dl, 0 ;coluna inicia em 0
	mov dh, 0; linha inicia em 0

	mov eax, taml
	mov aux1, eax
	mov eax, tamc
	mov aux2, eax
	mov al, 0 

;_____________________________________________________
	.while (aux1 > 0)
		mov dl, 0
		.while (aux2 > 0)
			mov al, [cenarioAnim + esi]
			.if (al == '1')
				jmp AchouPosicao
			.endif
			add dl, 2
			inc esi
			dec  aux2
		.endw
		add dh, 1
		mov ecx, tamc
		mov aux2, ecx
		dec aux1
	.endw
AchouPosicao:
	add dl, 10
	add dh, 5
	;dl dh posicao do personagem
	call Gotoxy ;coloca o cursor na posicao do personagem
	mov ebx, 0
	mov bh, dh
	mov bl, dl

;_____________________________________________________

	;##########################################################################
	;#######    esi = local do personagem (1) no cenarioAnim  #################
	;#######    bl, bh = posicao do cursor na tela            #################
	;##########################################################################


	;iteracao para execucao das instrucoes do jogador
	mov al, 1
	mov edi, 0 ;contador dos indices do instrucoesIn
	.while(al != 0)		
		mov al, [instrucoesIn + edi]
		inc edi
		.if (al == '^')
			mov ecx, esi  ;ecx = local antigo do personagem
			sub esi, tamc  ;possivel novo local do jogador	
			dec bh
		.elseif (al == 'v')
			mov ecx, esi  ;ecx = local antigo do personagem
			add esi, tamc ;possivel novo locao do jogador
			inc bh
		.elseif (al == '<')
			mov ecx, esi  ;ecx = local antigo do personagem
			dec esi  ;possivel novo locao do jogador
			sub bl, 2
		.elseif (al == '>')
			mov ecx, esi  ;ecx = local antigo do personagem
			inc esi  ;possivel novo locao do jogador
			add bl, 2
		.endif
			
		.if([cenarioAnim + esi] == '2'); é caixa
			push esi
			push ebx
			.if (al == '^')
				sub esi, tamc  ;possivel novo local do jogador	
				dec bh
			.elseif (al == 'v')
				add esi, tamc ;possivel novo locao do jogador
				inc bh
			.elseif (al == '<')
				dec esi  ;possivel novo locao do jogador
				sub bl, 2
			.elseif (al == '>')
				inc esi  ;possivel novo locao do jogador
				add bl, 2
			.endif
			.if([cenarioAnim + esi] == '0') || ([cenarioAnim + esi] == '3')
				.if(([cenarioAnim + esi] == '3')) ;se for se movimentar para um ponto final
					mov vitoria, 1

					mov [cenarioAnim + ecx], '0'
					mov al, 250
					call WriteChar ;printa '.' no bloco atual do personagem
				
					mov dl, bl
					mov dh, bh
					call Gotoxy
					mov [cenarioAnim + esi], '2'
					mov al, 254
					call WriteChar ;printa . no novo bloco da caixa
				
					pop ebx
					pop esi
				
					mov [cenarioAnim + esi], '1'
				.elseif(vitoria == 1)  ;tinha ganho, mas tirou a caixa do lugar
					mov vitoria, 0

					mov [cenarioAnim + ecx], '0'
					mov al, 250
					call WriteChar ;printa '.' no bloco atual do personagem

					mov dl, bl
					mov dh, bh
					call Gotoxy
					mov [cenarioAnim + esi], '2'
					mov al, 254
					call WriteChar ;printa . no novo bloco da caixa

					pop ebx
					pop esi
				
					mov [cenarioAnim + esi], '5'
				.else
					mov [cenarioAnim + ecx], '0'
					mov al, 250
					call WriteChar ;printa '.' no bloco atual do personagem
				
					mov dl, bl
					mov dh, bh
					call Gotoxy
					mov [cenarioAnim + esi], '2'
					mov al, 254
					call WriteChar ;printa . no novo bloco da caixa
				
					pop ebx
					pop esi
				
					mov [cenarioAnim + esi], '1'
				.endif
				
				
				
			.elseif([cenarioAnim + esi] == '4') ;se a caixa for parar numa parede;
				pop ebx
				pop esi
				mov esi, ecx
				.if (al == '^')  ;cancela tudo feito antes
					inc bh
				.elseif (al == 'v')
					dec bh
				.elseif (al == '<')
					add bl, 2
				.elseif (al == '>')
					sub bl, 2
				.endif
			.endif
				
				
			
		.elseif([cenarioAnim + esi] == '0'); é vazio
			mov [cenarioAnim + esi], '1'
			.if [cenarioAnim + ecx] == '5'
				mov [cenarioAnim + ecx], '3'
				mov al, 169
			.else
				mov [cenarioAnim + ecx], '0'
				mov al, 250
			.endif
			call WriteChar

		.elseif([cenarioAnim + esi] == '3'); espaco Final
			mov [cenarioAnim + esi], '5'
			mov [cenarioAnim + ecx], '0'
			mov al, 250
			call WriteChar

		.elseif([cenarioAnim + esi] == '4');é parede, nao altera cenarioAnim nem desloca cursor
			mov esi, ecx
			.if (al == '^')  ;cancela tudo feito antes
				inc bh
			.elseif (al == 'v')
				dec bh
			.elseif (al == '<')
				add bl, 2
			.elseif (al == '>')
				sub bl, 2
			.endif
		.endif
			
		.if (al != 0) && (esi!=ecx) ;nao é fim das instrucoes e o personagem movimentou
			mov dl, bl
			mov dh, bh
			call Gotoxy			
			mov al, 147
			call WriteChar
			mov al, 8
			call WriteChar
			
		.endif
		mov cl, al
		mov eax, velocidade
		call delay
		mov al, cl
		
	.endw

	
	ret
animaTela ENDP

;################################################################################
imprimeArquivo PROC USES edx
;################################################################################
	;limpa o buffer
	cld             
	lea edi, buffer
	mov ecx, (SIZEOF buffer)
	mov al, 0
	rep stosb       ; repete ate limpar buffer

	; abre o arquivo
	;mov  edx, OFFSET inFilename
	call OpenInputFile
	mov     infileH, eax

	; le o arquivo
	mov  edx, OFFSET buffer
	mov  ecx, BUFFER_SIZE
	call ReadFromFile
	mov  bytesRead, eax

	; fecha o arquivo
	mov     eax, infileH
	call        CloseFile	

	
	xor edx, edx
	call Gotoxy
	call Clrscr
	mov edx, OFFSET buffer
	call WriteString
	ret
imprimeArquivo ENDP

;################################################################################
plotaCenario PROC 
; Plota o cenario na tela
; Recebe: nas variaveis buffer, tamc, taml - Altera as variaveis tamc, taml, aux1, aux2
;################################################################################
mov aux1, 0
mov aux2, 0

	;pega numero de colunas
	mov ax, word ptr[buffer]
	;cwde
	mov tamc, eax

	;pega o numero de linhas
	mov ax, word ptr[buffer + 2]
	cwde
	mov taml, eax


	mov esi, 4

	mov eax, taml
	mov al, byte ptr[taml]
	sub al, '0'
	cbw
	mov bx, 10
	mul bx;resultado em ax
	mov bx, ax

	mov al, byte ptr[taml + 1]
	sub al, '0'
	cbw
	add ax, bx
	cwde
	mov aux1, eax
	mov taml, eax

	mov eax, tamc
	mov al, byte ptr[tamc]
	sub al, '0'
	cbw
	mov bx, 10
	mul bx;resultado em ax
	mov bx, ax

	mov al, byte ptr[tamc + 1]
	sub al, '0'
	cbw
	add ax, bx
	cwde
	mov aux2, eax
	mov tamc, eax
	
	mov  dl, 10;column
	mov  dh, 5;row
	call Gotoxy
	.while (aux1 > 0)
		.while (aux2 > 0)
			mov al, [buffer + esi]
			;caracter em al

			.if (al == '4')
				mov eax, taml
				mov ebx, tamc
				mov cx, 0  ;possibilidades de character
				;185 = vertical c/ esquerdo, 186 = vertical, 187 = canto sup dir, 188 = canto inf dir     - lados direitos
				;200 = canto inf esq, 201 = canto sup esq, 204 = vertical c/ direito      - lados esquerdos
				;202 = horizontal c/ cima, 203 = horizontal c/ baixo, 205 = horizontal    - horizontais
				;206 = central
				;1 = esquerda, 2 = direita, 4 = cima, 8 = baixo
				.if (aux2 < ebx) ;aux2 comeca com o tamanho total e vai decrescendo
					sub esi, 1
					.if ([buffer + esi] == "4") ;checa se tem na esquerda
						add cx, 1
					.endif
					add esi, 1
				.endif
				.if (aux2 > 1);aux2 comeca com o tamanho total e vai decrescendo
					add esi, 1
					.if ([buffer + esi] == "4");checa se tem na direita
						add cx, 2
					.endif
					sub esi, 1
				.endif
				.if (aux1 < eax);aux1 comeca com o tamanho total e vai decrescendo
					sub esi, ebx
					.if ([buffer + esi] == "4");checa se tem pra cima
						add cx, 4
					.endif
					add esi, ebx
				.endif
				.if (aux1 > 1);aux1 comeca com o tamanho total e vai decrescendo
					add esi, ebx
					.if ([buffer + esi] == "4");checa se tem pra baixo
						add cx, 8
					.endif
					sub esi, ebx
				.endif
				
				.if (cx == 1) || (cx == 2) || (cx == 3) ;horizontal
					mov al, 205
				.elseif (cx == 4) || (cx == 8) || (cx == 12) || (cx == 0);vertical
					mov al, 186
				.elseif (cx == 5) ;canto inf dir
					mov al, 188
				.elseif (cx == 6) ; canto inf esq
					mov al, 200
				.elseif (cx == 7) ; horizontal c/ cima
					mov al, 202
				.elseif (cx == 9) ; canto sup dir
					mov al, 187
				.elseif(cx == 10) ; canto sup esq
					mov al, 201
				.elseif(cx == 11) ; horizontal c/ baixo
					mov al, 203
				.elseif(cx == 13) ; vertical c/ esquerda
					mov al, 185
				.elseif(cx == 14) ; vertical c/ direita
					mov al, 204
				.elseif(cx == 15) ;	central	
					mov al, 206
				.else
				.endif
			.elseif(al == '0')
				mov al, 250
			.elseif(al == '1')
				mov al, 147
			.elseif(al == '2')
				mov al, 254
			.else
				mov al, 169
			.endif
			call WriteChar
			.if (al != 205) && (al != 200) && (al != 201) && (al !=202) && (al != 203)
				mov al, 32
			.else
				mov al, 205
			.endif
			call WriteChar
			inc esi
			dec  aux2
		.endw
		mov dl, 10
		add  dh, 1
		call Gotoxy
		mov eax, tamc
		mov aux2, eax
		dec aux1
	.endw


	call Crlf
	ret
plotaCenario ENDP

;################################################################################
printaMenu PROC
; Plota o Menu na tela
; Recebe: nada, mas usa a variavel buffer e aux1 e aux2
;################################################################################
	
	;limpa o buffer
	cld             
	lea edi, buffer
	mov ecx, (SIZEOF buffer)
	mov al, 0
	rep stosb       ; repete ate limpar buffer

	call Clrscr
	; abre o arquivo
	mov  edx, OFFSET inFileTitulo
	call OpenInputFile
	mov     infileH, eax

	; le o arquivo
	mov  edx, OFFSET buffer
	mov  ecx, BUFFER_SIZE
	call ReadFromFile
	mov  bytesRead, eax

	; fecha o arquivo
	mov     eax, infileH
	call        CloseFile

	mov edx, OFFSET buffer
	call WriteString

	;27 - 30, 14 = jogar
	;27 - 30, 19 = opcoes
	;27 - 30, 24 = ajuda
	;bl selecao atual. 1 = jogar, 2 = opcoes, 3 = ajuda

	mov dl, 27
	mov dh, 14
	call Gotoxy

	mov al, '_'
	call WriteChar
	call WriteChar
	call WriteChar
	mov al, '\'
	call WriteChar
	mov dl, 30
	mov dh, 15
	call Gotoxy
	mov al, '/'
	call WriteChar

	push 1

LookforKey2:
	mov  eax, 50; espera para nao pular entradas de teclado
	call Delay

	call ReadKey
	jz   LookForKey2 ;fica no loop ate receber entrada
	.if (al == 0h) ;recebeu caracter especial. 
		.if (ah == 72) 
			mov al, 94
		.elseif (ah == 80) 
			mov al, 118
		.endif
	.else ;recebeu caracter ascii normal
		.if (al == 'w') || (al == 'W')
			mov al, 94
		.elseif(al == 's') || (al == 'S')
			mov al, 118
		.elseif(al == 'j') || (al == 'J')
			invoke sndPlaySound, ADDR playGame, SND_LOOP or SND_FILENAME or SND_ASYNC
			INVOKE jogoPrincipal
		.elseif(al == 'o') || (al == 'O')
			INVOKE telaOpcoes
		.elseif(al == 'a') || (al == 'A')
			mov edx, OFFSET inFileAjuda
			INVOKE imprimeArquivo

		Ajuda2:
			mov  eax, 50; espera para nao pular entradas de teclado
			call Delay

			call ReadKey
			jz   Ajuda2 ;fica no loop ate receber entrada
			.if(al == 27)
				INVOKE printaMenu
			.endif
			jmp Ajuda2
		.elseif (al == 27) ;apertando ESC, sai do jogo
			invoke ExitProcess, 0
		.elseif (al !=13)
			mov al, 0h
		.endif
	.endif


	pop edx
	mov bl, dl
	.if(al == 94) ;foi para cima
		.if(bl == 1) ;se estiver em jogar
			mov bh, 1
		.elseif(bl == 2)
			mov bh, 1
		.else
			mov bh, 2
		.endif
	.elseif(al == 118) ;foi para baixo
		.if(bl == 1) ;se estiver em jogar
			mov bh, 2
		.elseif(bl == 2)
			mov bh, 3
		.else
			mov bh, 3
		.endif
	.elseif(al == 13) ;apertou Enter
		.if(bl == 1) ;se estiver em jogar
			invoke sndPlaySound, ADDR playGame, SND_LOOP or SND_FILENAME or SND_ASYNC
			INVOKE jogoPrincipal
		.elseif(bl == 2)
			INVOKE telaOpcoes
		.else
			mov edx, OFFSET inFileAjuda
			INVOKE imprimeArquivo

		Ajuda:
			mov  eax, 50; espera para nao pular entradas de teclado
			call Delay

			call ReadKey
			jz   Ajuda ;fica no loop ate receber entrada
			.if(al == 27)
				INVOKE printaMenu
			.endif
			jmp Ajuda
		.endif
	.endif
	
	movzx edx, bh 
	push edx ;joga nova posicao na pilha
	
	.if (bh == bl)
		jmp LookForKey2
	.endif



	;apaga a seta atual
	mov dl, 27
	.if(bl == 1)
		mov dh, 14
	.elseif(bl == 2)
		mov dh, 19
	.else
		mov dh, 24
	.endif
	call Gotoxy
	mov al, ' '
	call WriteChar
	call WriteChar
	call WriteChar
	call WriteChar
	mov dl, 30
	add dh, 1
	call Gotoxy
	call WriteChar

	;desenha a nova seta atual
	mov dl, 27
	.if(bh == 1)
		mov dh, 14
	.elseif(bh == 2)
		mov dh, 19
	.else
		mov dh, 24
	.endif
	call Gotoxy
	mov al, '_'
	call WriteChar
	call WriteChar
	call WriteChar
	mov al, '\'
	call WriteChar
	mov dl, 30
	add dh, 1
	call Gotoxy
	mov al, '/'
	call WriteChar


	jmp LookForKey2

		ret
printaMenu ENDP

telaOpcoes PROC
LOCAL	posLinha:byte,  ;1= primeira linha, 2 = segunda linha
		posSelect1:byte,  ;opcoes 1, 2, 3 e 4 do tema
		posSelect2:byte   ;opcoes 1, 2, 3 e 4 da velocidade

	mov posLinha, 1

	mov edx, OFFSET inFileOpcoes
	INVOKE imprimeArquivo

	mov al, [tema+1]
	mov posSelect1, al

PrintaSelecao:
	call Clrscr
	mov edx, OFFSET buffer
	call WriteString
	.if(tema==1)
		mov dl, 14
		mov dh, 15
		call Gotoxy
		mov al, '*'
		call WriteChar
		mov dl, 29
		call Gotoxy
		call WriteChar
	.elseif(tema == 2)
		mov dl, 38
		mov dh, 15
		call Gotoxy
		mov al, '*'
		call WriteChar
		mov dl, 53
		call Gotoxy
		call WriteChar
	.elseif (tema == 3)
		mov dl, 62
		mov dh, 15
		call Gotoxy
		mov al, '*'
		call WriteChar
		mov dl, 71
		call Gotoxy
		call WriteChar
	.else  ;4
		mov dl, 78
		mov dh, 15
		call Gotoxy
		mov al, '*'
		call WriteChar
		mov dl, 82
		call Gotoxy
		call WriteChar
	.endif

	.if(velocidade==100)
		mov dl, 14
		mov dh, 22
		call Gotoxy
		mov al, '*'
		call WriteChar
		mov dl, 29
		call Gotoxy
		call WriteChar
		mov posSelect2, 1
	.elseif(velocidade == 250)
		mov dl, 38
		mov dh, 22
		call Gotoxy
		mov al, '*'
		call WriteChar
		mov dl, 47
		call Gotoxy
		call WriteChar
		mov posSelect2, 2
	.elseif (velocidade == 500)
		mov dl, 54
		mov dh, 22
		call Gotoxy
		mov al, '*'
		call WriteChar
		mov dl, 62
		call Gotoxy
		call WriteChar
		mov posSelect2, 3
	.else ;750
		mov dl, 70
		mov dh, 22
		call Gotoxy
		mov al, '*'
		call WriteChar
		mov dl, 78
		call Gotoxy
		call WriteChar
		mov posSelect2, 4
	.endif
	
PrintaSeta:
	.if(posLinha == 1)		
		mov dh, 15
		.if(posSelect1 == 1)
			mov dl, 11
		.elseif (posSelect1 == 2)
			mov dl, 35
		.elseif (posSelect1 == 3)
			mov dl, 59
		.elseif (posSelect1 == 4)
			mov dl, 75		
		.endif
	.else
		mov dh, 22
		.if(posSelect2 == 1)
			mov dl, 11
		.elseif (posSelect2 == 2)
			mov dl, 35
		.elseif (posSelect2 == 3)
			mov dl, 51
		.elseif (posSelect2 == 4)
			mov dl, 67		
		.endif
	.endif
	call Gotoxy
	mov al, '-'
	call WriteChar
	mov al, '>'
	call WriteChar
LookforKey3:
	mov  eax, 100; espera para nao pular entradas de teclado
	call Delay

	call ReadKey
	jz   LookForKey3 ;fica no loop ate receber entrada
	.if (al == 0h) ;recebeu caracter especial. 
		.if (ah == 72) 
			mov al, 94
		.elseif (ah == 75) 
			mov al, 60
		.elseif (ah == 80) 
			mov al, 118
		.elseif (ah == 77)
			mov al, 62
		.endif
	.else ;recebeu caracter ascii normal
		.if (al == 'w') || (al == 'W')
			mov al, 94
		.elseif(al == 'a') || (al == 'A')
			mov al, 60
		.elseif(al == 's') || (al == 'S')
			mov al, 118
		.elseif(al == 'd') || (al == 'D')
			mov al, 62
		.elseif (al == 27) ;apertando ESC, volta pro menu			
			INVOKE printaMenu
		.elseif (al !=13)
			jmp LookforKey3
		.endif
	.endif

	.if (al == 13)
		.if (posLinha == 1)
			mov ax, 0
			mov al, posSelect1
			mov tema, al
			.if(tema == 1)
				mov  eax,white+(black*16)
			.elseif(tema == 2)
				mov  eax,black+(white*16)
			.elseif(tema ==3)
				mov  eax,lightGreen+(black*16)
			.else
				mov  eax,16
				call RandomRange
				mov ebx, eax
				.repeat
					mov  eax,16
					call RandomRange
				.until(ebx != eax)
				shl eax, 4
				add eax, ebx
			.endif
			call SetTextColor
		.else
			.if(posSelect2 == 1)
				mov velocidade, 100
			.elseif(posSelect2 == 2)
				mov velocidade, 250
			.elseif(posSelect2 == 3)
				mov velocidade, 500
			.else
				mov velocidade, 750
			.endif
		.endif
		jmp PrintaSelecao
	.elseif(posLinha == 1)
		.if (al == 60) ;esquerda
			.if(posSelect1 == 2) || (posSelect1 == 1)
				mov posSelect1, 1				
			.elseif (posSelect1 == 3)
				mov posSelect1, 2
			.else
				mov posSelect1, 3
			.endif
		.elseif (al == 62) ;direita
			.if(posSelect1 == 1)
				mov posSelect1, 2
			.elseif (posSelect1 == 2)
				mov posSelect1, 3
			.else
				mov posSelect1, 4
			.endif
		.elseif (al == 118)
			mov posLinha, 2
		.endif
	.else
		.if (al == 60) ;esquerda
			.if(posSelect2 == 2) || (posSelect2 == 1)
				mov posSelect2, 1				
			.elseif (posSelect2 == 3)
				mov posSelect2, 2
			.else
				mov posSelect2, 3
			.endif
		.elseif (al == 62) ;direita
			.if(posSelect2 == 1)
				mov posSelect2, 2
			.elseif (posSelect2 == 2)
				mov posSelect2, 3
			.else
				mov posSelect2, 4
			.endif
		.elseif (al == 94)
			mov posLinha, 1
		.endif
	.endif

	mov al, 8
	call WriteChar
	call WriteChar
	mov al, ' '
	call WriteChar
	call WriteChar
	jmp PrintaSeta
	

	call ReadChar
	ret
telaOpcoes ENDP

END main