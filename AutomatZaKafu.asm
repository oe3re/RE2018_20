INCLUDE Irvine32.inc
INCLUDE Macros.inc


endl EQU <0dh,0ah>
;---------------------------------------------------CONSTANTS------------------------------------------------------------------------
windX = 80
windY = 30
sugarDiam = 4 ;black diamond
sugarMin = 45 ;minus
buffSize = 80
;----------------------------------------------RECTANGLES & TITLES POSITIONS------------------------------------------------------
	productListX = 1
	productListY = 1
		sugarX = productListX+5
		sugarY = productListY+10
			sugarLevelX = sugarX
			sugarLevelY = sugarY+2
		creditsTitleX = sugarX
		creditsTitleY = sugarY+6
	billInfoX = 40
	billInfoY = 11
		billTitleX = billInfoX+5
		billTitleY = billInfoY+1
		billX = billTitleX
		billY = billTitleY+1
			cappBillX = billX
			esspBillX = billX
			cortBillX = billX
			machBillX = billX
			coffBillX = billX
			teeBillX = billX
	changeInfoX = 40
	changeInfoY = 1
		changeTitleX = changeInfoX+5
		changeTitleY = changeInfoY+5


.data
;-------------------------------------------------------TITLES-------------------------------------------------------------------
	titlemsg BYTE "Automat za kafu", endl, 0							;Naslov aplikacije
	prodTitle	BYTE "1. Kapucino ..................... 50", endl		;Spisak proizvoda koje aparat nudi
				BYTE "  2. Espreso ...................... 40", endl
				BYTE "  3. Kortado ...................... 50", endl
				BYTE "  4. Makijato ..................... 50", endl
				BYTE "  5. Domaca kafa .................. 40", endl
				BYTE "  6. Caj .......................... 30", endl, 0
	sugarTitle	BYTE "Secer:", endl, 0									;Naslov sekcije u kojoj se regulise kolicina secera
	billTitle	BYTE "Racun:", endl, 0
	creditsTitle BYTE "Kredit:", endl, 0								;Naslov sekcije u kojoj se prikazuje kredit korisnika
	changeTitle BYTE "Kusur:", endl, 0									;Naslov sekcije u kojoj se prikazuje kusur
	welcomeTitle	BYTE "Dobrodosli!", endl, endl						;Poruka na pocetku pokretanja aplikacije
					BYTE "		    (unesite kredit i pritisnite bilo koji taster)", endl, 0
	goodbyeMsg	BYTE "D O V I Dj E Nj A", endl, 0
	infoCaption BYTE "INFORMATION", endl, 0
	infoMsg	BYTE "Nemate dovoljno kredita.", endl, 0
	;-----------------------------------------------------------------------------------------------------------------------------
	
	welcomePos COORD <35,10>											;Pozicija naslova dobrodoslice	
	exitPos COORD <80,30>
	sugarLevel BYTE 3
	credits DWORD 0
	change DWORD ?
	bill DWORD 0
	cappAmount BYTE 0
	esspAmount BYTE 0
	cortAmount BYTE 0
	machAmount BYTE 0
	coffAmount BYTE 0
	teeAmount BYTE 0
	cappPrice DWORD 50 ; =50
	esspPrice DWORD 40 ; =40
	cortPrice DWORD 50 ; =50
	machPrice DWORD 50 ; =50
	coffPrice DWORD 40 ; =40
	teePrice DWORD 30	; =30

	
;------------------------------------------------CONSOLE CONTROLS----------------------------------------------------------------	
	outHandle HANDLE ?
	consoleHandle HANDLE 0
	scrSize COORD <120,80>
	windowRect SMALL_RECT <0,0,windX,windY> ; <left,right,top,bottom>
	consoleInfo CONSOLE_SCREEN_BUFFER_INFO <>
	cursorInfo CONSOLE_CURSOR_INFO <>	

	buffer BYTE buffSize DUP(?)
	inHandle HANDLE ?
	bytesRead DWORD ?

;==================================================================================================================================
;==================================================================================================================================

