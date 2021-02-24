
 ; 1: load the 16 bit number 0x0102 into memory locations 0x10 and 0x20
 ; 2: load the 16 bit number 0x05ff into memory location 0x11 and 0x21
 ; 3: add the 2 16 bit numbers previously loaded and store the result into memory locations 0x12 and 0x22
  
 ;-------------------------------------------------------------------------------
 num1    equ     0x0102  ; First number
 num2    equ     0x05FF  ; Second number
  
 op1l    equ     0x10    ; First operand address in memory, lower byte (LSB)
 op1h    equ     0x20    ; First operand address in memory, higher byte (MSB)
  
 op2l    equ     0x11    ; Second operand address in memory, lower byte (LSB)
 op2h    equ     0x21    ; Second operand address in memory, higher byte (MSB)
  
 resl    equ     0x12    ; Result address in memory, lower byte (LSB)
 resh    equ     0x22    ; Result address in memory, higher byte (MSB)
 
 ;-------------------------------------------------------------------------------
 #include <p18F8720.inc>
  
         org     0x00
         goto    start 
   
         org     0x08 
         retfie 
  
         org     0x18 
         retfie
   
 start:
         movlw   high num1       ; Load a first number's MSB to WREG
         movwf   op1h            ; Store it in its memory location
         movlw   low num1        ; Load a first number's LSB to WREG
         movwf   op1l            ; Store it in its memory location
  
         movlw   high num2       ; Load a second number's MSB to WREG
         movwf   op2h            ; Store it in its memory location
         movlw   low num2        ; Load a second number's LSB to WREG
         movwf   op2l            ; Store it in its memory location, WREG also contains it
  
         addwf   op1l,w          ; Add WREG (=num2 LSB) to a num1 LSB, result in WREG
         movwf   resl            ; Store a result LSB in its memory location
  
         movf    op1h,w          ; Load a num1 MSB to WREG
         addwfc  op2h,w          ; Add a num2 MSB to it with carry remembered from a previous LSB addition
         movwf   resh            ; Store a result MSB in its memory location
  
         end
 