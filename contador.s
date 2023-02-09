; Archivo: contador.s
; Dispositivo: PIC16F887
; Autor: Anderson Escobar
; Compilador: pic-as (v2.4), MPLABX V6.05
; 
; Programa: contador en el puerto A
; Hardware: LEDs en el puerto A
; 
; Creado: 30 ene, 2023
; Última modificación: 30 ene, 2023

PROCESSOR 16F887
#include <xc.inc> ;librería
    
;configuration Word 1
CONFIG FOSC=INTRC_NOCLKOUT
CONFIG WDTE=OFF
CONFIG PWRTE=OFF
CONFIG MCLRE=OFF
CONFIG CP=OFF
CONFIG CPD=OFF
    
CONFIG BOREN=OFF
CONFIG IESO=OFF
CONFIG FCMEN=OFF
CONFIG LVP=OFF

;configuration word 2
CONFIG WRT=OFF
CONFIG BOR4V=BOR40V

PSECT udata_bank0 ;se apartan los bytes en el banco
    cont_small: DS 1 ; 1 byte
    cont_big: DS 1
    suma: DS 1
   
    
PSECT resVect, class=CODE, abs, delta=2
 ;----------------vector reset---------------
 ORG 00h
 resetVec:
    Pagesel main ;selección de pagina
    goto main
 PSECT code, delta=2, abs
 ORG 100h 
 ;-----------------configuracion--------------
 main:
    call config_io ;llama a la subrutinas de configuración
    call config_reloj
    banksel PORTA
 ;----------------loop principal--------------
loop_1: 
    ; contador 1
    btfsc PORTB, 0 ;comprueba que el pin 0 del puerto B este presionado (1) si es así ejecuta la siguiente instrucción de lo contrario la salta
    call inc_porta ; llama a la subrutina de incremento del puerto a
    
    btfsc PORTB, 1 ;chequeo pin 1
    call dec_porta ; llama a la subrutina de decremento del puerto a
    
    ; contador 2
    btfsc PORTB, 2 ;chequeo pin 2
    call inc_portc ; llama a la subrutina de incremento del puerto c
    
    btfsc PORTB, 3 ;chequeo pin 3
    call dec_portc  ; llama a la subrutina de decremento del puerto c
 
    ;sumador
    btfsc PORTB, 4 ;chequeo pin 4
    call sumador  ; llama a la subrutina de la sumatoria
    
    call delay_big ;llama a la subrutina de delay para aprovechar los tiempos
    goto loop_1    ;se llama a si mismo para ejecutarse siempre (loop infinito)
 ;-------------------sub rutinas--------------
 inc_porta:
    call delay_small ;hace un delay para aprovechar los tiempos entre instrucciones
    btfsc PORTB, 0 ; (anti-rebote)comprueba si el boton que llamo a la rutina dejo de ser presionado
    goto $-1	    ;vuelve a la línea anterior
    incf PORTA	; incrementa el valor del puerto A 
    return	;sale de la subrutina y regresa al loop
    
dec_porta:
    call delay_small
    btfsc PORTB, 1
    goto $-1
    decf PORTA	;decrementa el valor del puerto A
    return

inc_portc:
    call delay_small
    btfsc PORTB, 2
    goto $-1
    incf PORTC ;incrementa el valor del puerto C
    return
    
dec_portc:
    call delay_small
    btfsc PORTB, 3
    goto $-1
    decf PORTC ;decrementa el valor del puerto C
    return
    
sumador:
    btfsc PORTB, 4  
    goto $-1
    movf PORTA, 0 ;guarda el valor de PORTA a W
    addwf PORTC, 0 ;suma el valor del PORTC con el registro W (actualmente con valor de portA, es decir PORTA + PORTC) 
    movwf PORTD ;guarda el valor de la suma en el puerto D
    return
    
delay_big:
    movlw   50		;(1)
    movwf   cont_big	;(1)
    call    delay_small	;(2)
    decfsz  cont_big, 1 ;1(2)
    goto    $-2 ; (2)
    return  ;(2)
    
delay_small:
    movlw   150 ;(1)
    movwf   cont_small ;(1)
    decfsz  cont_small, 1 ;1(2)
    goto    $-1 ;(2)
    return ;(2)
   
;-----------------configuración pic-----------  
config_io:
    bsf STATUS, 5 
    bsf STATUS, 6   ; banco 0b11 (3)
    clrf ANSEL	   ; configuración de pines digitales
    clrf ANSELH
    
    bsf STATUS, 5
    bcf STATUS, 6   ;banco 0b01 (1)
    // clrf TRISA
    movlw 0b11110000 ; se selecciona un valor de byte que configure a los bits del TRIS como entradas o salidas
    movwf TRISA	    ;  configura los 4 bits más significativos como entradas
    movlw 0b11110000 
    movwf TRISC
    movlw 0b11100000 
    movwf TRISD ; se configuran los 3 bits más significativos como entrada
    
    ; Se configuran 5 pines del puerto B como entrada
    bsf	TRISB, 0    
    bsf TRISB, 1
    bsf	TRISB, 2
    bsf TRISB, 3
    bsf	TRISB, 4 
 /* movlw 0b00011111
    movwf TRISB*/
    
    
    bcf STATUS, 5
    bcf STATUS, 6   ;banco 00
    clrf PORTA	    ;Limpiamos los puertos A, C y D (valor inicial 0)
    clrf PORTC
    clrf PORTD
    return
    
config_reloj:
    banksel OSCCON ;configuración del registro OSCCON para el oscilador
    bsf IRCF2
    bcf IRCF1
    bcf IRCF0   ; oscilador a 1Mhz
    bsf SCS  ; reloj interno
    return

 
END

    

    