.code
drawRect PROC c ;--------------------------DRAWING RECTANGLE PROCEDURE-------------------------------------------------------------
		LOCAL startX:WORD, startY:WORD, endX:WORD, endY:WORD
		mov ax, [ebp+8]				; hvatamo argumente koje smo prosledili relativno u odnosu na BASE POINTER
		mov endY, ax				; jer smo pozivom direktive LOCAL, pored toga sto smo odvojili mesta na steku
		mov ax, [ebp+10]			; za lokalne promenljive, automatski stavili vrednost INSTRUCTION POINTERA
		mov endX, ax				; i staru vrednost BASE POINTER-a, koja ce se izlaskom iz procedure povratiti
		mov ax, [ebp+12]			; sto je lepa osobina direktive LOCAL :)
		mov startY, ax
		mov ax, [ebp+14]			; smestanje pocetnih i krajnjih koordinata za crtanje pravougaonika koje smo
		mov startX, ax				; prosledili u lokalne promeljive
		;------------------------------------------DRAWING TOP LINE----------------------------------------------------------------
		mov dl, BYTE PTR startX
		mov dh, BYTE PTR startY
		mov al, 196					

		.REPEAT
			call Gotoxy
			call Writechar
			inc dl
		.UNTIL dl > BYTE PTR (endX)
		;-----------------------------------------DRAWING BOTTOM LINE----------------------------------------------------------------
		mov dl, BYTE PTR startX
		mov dh, BYTE PTR endY
		mov al, 196

		.REPEAT
			call Gotoxy
			call Writechar
			inc dl
		.UNTIL dl > BYTE PTR endX
		;------------------------------------------DRAWING SIDE LINES---------------------------------------------------------------
		mov dl, BYTE PTR startX
		mov dh, BYTE PTR startY
		mov al, 179

		.REPEAT
			call Gotoxy
			call Writechar
			inc dh
		.UNTIL dh > BYTE PTR endY

		mov dl, BYTE PTR endX
		mov dh, BYTE PTR startY
		mov al, 179

		.REPEAT
			call Gotoxy
			call Writechar
			inc dh
		.UNTIL dh > BYTE PTR endY

		ret
drawRect ENDP

print PROC c;----------------------------------PRINTING TEXT PROCEDURE-----------------------------------------------------------
	LOCAL startX:BYTE, startY:BYTE, msg:DWORD
	mov al, [ebp+8]
	mov startY, al
	mov al, [ebp+12]
	mov startX, al
	mov eax, [ebp+16]
	mov msg, eax

	mov dl, startX
	mov dh, startY
	call Gotoxy
	mov edx, msg
	call WriteString

	ret

print ENDP

detect PROC c;-------------------------------KEY DETECTION PROCEDURE---------------------------------------------------------------
	LOCAL key:BYTE
	mov dl, [ebp+8]
	;Ispitujemo koji broj je pritisnut:
	mov key, dl
	cmp key, 31h
	je pressed1
	cmp key, 32h
	je pressed2
	cmp key, 33h
	je pressed3
	cmp key, 34h
	je pressed4
	cmp key, 35h
	je pressed5
	cmp key, 36h
	je pressed6
	cmp key, 2bh
	je pressedPlus
	cmp key, 2dh
	je pressedMinus
	cmp key, 0dh
	je pressedEnter
	jmp finish						; ukoliko nije pritisnut nijedan od ponudjenih, napusta se procedura i ceka se novi unos

pressedEnter:						; kada se pritisne ENTER, na ekranu se stampa racun i kusur i zavrsava se sa radom
	mov dl, finalX
	mov dh, finalY
	call Gotoxy
	mWrite <"--------------------------------">
	inc dh
	call Gotoxy
	mWrite <"RACUN:		">
	mov eax, bill
	call WriteDec

	mov dl, changeTitleX+8
	mov dh, changeTitleY
	call Gotoxy
	mWrite <"         ">
	call Gotoxy
	mov eax, change
	call WriteDec
	mov dl, creditsTitleX+8
	mov dh, creditsTitleY
	call Gotoxy
	mWrite <"         ">
escape:									; pritiskom na dugme ESC, ispisuje se poruka i zavrsava se sa radom
	mov eax, 10
	call Delay
	call ReadKey
	jz escape

	cmp al, 1bh
	jne escape

	call Clrscr
	INVOKE SetConsoleCursorPosition, outHandle, welcomePos
	mov edx, OFFSET goodbyeMsg
	call WriteString
	mov eax, 300
	call Delay
	INVOKE SetConsoleCursorPosition, outHandle, exitPos

	exit
	

