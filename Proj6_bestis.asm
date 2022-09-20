TITLE Program Template     (template.asm)

; Author: Isaac Best
; Last Modified: 8/4/22
; OSU email address: bestis@oregonstate.edu
; Course number/section:   CS271 Section 400
; Project Number:      6           Due Date: 8/12/22
; Description: This program utilizes 2 macros wich are then used in 2 proceedures to convert strings to integers calculates the sum and average and then
; uses those integers calcualted to convert them back to strings so the mdisplaystring macro can print them to the user And also displats the list of inputted 
; integers as a sequence of strings 

INCLUDE Irvine32.inc

; Name: mGetString
; description of procedure:  this macro displays a string to the user to promt them to input integers, it than taks those call's readstring and outputs the string read
; into the EDX which is the address of a list and than moves the EAX into char_types by dereferncing 
; preconditoins: this macro is passed a string address, array of bytes for storage of the string that is read and a char typed variable for storage 
; postconditions: returns the string in the temporary array, also returns the size of the string read as an integer in the char_typed variable 
; recieves: promt_address, str_mem_arr , char_typed 
; returns: str_mem_arr = address of user string and char_typed = number of chatacters enetered 
mGetString MACRO promt_address, str_mem_arr , char_typed 
	push	ecx
	push	eax
	push	ebx

	mov		edx, promt_address
	call	WriteString
	mov		ecx, MAX_BUFFER					; max bytes readable constant
	mov		edx, str_mem_arr				; address of a list / buffer 
	call	ReadString						; lodsb to advance pointer (string primitive)
	mov		ecx, char_typed                 ; derefernce
    mov     [ECX], EAX

	pop		ebx
	pop		eax
	pop		ecx
ENDM

; Name: mDisplayString
; description of procedure: this macro is given a string address and prints it
; preconditoins: string to display (address)
; postconditions: string is displayed to user 
; recieves: string address
; returns N/A 
mDisplayString MACRO str_addr
	push	edx

	MOV		edx, str_addr
	CALL	WriteString 

	pop		edx
ENDM

MAX_BUFFER		EQU 100 
LO				equ -2147483648
HI				equ 2147483647


.data
title_1				BYTE	"PROGRAMMING ASSIGNMENT 6: Designing low-level I/O procedures" ,13,10 
					BYTE	"Written by: Isaac Best" ,13,10,0
descr				BYTE	"Please provide 10 signed decimal integers."  ,13,10
					BYTE	"Each number needs to be small enough to fit inside a 32 bit register." ,13,10
					BYTE	"After you have finished inputting the raw numbers I will display a " ,13,10
					BYTE	"list of the integers, their sum, and their average value." ,13,10,0
array_1				SDWORD	10 DUP (?) 
inp_promt			BYTE	"Please enter an signed number: " ,0 
error_str			BYTE	"ERROR: You did not enter a signed number or your number was too big. " ,13,10,0
temp_char			SDWORD	?
temp_str_arr		BYTE	(MAX_BUFFER +1) DUP (?)
out_put_arr			BYTE	(max_buffer -1) DUP (?)
sum_title			BYTE	"The sum of these numbers is: " ,0
avg_title			BYTE	"The truncated average is: " ,0 
goodbye				BYTE	"Thanks for playing!" ,0 
space				BYTE	" " ,0 
sum_1				sdword	?


.code
main PROC 

	push			OFFSET title_1				; set up and call my intro procedure 
	push			OFFSET descr
	call			intro					 


; start of my get data from user loop 
_get_data:										
	mov				ecx, 10 
	mov				edi, OFFSET array_1 
_int_input_loop:
	push			offset temp_char			; ebp 20
	push			OFFSET inp_promt			; ebp 16 address input promt
	push			OFFSET error_str			; ebp 12 address error msg 
	push			offset temp_str_arr			; ebp 8 addres of list
	call			readVal

	mov				[edi], edx					; add the verfifed value to the list 
	add				edi, 4
	loop			_int_input_loop 		



	call			crlf
	; prints the array 
	MOV			ESI, offset array_1							
	MOV			ECX, 10										
	_PrintArr:
	MOV			EAX, [ESI] 
	push		ecx								; pop ecx to save register 
	push		offset out_put_arr
	push		eax
	CALL		WriteVal
	pop			ecx 
	MOV			AL, " "
	CALL		WriteChar
	ADD			ESI, 4
	LOOP		 _PrintArr
	call		crlf 
	





