; Archivo: tablas_timer0.s
; Dispositivo: PIC16F887
; Autor: Anderson Escobar
; Compilador: pic-as (v2.4), MPLABX V6.05
; 
; Programa: contador activado por tmr0
; Hardware: leds puerto A
; 
; Creado: 05 feb, 2023
; Última modificación: 06 feb, 2023

PROCESSOR 16F887
#include <xc.inc>;libreria

    
; CONFIG1
  CONFIG  FOSC = INTRC_NOCLKOUT ; Oscillator Selection bits (INTOSCIO oscillator: I/O function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
  CONFIG  WDTE = OFF            ; Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
  CONFIG  PWRTE = ON            ; Power-up Timer Enable bit (PWRT enabled)
  CONFIG  MCLRE = OFF           ; RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
  CONFIG  CP = OFF              ; Code Protection bit (Program memory code protection is disabled)
  CONFIG  CPD = OFF             ; Data Code Protection bit (Data memory code protection is disabled)
  CONFIG  BOREN = OFF           ; Brown Out Reset Selection bits (BOR disabled)
  CONFIG  IESO = OFF            ; Internal External Switchover bit (Internal/External Switchover mode is disabled)
  CONFIG  FCMEN = OFF           ; Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
  CONFIG  LVP = ON              ; Low Voltage Programming Enable bit (RB3/PGM pin has PGM function, low voltage programming enabled)

; CONFIG2
  CONFIG  BOR4V = BOR40V        ; Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
  CONFIG  WRT = OFF             ; Flash Program Memory Self Write Enable bits (Write protection off)


PSECT udata_bank0 ;se apartan los bytes en el banco
    cont_small: DS 1 ; 1 byte
    cont_big: DS 1
   
    
PSECT resVect, class=CODE, abs, delta=2
 ;----------------vector reset---------------
 ORG 00h
 resetVec:
    PAGESEL setup 
    goto setup ;inicio del programa
    
 PSECT code, delta=2, abs
 ORG 100h 
 ;-----------------configuracion--------------
 setup: ;llama a la subrutinas de configuración
    call config_io ;input/output
    call config_osc ;oscilador/reloj
    call config_tmr0 ;timer0
    
 ;------------------ loop---------------------   
 loop:
    call contador_tmr0
    
    btfsc PORTB, 0 ;comprueba que el pin 0 del puerto B este presionado (1) si es así ejecuta la siguiente instrucción de lo contrario la salta
    call inc_portC ; llama a la subrutina de incremento del puerto C
    
    btfsc PORTB, 1 ;chequeo pin 1
    call dec_portC ; llama a la subrutina de decremento del puerto C
    
    movf PORTC, W ;mueve el valor del puerto C (contador de botones) al acumulador
    call tabla ;llama a la subrutina tabla
    movwf PORTD ;el valor que devuelve la subrutina la muestra en el puerto D
    
    goto loop
    
    
;---------------------subrutinas setup-------------------
 config_io:
    banksel ANSEL
    clrf ANSEL	   
    clrf ANSELH ;configuración de pines digitales
    
    banksel TRISA
    movlw 0b11110000 ; se selecciona un valor de byte que configure a los bits del TRIS como entradas o salidas
    movwf TRISA	    ;  configura los 4 bits más significativos como entradas
    clrf TRISC	; puerto c como salida
    clrf TRISD
    
    bsf	TRISB, 0   ; Se configuran 2 pines del puerto B como entradas
    bsf TRISB, 1
    
    bcf STATUS, 5
    bcf STATUS, 6   ;banco 00
    clrf PORTA	    ;Limpiamos el puerto A y B
    clrf PORTC
    clrf PORTD
    return
    
config_osc:
    banksel OSCCON ;configuración del registro OSCCON para el oscilador
    bsf IRCF2
    bcf IRCF1
    bcf IRCF0 ; oscilador a 1MHz 
    bsf SCS  ; reloj interno
    return

config_tmr0:
    banksel OPTION_REG
    bcf T0CS ;timer como WDT
    bcf PSA ; asignación de prescaler al tmr0
    
    bsf PS2
    bsf PS1
    bsf PS0 ; razón de prescaler a 256
    
    banksel PORTA
    call reinicio_tmr0
    return 
;----------subrutinas loop----------
contador_tmr0:
    btfss  T0IF ;salta cuando es T0IF devuelve 1
    goto $-1
    call reinicio_tmr0
    incf PORTA
    return
    
reinicio_tmr0: 
    movlw 158
    movwf TMR0
    bcf T0IF ;se apaga la bandera de interrupción (no detecta overflow)
    return
   
inc_portC:
    call delay_small ;hace un delay para aprovechar los tiempos entre instrucciones
    btfsc PORTB, 0 ; (anti-rebote)comprueba si el boton que llamo a la rutina dejo de ser presionado
    goto $-1	    ;vuelve a la línea anterior
    incf PORTC	; incrementa el valor del puerto C
   
    return	;sale de la subrutina y regresa al loop
    
dec_portC:
    call delay_small
    btfsc PORTB, 1
    goto $-1
    decf PORTC	;decrementa el valor del puerto C
   
    return
    
    
delay_small:
    movlw   150
    movwf   cont_small
    decfsz  cont_small, 1 
    goto    $-1 
    return 

tabla: 
    CLRF PCLATH
    BSF PCLATH, 0
    ANDLW 0X0F
    ADDWF PCL ;PCL + PCLATH (W con PCL) PCL adquiere ese nuevo valor y salta a esa linea
    ;valores que regresa
    retlw 00111111B ;0
    retlw 00000110B ;1
    retlw 01011011B ;2
    retlw 01001111B ;3
    retlw 01100110B ;4
    retlw 01101101B ;5
    retlw 01111101B ;6
    retlw 00000111B ;7
    retlw 01111111B ;8
    retlw 01101111B ;9
    retlw 01110111B ;A
    retlw 01111100B ;B
    retlw 00111001B ;C
    retlw 01011110B ;D
    retlw 01111001B ;E
    retlw 01110001B ;F
END