pressedPlus:						; ukoliko je detektovan plus, povecavamo secer i osvezavamo skalu
	cmp sugarLevel, 5				; ukoliko je nivo secera na maksimumu izlazimo iz procedure
	je finish

	inc sugarLevel					; prilikom povecavanja nivoa secera, prvo povecamo sugarLevel, kako bismo pristupili
									; narednom karakteru, pa onda taj karakter prepravimo sa - na kvadratic
	mov dl, sugarLevelX
	mov dh, sugarLevelY
	mov al, sugarLevel
	shl al, 1
	add dl, al
	call Gotoxy
	mWrite <" ">
	call Gotoxy
	xor eax, eax
	mov al, 254
	call WriteChar
	jmp finish
pressedMinus:						; ukoliko je detektovan minus, smanjujemo secer i osvezavamo skalu
	cmp sugarLevel, 0				; ukoliko je nivo secera na minimumu, izlazimo iz procedure
	je finish

	mov dl, sugarLevelX				; prilikom smanjivanja nivoa secera, prvo brisemo kvadratic na poziciji na kojoj je 
	mov dh, sugarLevelY				; trenutni nivo secera i na toj poziciji umesto kvadratica stavljamo -, a zatim spustamo 
	mov al, sugarLevel				; nivo secera za jedan (obrnut proces u odnosu na povecanje)
	shl al, 1
	add dl, al
	call Gotoxy
	mWrite <" ">
	call Gotoxy
	xor eax, eax
	mov al, 45
	call WriteChar

	dec sugarLevel
	jmp finish
pressed1:
	xor eax, eax
	mov al, cappAmount
	mov dl, key
	push edx
	push cappPrice
	push eax
	call correction				; prosledjujemo proceduri kolicinu, broj koji je pritisnut i cenu tog proizvoda kako bi
	add esp, 4					; procedura izvrsila korekciju (isto tako je i za ostale slucajeve)
	mov cappAmount, al			; prihvatamo povratnu korigovanu vrednost
	jmp finish
pressed2:
	xor eax, eax
	mov al, esspAmount
	mov dl, key
	push edx
	push esspPrice
	push eax
	call correction
	add esp, 4
	mov esspAmount, al
	jmp finish
pressed3:
	xor eax, eax
	mov al, cortAmount
	mov dl, key
	push edx
	push cortPrice
	push eax
	call correction
	add esp, 4
	mov cortAmount, al
	jmp finish
pressed4:
	xor eax, eax
	mov al, machAmount
	mov dl, key
	push edx 
	push machPrice
	push eax
	call correction
	add esp, 4
	mov machAmount, al
	jmp finish
pressed5:
	xor eax, eax
	mov al, coffAmount
	mov dl, key
	push edx
	push coffPrice
	push eax
	call correction
	add esp, 4
	mov coffAmount, al
	jmp finish
pressed6:
	xor eax, eax
	mov al, teeAmount
	mov dl, key
	push edx
	push teePrice
	push eax
	call correction
	add esp, 4
	mov teeAmount, al

finish:
	ret

detect ENDP

correction PROC;---------------------------------CORRECTION PROCEDURE------------------------------------------------------------
	LOCAL amount:BYTE, price: DWORD, key:BYTE
	mov al, [ebp+8]
	mov amount, al
	mov eax, [ebp+12]
	mov price, eax
	mov al, [ebp+16]
	mov key, al 

	mov eax, 200
	call Delay
	call ReadKey
	cmp al, 2bh								; detektujemo da li je pritisnut znak + neposredno nakon broja
	je incAmount							; ukoliko jeste skacemo na deo procedure koji uvecava kolicinu proizvoda
	cmp al, 2dh								; detektujemo da li je pritisnut znak - neposredno nakon broja
	je decAmount							; ukoliko jeste skacemo na deo procedure koji umanjuje kolicinu
	cmp amount,0							; ukoliko je pritisnut samo broj bez znaka + ili -, a trenutna kolicina
	jne finish								; je neki broj koji nije nula, ne radimo nista (za promenu mora + ili -)
pressedPlusOnBeg:
	mov eax, credits
	mov edx, price
	cmp eax, edx							; proveravamo da li korisnik ima kredita za odabrani proizvod
	jb warning								; ukoliko nema kredita skace se na deo procedure koji ispisuje obavestenje
	sub eax, edx							; ukoliko ima kredita za izabrani proizvod, smanjujemo cenu proizvoda od kredita
	add bill, edx
	mov credits, eax
	mov change, eax
	push eax
	call updateCredits						; prosledjujemo proceduri novu kolicinu kredita kako bi osvezila ekran
	add esp, 4

	inc amount								; i povecavamo kolicinu narucenog proizvoda

	xor eax, eax
	xor edx, edx
	mov al, amount
	mov dl, key
	push eax
	push edx
	call printBill							; prosledjujemo kolicinu i broj koji je pritisnut kako bi se ispisao racun
	add esp, 8
	jmp finish
