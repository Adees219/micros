; Archivo: interrupciones
; Dispositivo: PIC16F887
; Autor: Anderson Escobar
; Compilador: pic-as (v2.4), MPLABX V6.05
; 
; Programa: contador utilizando interrupciones
; Hardware: leds (RA), botones (RB), displays
; 
; Creado: 12 feb, 2023
; Última modificación: 13 feb, 2023

PROCESSOR 16F887
#include <xc.inc>


; CONFIG1
  CONFIG  FOSC = INTRC_CLKOUT   ; Oscillator Selection bits (INTOSC oscillator: CLKOUT function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
  CONFIG  WDTE = OFF            ; Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
  CONFIG  PWRTE = OFF           ; Power-up Timer Enable bit (PWRT disabled)
  CONFIG  MCLRE = OFF           ; RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
  CONFIG  CP = OFF              ; Code Protection bit (Program memory code protection is disabled)
  CONFIG  CPD = OFF             ; Data Code Protection bit (Data memory code protection is disabled)
  CONFIG  BOREN = OFF           ; Brown Out Reset Selection bits (BOR disabled)
  CONFIG  IESO = OFF            ; Internal External Switchover bit (Internal/External Switchover mode is disabled)
  CONFIG  FCMEN = OFF           ; Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
  CONFIG  LVP = OFF             ; Low Voltage Programming Enable bit (RB3 pin has digital I/O, HV on MCLR must be used for programming)

; CONFIG2
  CONFIG  BOR4V = BOR40V        ; Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
  CONFIG  WRT = OFF             ; Flash Program Memory Self Write Enable bits (Write protection off)



PSECT udata_bank0 ;se apartan los bytes en el banco
vueltas: DS 1
unidad: DS 1
decena: DS 1
    
PSECT udata_shr ;variables que se protegen los bits de status 
W_TEMP: DS 1
STATUS_TEMP: DS 1
    
PSECT resVect, class=CODE, abs, delta=2
    

 ;----------------vector reset---------------
    ORG 00h
resetVec:
    PAGESEL setup 
    goto setup ;inicio del programa
    
 PSECT code, delta=2, abs
    
 ;--------------macros------------   
 reinicio_tmr0 macro
    movlw 246 ; literal para que tmr0 tarde 10 ms
    movwf TMR0
    bcf T0IF ;bandera if apagada
 endm
        

    
 ;------------- rutina interrupcion--------
 ORG 04h
push:
    movwf W_TEMP ; copia W al registro temporal
    swapf STATUS, W ; intercambio de nibbles y guarda en W
    movwf STATUS_TEMP; guarda status en el registro temporal
 
isr: ; rutina de interrupcion
   
    ;contador push_buttons
   btfsc RBIF   
   call cont_iocb
  
  ;contador tmr0
  /* btfsc T0IF	
   call incr_tmr0*/
  
  ;cronometro segundos_tmr0
   btfsc T0IF	
   call cronometro

pop: 
    swapf STATUS_TEMP, W ;intercambio nibbles y guarda en W
    movwf STATUS	 ;mueve W a STATUS
    swapf W_TEMP, F	;intercambio nibbles y guarda en W temporal
    swapf W_TEMP, W	;intervambio nibbles y guarda en W
   
    retfie ;salida de la interrupcion
    
    
    
    
 ;------------------subrutina interrupcion-------------
 cont_iocb:
    banksel PORTA
    btfss PORTB, 0
    incf PORTA
    btfss PORTB, 1
    decf PORTA
    bcf RBIF
    return

/*incr_tmr0:
   reinicio_tmr0
   incf vueltas
   movf vueltas, W
   sublw 100 ;resta a la literal
   btfss STATUS, 2 ;comprueba la bandera zero
   goto $+3 ;sale
   clrf vueltas
   incf PORTC
   return
   */
    
cronometro:
    
    
   reinicio_tmr0
   incf vueltas ;lleva el conteo de las vueltas que ha realizado
   movf vueltas, W ;pasa el conteo de vueltas a W
   sublw 100 ;resta a la literal el valor de W, como tmr0 va a 0.01 s y 100 vueltas (100*0.01 = 1s)
   btfss STATUS, 2 ;comprueba la bandera zero
   goto $+20 ;zero = 0: sale de la subrutina ; zero = 1: salta esta instruccion
   clrf vueltas ;reinicia el conteo de vueltas
   
   ;incremento unidades
  
   incf unidad ;incrementa el contador de unidad de segundos
   movf unidad, W ;pasa el valor a W
   sublw 10 ;resta a la literal el valor de W, como unidad < 10, si unidad=10 debe reiniciarse
   btfss STATUS, 2 ;comprueba la bandera zero
   goto $+3 ;zero = 0: no reinicia (limpia) la variable de unidad e incremento de unidad ; zero = 1: salta esta instruccion
   clrf unidad ;reinicia la variable de unidad
   incf decena ;incrementa el contador de decena de segundos
   
   
   ;incremento decenas
   
   movf decena, W  ;pasa el valor a W
   sublw 6 ;resta a la literal el valor de W, como temporizador ? 60, si decena = 6 debe reiniciarse
   btfss STATUS, 2;comprueba la bandera zero
   goto $+2 ;zero = 0: no reinicia (limpia) la variable de decena ; zero = 1: salta esta instruccion
   clrf decena ;reinicia la variable de decena
   
   
   ;displays
   movf unidad, W ;toma el valor de la variable
   call tabla	; llama a la subrutina tabla donde se opera W
   movwf PORTD ; muestra el valor devuelto en la subrutina, guardado en W
   
   movf decena, W
   call tabla
   movwf PORTC
  
   return
    
 
 PSECT code, delta=2, abs
 ORG 100h
 ;------------------tablas---------------------
 tabla: 
    CLRF PCLATH
    BSF PCLATH, 0
    ANDLW 0X0F ;restriccion para que no exceda el valor 15
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
    
    
    
 ;-----------------configuracion--------------
setup:
    call config_io	    ;input/output
    call config_reloj	    ;oscilador/reloj
    call config_int_enable  ; interrupciones
    call config_iocrb	    ; interrupt-on-change
    call config_tmr0	;timer0
    
    
    banksel PORTA

 ;-------------loop-----------------------
 loop:
    goto loop
 
 ;-------------subrutinas setup----------------
config_iocrb:
    banksel TRISA
    bsf IOCB0   ;interrupt-on-change 1:enabled
    bsf IOCB1
    
    banksel PORTA
    movf PORTB, W ;cuando lee, termina la condicion de mismatch
    bcf RBIF
    return
 
config_io:
    banksel ANSEL
    clrf ANSEL
    clrf ANSELH ;entradas digitales
 
    banksel TRISA
    movlw 11110000B ;4 entradas/ 4 salidas
    movwf TRISA
   /* movlw 11110000B ;4 entradas/ 4 salidas
    movwf TRISC*/
   
   ;salidas displays
   clrf TRISC 
   clrf TRISD
    
    ; entradas
    bsf TRISB, 0
    bsf TRISB, 1
    
    
    bcf OPTION_REG, 7 ;habilita los pull-ups del puerto B
    bsf WPUB0 ;pull-ups internos 1: enabled
    bsf WPUB1
    
    banksel PORTA
    clrf PORTA ;init val
    clrf unidad
    clrf vueltas
    clrf decena
    clrf PORTB
    clrf PORTC
    clrf PORTD
    return
    
config_reloj:
    banksel OSCCON
    bsf IRCF2	
    bcf IRCF1
    bcf IRCF0 ; 1MHz
    bsf SCS ;reloj interno
    return
   
config_int_enable:
    bsf GIE ;global interrupt enable
    bsf T0IE ; tmr0 interrupt enable
    bcf T0IF ; bandera interrupcion
    bsf RBIE  ; RB interrupt enable
    bcf RBIF ;bandera interrupcion
    return
    
  
    
config_tmr0:
    banksel OPTION_REG
    bcf T0CS ;mode: temporizador
    bcf PSA ;prescaler para temporizador
    
    bsf PS2
    bsf PS1
    bsf PS0 ;prescaler 256 
    
    banksel PORTA
    reinicio_tmr0 ;llama a la macro
    return
    
 

    
