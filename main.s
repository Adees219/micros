; Archivo:  main.s
; Dispositivo:  PIC16F887
; Autor: Anderson Escobar
; Compilador: pic-as (v2.4), MPLABX V6.05
; 
; Programa: contador en el puerto A
; Hardware: LEDs en el puerto A
; 
; Creado: 23 ene, 2023
; Última modificación: 23 ene, 2023

PROCESSOR 16F887
#include <xc.inc>
    
;configuration Word 1
CONFIG FOSC=INTRC_NOCLKOUT
CONFIG WDTE=OFF
CONFIG PWRTE=ON
CONFIG MCLRE=OFF
CONFIG CP=OFF
CONFIG CPD=OFF
    
CONFIG BOREN=OFF
CONFIG IESO=OFF
CONFIG FCMEN=OFF
CONFIG LVP=ON

;configuration word 2
CONFIG WRT=OFF
CONFIG BOR4V=BOR40V

PSECT udata_bank0
    cont_small: DS 1
    cont_big: DS 1
    
    
PSECT resVect, class=CODE, abs, delta=2
;---------------------Vector reset-------------------
ORG 00h
resetVec:
    PAGESEL main
    goto main

    
PSECT code, delta=2, abs
ORG 100h
;-------------------configuración-----------
main:
    bsf	    STATUS, 5
    bsf	    STATUS, 6
    clrf    ANSEL
    clrf    ANSELH
    
    bsf	    STATUS, 5
    bcf	    STATUS, 6
    clrf    TRISA
    
    bcf	    STATUS, 5
    bcf	    STATUS, 6
    
loop:
    incf    PORTA, 1
    call    delay_big
    goto    loop
  
    
;---------sub rutinas---------------    
delay_big:
    movlw   198		;(1)
    movwf   cont_big	;(1)
    call    delay_small	;(2)
    decfsz  cont_big, 1 ;1(2)
    goto    $-2 ; (2)
    return  ;(2)
    
delay_small:
    movlw   165 ;(1)
    movwf   cont_small ;(1)
    decfsz  cont_small, 1 ;1(2)
    goto    $-1 ;(2)
    return ;(2)
    
END
    