incAmount:
	cmp amount, 0
	je pressedPlusOnBeg						; ukoliko je odmah na pocetku pritisnut i broj i znak +, procedura treba da se
	mov eax, credits						; ponasa kao da je pritisnut samo broj
	mov edx, price
	cmp eax, edx
	jb warning								; proveravamo da li ima kredita, ako nema ispisuje se poruka, a ukoliko ima
	sub eax, edx							; oduzima se cena proizvoda od kredita
	add bill, edx
	mov credits, eax
	mov change, eax
	push eax
	call updateCredits						; prosledjujemo proceduri novi iznos kredita kako bi osvezila ekran
	add esp, 4

	inc amount								; uvecava se kolicina porucenog proizvoda

	xor eax, eax
	mov al, amount
	mov dl, key
	push eax
	push edx
	call updateAmount						; ukoliko je proizvod vec bio porucivan, potrebno je samo prepraviti kolicinu
	add esp, 8
	jmp finish
decAmount:
	cmp amount, 0							; ukoliko nije porucivan proizvod, ne smanjuje se kolicina (kolicina ne moze biti
	je finish								; biti negativan broj)
	mov eax, credits
	mov edx, price
	add eax, edx							; ukoliko smo smanjili kolicinu, korisniku vracamo kredit u iznosu cene tog proizvoda
	sub bill, edx
	mov credits, eax
	mov change, eax
	push eax
	call updateCredits						; prosledjujemo proceduri novi iznos kredita kako bi se osvezio ekran
	add esp, 4

	dec amount								; i smanjujemo porucenu kolicinu

	xor eax, eax
	xor edx, edx
	mov al, amount
	mov dl, key
	push eax
	push edx
	call updateAmount						; nakon toga prepravljamo porucenu kolicinu na ekranu
	add esp, 8
	jmp finish

	
warning:									; MESSAGE BOX koji ispisuje da nema dovoljno kredita
	INVOKE MessageBox, NULL, ADDR infoMsg, ADDR infoCaption, MB_OK

finish:
	mov eax, DWORD PTR amount
	ret
correction ENDP

updateAmount PROC c, key:BYTE, amount:BYTE ;------------REFRESHING SCREEN PROCEDURE-----------------------------------------------
	;ispitujemo koji broj je prosledjen proceduri(pritisnut)
	cmp key, 31h
	je update1
	cmp key, 32h
	je update2
	cmp key, 33h
	je update3
	cmp key, 34h
	je update4
	cmp key, 35h
	je update5
	cmp key, 36h
	je update6
	jmp finish

update1:
	mov dl, cappBillX+8
	mov dh, cappBillY
	call Gotoxy
	mWrite <"   ">					; brisemo prethodnu kolicinu
	call Gotoxy
	xor eax, eax
	mov al, amount
	call WriteDec					; ispisujemo novu kolicinu na ekranu
	jmp finish
update2:
	mov dl, esspBillX+8
	mov dh, esspBillY
	call Gotoxy
	mWrite <"   ">					;brisemo prethodnu kolicinu
	call Gotoxy
	xor eax, eax
	mov al, amount
	call WriteDec
	jmp finish
update3:
	mov dl, cortBillX+8
	mov dh, cortBillY
	call Gotoxy
	mWrite <"   ">					;brisemo prethodnu kolicinu
	call Gotoxy
	xor eax, eax
	mov al, amount
	call WriteDec
	jmp finish
update4:
	mov dl, machBillX+8
	mov dh, machBillY
	call Gotoxy
	mWrite <"   ">					;brisemo prethodnu kolicinu
	call Gotoxy
	xor eax, eax
	mov al, amount
	call WriteDec
	jmp finish
update5:
	mov dl, coffBillX+8
	mov dh, coffBillY
	call Gotoxy
	mWrite <"   ">					;brisemo prethodnu kolicinu
	call Gotoxy
	xor eax, eax
	mov al, amount
	call WriteDec
	jmp finish
