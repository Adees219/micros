; Archivo: Generador de funciones.s
; Dispositivo: PIC16F887
; Autor: Anderson Daniel Eduardo Escobar Sandoval
; Compilador: pic-as (v2.4), MPLABX V6.05
; 
; Programa: 
; Hardware: 
; 
; Creado: 27 febrero, 2023
; Última modificación: 

processor 16F887
#include <xc.inc>
      
; CONFIG1
  CONFIG  FOSC = INTRC_NOCLKOUT   ; Oscillator Selection bits (INTOSC oscillator: CLKOUT function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
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

;---------------------------macros------------------- 
 reinicio_tmr0 macro
    banksel PORTA
    movlw 100
    movf TMR0
    bcf T0IF
endm 
 
;------------------------variables-------------------
      
PSECT udata_shr ;variables que se protegen los bits de status 
W_TEMP: DS 1	    ;variables para el push-pop
STATUS_TEMP: DS 1

var: DS 1	    ;valor para los displays
flags: DS 1	    ;selector del multiplexado	
display_var: DS 4   ;valor mostrado en los displays    

vueltas: DS 1 //temporalmente
pendiente: DS 1
nivel_pendiente: DS 1
    
mode: DS 1    

    
PSECT resVect, class=CODE, abs, delta=2
     
;------------------------vector reset----------------
ORG 00h
resetVec:
    PAGESEL setup 
    goto setup ;rutina de configuracion

    
    
PSECT code, delta=2, abs
 
;-----------------------interrupciones---------------
 ORG 04h
push:
    movwf W_TEMP ; copia W al registro temporal
    swapf STATUS, W ; intercambio de nibbles y guarda en W
    movwf STATUS_TEMP; guarda status en el registro temporal
 
isr: ; rutina de interrupcion
      
 
   btfsc RBIF
   call change_mode
   
   btfsc T0IF	   ;comprueba la bandera de tmr0
   call	generador
 
      
pop: 
    swapf STATUS_TEMP, W ;intercambio nibbles y guarda en W
    movwf STATUS	 ;mueve W a STATUS
    swapf W_TEMP, F	;intercambio nibbles y guarda en W temporal
    swapf W_TEMP, W	;intervambio nibbles y guarda en W
   
    retfie ;salida de la interrupcion

 
;-------------------------setup----------------------
org 100h
setup:
    call config_io
    call config_tmr0
    call config_reloj
    call config_int_enable
    call config_iocrb
    
    movlw 254
    movwf nivel_pendiente
    
banksel PORTA   
 
;--------------------------loop----------------------
loop:
    movlw 10
    movwf PORTC //valor de prueba
    goto loop
;-----------------------subrutinas loop--------------

;------------------subrutina interrupción------------

change_mode:
    btfsc PORTB, 0
    goto $+3
    movlw 0x01
    xorwf mode, F 
    bcf RBIF
    clrf PORTA
    return

generador:
    call signal
    call selector_display
    reinicio_tmr0
    return

    
    
signal:
    ;0:cuadrada	    ;1:triangular
    btfss mode,0 
    call rectangular
    btfsc mode,0
    call triangular
    return

rectangular: 
  /* incf vueltas ;lleva el conteo de las vueltas que ha realizado
   movf vueltas, W ;pasa el conteo de vueltas a W
   sublw 10 ;resta a la literal el valor de W, como tmr0 va a 0.01 s y 100 vueltas (100*0.01 = 1s)
   btfss STATUS, 2 ;comprueba la bandera zero
   goto $+3 ;zero = 0: sale de la subrutina ; zero = 1: salta esta instruccion
   clrf vueltas ;reinicia el conteo de vueltas*/
   comf PORTA
   return
    
triangular:
   btfss pendiente,0
   call t_inc
   btfsc pendiente,0
   call t_dec
   return

 t_inc:  
    incf PORTA
    decf nivel_pendiente
    btfss STATUS, 2
    goto $+5
    
    movlw 254
    movwf nivel_pendiente //reinicia contador
    
    movlw 0x01
    xorwf pendiente, F  //cambia bandera

   return
   
t_dec:
    decf PORTA
    decf nivel_pendiente
    btfss STATUS, 2
    goto $+5
    
    movlw 254
    movwf nivel_pendiente //reinicia contador
    
    movlw 0x01
    xorwf pendiente, F  //cambia bandera

   return
   return
   
selector_display:
    clrf PORTD		;apagar los displays
    btfss flags,1
    goto $+3
    btfsc flags, 0
    goto display_3
    btfsc flags, 1	; si hay un bit 1x ejecuta siguiente linea
    goto display_2	 
    btfsc flags, 0	; si hay un bit x1 ejecuta siguiente linea
    goto display_1	
    goto display_0	
 
    return

;00
display_0:
    movf display_var, W   ;W recibe el valor del display+1 (una localidad mayor)
    movwf PORTC		    ;recibe el puerto c el valor de W
    bsf PORTD, 0    ;bit0 del multiplexeado enciende
    bsf flags, 0
    bcf flags, 1	    ;bandera = 01
    return

;01
display_1:  ;display centena
    movf display_var+1, W	    ;W recibe el valor del display
    movwf PORTC		    ;recibe el puerto c el valor de W
    bsf PORTD, 1	    ;bit1 del multiplexeado enciende
    bcf flags, 0
    bsf flags, 1    ; bandera = 10
    return

;10
display_2:
    movf display_var+2, W   ;W recibe el valor del display+2 (una localidad mayor)
    movwf PORTC		    ;recibe el puerto c el valor de W
    bsf PORTD, 2    ;bit2 del multiplexeado enciende
    bsf flags, 0
    bsf flags, 1    ;bandera = 11 
    return
    
;11    
display_3: 
    movf display_var+3, W   ;W recibe el valor del display+2 (una localidad mayor)
    movwf PORTC		    ;recibe el puerto c el valor de W
    bsf PORTD, 3    ;bit2 del multiplexeado enciende
    bcf flags, 0
    bcf flags, 1    ;bandera = 00 
    return
    
;-----------------------subrutinas setup-------------
 config_io:
    banksel ANSEL
    clrf ANSEL
    clrf ANSELH
    
    banksel TRISA
    clrf TRISA
    clrf TRISC
    
    bcf TRISD, 0
    bcf TRISD, 1
    bcf TRISD, 2
    bcf TRISD, 3
    
    ;config pullup 
    bcf OPTION_REG, 7	;habilita los pull-ups del puerto B
    bsf WPUB0	;pull-ups internos 1: enabled
    bsf WPUB1
   
    
    bsf TRISB, 0 //boton modo triangular/rectangular
    bsf TRISB, 1 //boton modo Hz/KHz
    bsf TRISB, 2 //boton + frecuencia
    bsf TRISB, 3 //boton - frecuencia
    
    
    banksel PORTA
    clrf PORTA
    clrf PORTB
    clrf PORTC
    clrf PORTD
    
    return
    
    
    
 config_tmr0:
    banksel OPTION_REG
    bcf T0CS	;mode: temporizador
    bcf PSA	;prescaler para temporizador
    
    bcf PS2
    bcf PS1
    bsf PS0	;prescaler: 4
   
    banksel PORTA
    reinicio_tmr0
    return
    
config_reloj:
    banksel OSCCON
    bcf IRCF2
    bsf IRCF1
    bsf IRCF0 ;4MHz
    bsf SCS
    return
    
config_iocrb:
    banksel TRISA
    bsf IOCB0   ;interrupt-on-change 1:enabled
    bsf IOCB1
    
    banksel PORTA
    movf PORTB, W ;cuando lee, termina la condicion de mismatch
    bcf RBIF
    return
    
config_int_enable:
    bsf GIE ;global interrupt enable
    bsf T0IE ; tmr0 interrupt enable
    bcf T0IF ; bandera interrupcion
    bsf RBIE  ; RB interrupt enable
    bcf RBIF ;bandera interrupcion
    return
;----------------------Tabla---------------------
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
    
/* tabla_triangular: 
    CLRF PCLATH
    BSF PCLATH, 0
    ANDLW 0X0F
    ADDWF PCL ;PCL + PCLATH (W con PCL) PCL adquiere ese nuevo valor y salta a esa linea
    ;valores que regresa
    retlw 00000001B ;0
    retlw 00000011B ;1
    retlw 00000111B ;2
    retlw 00001111B ;3
    retlw 00011111B ;4
    retlw 00111111B ;5
    retlw 01111111B ;6
    retlw 11111111B ;7
    retlw 01111111B ;8
    retlw 00111111B ;9
    retlw 00011111B ;A
    retlw 00001111B ;B
    retlw 00000111B ;C
    retlw 00000011B ;D
    retlw 00000001B ;F
    */
    
   

END