; this will calculate the sum of the array 
	call			crlf
	mdisplaystring	offset sum_title
_sum:
	mov				esi, offset array_1			; address list
	mov				ecx, 10						; number of elements
	mov				eax, 0						; eax holds total
_add_loop:
	mov				ebx, [esi]
	add				eax, ebx 
	add				esi, 4
	loop			_add_loop 	
	mov				sum_1, eax					;global in main to hold sum function doesn't save
	push			offset out_put_arr
	push			eax
	call			WriteVal					
	call			crlf 
	mov				eax, sum_1					




; this will calculate the truncated average EAX already has the sum THIS IS NOT SET UP PROPERLY ??? IDIV IS ONLY GIVING ME #1 ????
	mdisplaystring	offset avg_title
_average:
	mov				ecx, 10						; move divisor into ecx
	cdq											; extend 
	idiv			ecx
	push			offset out_put_arr
	push			eax
	call			WriteVal					
	call			crlf 




; print the good bye message
	mdisplaystring offset goodbye
	call			crlf 


	Invoke ExitProcess,0	; exit to operating system
main ENDP

; Name: intro
; description of procedure: simply prints the introduction of the program to the user
; preconditoins: strings to be defined in the data section and passed as an address 
; postconditions: displays a message to the user 
; recieves: this recieves two string addresses
; returns: this procedure does not change anything
intro PROC
	push			ebp 
	mov				ebp, esp
	
	mdisplaystring	[EBP + 12]
	call			crlf 
	mdisplaystring	[ebp + 8] 
	call			Crlf 

	pop				ebp
	ret	8
intro ENDP 



; Name: ReadVal 
; description of procedure: takes a string uses a macro and gets the size and string that was read in a temp array, it stores the array address + count so I can use STD and 
; decrement starting from the 'right hand' side of an array, it then validates each integer checking if its greater 
; than or less than the ASCII equivalent of 0 and 9, it than converts the byte to the integer equivalent by subtracting 48 and than using the digits place counter (EBX) to multiply 
; by the proper amount ebx is 1 -> 10 -> 100. Since I used STD to move right to left the sign is calculated last and my running total is just * -1 if a negative ASCII equivalent 
; is found I than have over flow testing before the value is returned 
; preconditoins: everything in the recieves must be passed as an OFFSET
; postconditions: a valid integer is passed back from the function 
; recieves: temp_char (holds the byes read from macro as integer) inp_promt(input promt for the macro as address) error_str (holds the error message a address) 
; temp_str_arr (holds the string as an array of bytes to be decremeneted) 
; returns: this returns a validated integer to the main 

; string pointer, decremented with lodsb - esi
; current char - eax
; digit place - ebx
; total - edx
; i - ecx
ReadVal PROC
	push			ebp
	mov				ebp, esp 
	push			ecx					; need to keep loop countr for 10 elements working


; this macro returns a number of bytes read in EBP 20 (temp_char) and EDX register of what was read 
_start:
	mGetString [ebp + 16],  [ebp + 8], [EBP + 20] 

; validate the user input 
_validate:
	mov				ebx, 1				; place = 1
	mov				edx, 0				; total = 0
	mov				ecx, [EBP + 20] 	; moves bytesRead into ecx
	mov				ecx, [ecx]          ; ecx = *ecx
	mov				esi, [ebp + 8]		; move address of list into esi for lodsb 
	add             esi, ecx			; esi += ecx (points esi to the end of the string)
	dec				esi
	std									; set direction forward 
	