update6:
	mov dl, teeBillX+8
	mov dh, teeBillY
	call Gotoxy
	mWrite <"   ">					;brisemo prethodnu kolicinu
	call Gotoxy
	xor eax, eax
	mov al, amount
	call WriteDec
	jmp finish
	
finish:
	ret
updateAmount ENDP

printBill PROC c, key:BYTE, amount:BYTE ;-------------------PRINTING BILL ON THE SCREEN------------------------------------------
	cmp key, 31h
	je print1
	cmp key, 32h
	je print2
	cmp key, 33h
	je print3
	cmp key, 34h
	je print4
	cmp key, 35h
	je print5
	cmp key, 36h
	je print6
	jmp finish

print1:
	cappBillY = billY
	mov dl, cappBillX							; podesavanje koordinata mesta na kome treba ispisati racun
	mov dh, cappBillY
	xor eax, eax
	mov al, amount
	call Gotoxy
	mWrite <"capp   x">
	call WriteDec
	billY = billY+1
	jmp finish
print2:
	esspBillY = billY
	mov dl, esspBillX
	mov dh, esspBillY
	xor eax, eax
	mov al, amount
	call Gotoxy
	mWrite <"essp   x">
	call WriteDec
	billY = billY+1
	jmp finish
print3:
	cortBillY = billY
	mov dl, cortBillX
	mov dh, cortBillY
	xor eax, eax
	mov al, amount
	call Gotoxy
	mWrite <"cort   x">
	call WriteDec
	billY = billY+1
	jmp finish
print4:
	machBillY = billY
	mov dl, machBillX
	mov dh, machBillY
	xor eax, eax
	mov al, amount
	call Gotoxy
	mWrite <"mach   x">
	call WriteDec
	billY = billY+1
	jmp finish
print5:
	coffBillY = billY
	mov dl, coffBillX
	mov dh, coffBillY
	xor eax, eax
	mov al, amount
	call Gotoxy
	mWrite <"coff   x">
	call WriteDec
	billY = billY+1
	jmp finish
print6:
	teeBillY = billY
	mov dl, teeBillX
	mov dh, teeBillY
	xor eax, eax
	mov al, amount
	call Gotoxy
	mWrite <"tee    x">
	call WriteDec
	billY = billY+1
	jmp finish

	finalX = billX
	finalY = billY

finish:
	ret

printBill ENDP

updateCredits PROC c, newCredit:DWORD ;-------------------REFRESHING CREDITS PROCEDURE---------------------------------------------
	mov dl, creditsTitleX+8
	mov dh, creditsTitleY
	mov eax, newCredit
	call Gotoxy
	mWrite <"         ">
	call Gotoxy
	call WriteDec

	ret

updateCredits ENDP

;====================================================================================================================================
;												MAIN PROCEDURE
;====================================================================================================================================
main PROC;
	INVOKE  GetStdHandle, STD_OUTPUT_HANDLE
	mov outHandle, eax													; handle za standardni izlaz
	INVOKE GetStdHandle, STD_INPUT_HANDLE
	mov inHandle, eax

	INVOKE GetConsoleCursorInfo, outHandle, ADDR cursorInfo				
	mov cursorInfo.bVisible,0											; nevidljiv kursor
	INVOKE SetConsoleCursorInfo, outHandle, ADDR cursorInfo				
	INVOKE SetConsoleScreenBufferSize, outHandle, scrSize				; podesavanje screen buffera
	INVOKE SetConsoleWindowInfo, outHandle, TRUE, ADDR windowRect		; podesavanje prozora
	INVOKE SetConsoleTitle, ADDR titlemsg								; podesavanje naslova konzole
	INVOKE GetConsoleScreenBufferInfo, outHandle, ADDR consoleInfo	
	
	;podesavanje boje pozadine i boje teksta:
	mov eax, black + (lightGray*16)
	call SetTextColor
	;--------------------------------------------DRAWING TEXT------------------------------------------------------------------------
	;ispisivanje poruke dobrodoslice na ekranu:
	call Clrscr
	INVOKE SetConsoleCursorPosition, outHandle, welcomePos
	mov edx, OFFSET welcomeTitle
	call WriteString
	mWrite <endl, endl, "		Vas kredit: ">							;cekanje korisnika da unese kredit

	;----------------------------------------INPUT TO INTEGER CONVERSION------------------------------------------------------------
	INVOKE ReadConsole, inHandle, ADDR buffer, buffSize, ADDR bytesRead, 0
	xor edx, edx
	xor eax, eax
	xor esi, esi
	xor edi, edi
	xor ebx, ebx
	mov ecx, bytesRead
	sub ecx, 2								; oduzimamo 2 zbog EDNL
	mov esi, OFFSET buffer