_digits: 
	lodsb								; loads the current character pointed to by esi into eax
	movsx			eax, al		
	cmp				al, 48				; if str < then ascii 0 
	jl				_nondigit				
	cmp				al, 57				; if str > ascii 9 
	jg				_nondigit

	sub				al, 48 				; converts from a char to an int
	
	imul			eax, ebx			; multiply the digit by the place
	add				edx, eax			; total += place
	JO				_error				; jump overflow 
	imul			ebx, 10				; place *= 10
	JO				_error

	LOOP			_digits				

	; after converting the digits, check the sign (could be '+', '-' or none (null)
	lodsb
_nondigit:	
	cmp				al, 45				;ASCII - sign 
	je				_minus
	cmp				al, 43				;ASCII + sign
	je				_return
	cmp				al, 0
	je				_return
	jmp				_error
_minus:
	imul			edx, -1
	jmp				_return

_error:
	mdisplaystring [ebp + 12] 
	JMP				_start

_return:							
	cmp				edx, LO				; checks for overlow with conditional jump WHY DOESN'T THIS WORK
	JL				_error
	cmp				edx, HI
	JG				_error


	pop				ecx 
	pop				ebp 
	ret 16
ReadVal ENDP



; Name: WriteVal 
; description of procedure: this procedure negates ALL negatives for calculations, it divides the input value by 10 until its < 0 to find the amount of digits the value is
; than it adds it to the EDI as we use STD to move from right to left, it adds a null terminator to the right end, then calculates each digit by taking the input
; dividing by 10 appending the remainder to a temp list (add 48 to AL for offset) then repeats with the qoutient until the qoutient is 0. It then adds a sign comparing the orginal value
; to 0 and adding a + or - (appending a + bc can't start on a sritng on an empty byte) it than calls the mdisplaystring and prints the input parameter as a string 
; preconditoins: passsed a value by parameter, passed a temp byte array 
; postconditions: prints a message 
; recieves: out_put_arr (byte array by address) EAX register with a value 
; returns: does not returns a value (string is printed in function) 

WriteVal PROC
	push			ebp
	MOV				ebp, esp 

	mov				edi, [ebp + 12]			; address of out_put_array 
	mov				eax, [ebp + 8]			; address of input 
	STD										; set direction flag right to left

	cmp				eax, 0					; for calculations negate negative numbers
	jl				_negate
	jmp				calc_digits_1
_negate:									
	neg				eax 


calc_digits_1:

	mov				ecx, 0					; start digit counter at 0
_calc_digits:								; here we divide until we find the amount of digits place divide until 0 is in qoutient 
	mov				ebx, 10
	mov				edx, 0 
	div				ebx 
	inc				ecx
	cmp				eax, 0
	jne				_calc_digits	



	inc				ecx						; adding one to ecx, this now represents how many bytes to add to edi to start on the rhs
	add				edi, ecx				; here we get the end of the string as we are decrementing with STD
	mov				eax, 0					; add a null term to the end 
	stosb
	mov				eax, [ebp + 8]			; load the value of the integer into eax



	cmp				eax, 0					; for negatives negate calculations 
	jl				negate_2
	jmp				_start 
negate_2:									
	neg				eax




_start:
	mov				ebx, 10					; set up divisor
	mov				edx, 0					; set up div per rules 
	div				ebx 
	xchg			eax, edx				; put the remainder in eax so I can use AL and add
	mov				ecx, edx				; piutting the qoutient in ecx 
	add				al, 48					; add 48 offset to ASCII qoutient 
	stosb 
	xchg			edx, eax				; put them back 
	mov				eax, ecx				;restore eax bc we added a offset 

	cmp				eax, 0
	jne				_start					; if not equal divide again 


; after moving everything into the array check for negative and add sign 
	mov				eax, [ebp + 8]			; address of input 
	cmp				eax, 0					
	JL				_minus
; if it wasn't negative, add a + sign
	mov				eax,0
	mov				al, 43
	stosb
	jmp				_return
_minus:					
	mov				eax,0
	mov				al, 45
	stosb


_return:
	mov				edx, [ebp +12]				; print whatever was at the EDI address
	mdisplaystring	edx

	pop				ebp
	ret	8									
WriteVal ENDP

END main