convertstr2int:
	mov ebx, ecx							; EBX predstavlja poziciju(stepen 10) na kom se nalazi cifra
	xor eax, eax
	mov al, [esi]							; u AL smestamo cifru po cifru sa adrese ESI tj. adresa na kojoj se nalazi BUFFER
	sub eax, 30h							; 30h = 48 sto je pozicija nule u ASCII tabeli
	sub ebx, 1								; oduzimamo jer nam jacine cifara krecu od 0
	jz addition								; ukoliko je jacina cifre 0, preskacemo mnozenje stepenom desetke
	inc esi									; uvecavamo ESI kako bismo u narednoj iteraciji dohvatili sledecu cifru	
calc:										; mnozenje stepenom broja 10 u zavisnosti na kojoj se poziciji nalazi cifra
	mov edi, 10
	mul edi
	dec ebx
	cmp ebx, 0
	jnz calc
addition:									; dodajemo prozivod na vec postojece kredite
	add credits, eax
	loop convertstr2int
	;--------------------------------------------------------------------------------------------------------------------------------
	call ClrScr

	;ispisivanje liste proizvoda:
	push OFFSET prodTitle
	push productListX+1
	push productListY+1
	call print
	add esp, 12

	;ispivanje racuna:
	push OFFSET billTitle
	push billTitleX
	push billTitleY
	call print
	add esp, 12

	;ispisivanje secera:
	push OFFSET sugarTitle
	push sugarX
	push sugarY
	call print
	add esp, 12

	;ispisivanje skale za secer:
	mov dl, sugarLevelX
	mov dh, sugarLevelY
	call Gotoxy
	mov al, 205
	call WriteChar
	inc dl
	inc dl
	xor ecx, ecx
	mov cl, sugarLevel						; smestamo nivo secera u CL kako bi se petlja printSq ponavljala
printSq:									; sve dok se ne istampa onoliko kvadratica koliki je nivo secera
	call Gotoxy
	mov al, 254
	call WriteChar
	inc dl
	inc dl
	loop printSq							; stampa kvadratic onoliko puta koliki je nivo secera

	xor eax, eax
	mov eax, 5
	sub al, sugarLevel						; ostatak do 5 popunjavamo crticama
	xor ecx, ecx
	mov cl, al
printMin:
	call Gotoxy
	mov al, 45
	call WriteChar
	inc dl
	inc dl
	loop printMin
	mov al, 206
	call Gotoxy
	call WriteChar
	

	;ispisivanje kredita:
	push OFFSET creditsTitle
	push creditsTitleX
	push creditsTitleY
	call print
	add esp, 12
	mov eax, credits
	mov dl, creditsTitleX+8
	mov dh, creditsTitleY
	call Gotoxy
	call WriteDec


	;ispisivanje kusura:
	push OFFSET changeTitle
	push changeTitleX
	push changeTitleY
	call print
	add esp, 12
	mov eax, credits
	mov change, eax
	;--------------------------------------------------DRAWING RECTANGLES----------------------------------------------------------
	;prosledjivanje koordinata za iscrtavanje okvira za proizvode:
	push WORD PTR productListX
	push WORD PTR productListY											
	push WORD PTR billInfoX-1
	push WORD PTR windY
	call drawRect
	add esp, 8

	;prosledjivanje koordinata za iscrtavanje okvira za informacije o racunu;
	push WORD PTR billInfoX
	push WORD PTR billInfoY
	push WORD PTR windX
	push WORD PTR 10
	call drawRect
	add esp, 8

	;prosledjivanje koordinata za iscrtavanje okvira za informacije o kusuru:
	push WORD PTR changeInfoX
	push WORD PTR changeInfoY
	push WORD PTR windX
	push WORD PTR windY
	call drawRect
	add esp, 8

	;-----------------------------------------INTERACTION WITH USER----------------------------------------------------------------
xor eax, eax
waiting:						; cekamo na unos broja proizvoda
	mov eax, 10
	call Delay
	call ReadKey
	jz waiting

	push eax
	call detect					; pozivamo proceduru koja vrsi detekciju pritisnutog broja
	add esp, 4
	jmp waiting					; cekamo novi unos sve dok ne stisnemo ESC
	

main ENDP
END main
