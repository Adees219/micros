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
 reinicio_tmr0 macro valueTmr0
    banksel PORTA
    movf valueTmr0, W
    movwf TMR0
    bcf T0IF
endm 
 
    
sel_prescaler macro valuePS
    banksel OPTION_REG
    movf valuePS, W
    iorwf OPTION_REG, F
endm 

;------------------------variables-------------------
      
PSECT udata_shr ;variables que se protegen los bits de status 

//variables para interrupcion
W_TEMP: DS 1	    ;variables para el push-pop
STATUS_TEMP: DS 1

//variables para cambio de frecuencia
ctrlFR: DS 1
frecuencia: DS 1
preescalador: DS 1  
    
//variables de interfaz
var: DS 1	    ;valor para los displays
flags: DS 1	    ;selector del multiplexado	
display_var: DS 4   ;valor mostrado en los displays    

    
//variables mapeo ondas
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
    call config_reloj
    call config_int_enable
    call config_iocrb
    
    //condiciones iniciales para tmr0
    movlw 0
    call tabla_tmr0 
    movwf frecuencia
    call seteo_prescaler
    movwf preescalador
    
    call config_tmr0
     
    //condiciones iniciales para onda triangular
    movlw 254
    movwf nivel_pendiente
    
banksel PORTA   
 
;--------------------------loop----------------------
loop:
    call seteo_freq
    call seteo_prescaler
    movwf preescalador
    
    btfss PORTB, 0
    call limpiar
    
    btfss PORTB, 1
    call incr_freq
   
    btfss PORTB, 2
    call dec_freq
    

      
    goto loop
;-----------------------subrutinas loop--------------

limpiar:
clrf PORTA
    return
    
incr_freq:
btfss PORTB, 1 ; (anti-rebote)comprueba si el boton que llamo a la rutina dejo de ser presionado
goto $-1	    ;vuelve a la línea anterior
incf ctrlFR	; incrementa el valor del puerto A 
return	;sale de la subrutina y regresa al loop

    
dec_freq:    
btfss PORTB, 2 ; (anti-rebote)comprueba si el boton que llamo a la rutina dejo de ser presionado
goto $-1	    ;vuelve a la línea anterior
decf ctrlFR	; incrementa el valor del puerto A 
return	;sale de la subrutina y regresa al loop

    
seteo_freq:
    movf ctrlFR, W
    andlw 0x32
    call tabla_tmr0 //mandar valor tmr0
    movwf frecuencia  
return

    
seteo_prescaler:
//comparador prescaler 128  (caso: 0-2)
movf ctrlFR, W 
sublw 3
btfsc STATUS, 0 //uno: W<3 dos: W>3
retlw 0b110//caso verdadero

//comparador presacaler 64  (caso: 3-5)
movf ctrlFR, W 
sublw 6
btfsc STATUS, 0 //uno: W<5 dos: W>5
retlw 0b101  //caso verdadero
   
//comparador presacaler 32  (caso: 6-8)
movf ctrlFR, W 
sublw 9
btfsc STATUS, 0 //uno: W<3 dos: W>3
retlw 0b100  //caso verdadero 
    
//comparador presacaler 16  (caso:9-12)
movf ctrlFR, W 
sublw 13
btfsc STATUS, 0 //uno: W<3 dos: W>3
retlw 0b011  //caso verdadero  

//comparador presacaler 8  (caso:13-15)
movf ctrlFR, W 
sublw 16
btfsc STATUS, 0 //uno: W<3 dos: W>3
retlw 0b010  //caso verdadero 
   
//comparador presacaler 4  (caso:16-28)
movf ctrlFR, W 
sublw 29
btfsc STATUS, 0 //uno: W<3 dos: W>3
retlw 0b001  //caso verdadero 
   
//comparador presacaler 2  (caso:29-49)
retlw 0b000  //caso verdadero  


    
;------------------subrutina interrupción------------

change_mode:
    btfsc PORTB, 0
    goto $+3
    movlw 0x01
    xorwf mode, F 
    bcf RBIF
 // clrf PORTA
    return

generador:
    call signal
    call selector_display
    reinicio_tmr0 frecuencia
    sel_prescaler preescalador 
    return

  
signal:
    ;0:cuadrada	    ;1:triangular
    btfsc mode,0 
    call rectangular
    btfss mode,0
    call triangular
    return

rectangular: 
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
    //decf nivel_pendiente
    movf PORTA, W
    sublw 255
    btfss STATUS, 2
    goto $+3
    
  /*  movlw 254
    movwf nivel_pendiente //reinicia contador*/
    
    movlw 0x01
    xorwf pendiente, F  //cambia bandera

   return
   
t_dec:
    decf PORTA
    btfss STATUS, 2
    goto $+3
    
  /*  movlw 254
    movwf nivel_pendiente //reinicia contador*/
    
    movlw 0x01
    xorwf pendiente, F  //cambia bandera

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
    
   //limpieza 
    banksel PORTA
    clrf PORTA
    clrf PORTB
    clrf PORTC
    clrf PORTD
    clrf frecuencia
    clrf preescalador 
    return
    
    
    
 config_tmr0:
    banksel OPTION_REG
    bcf T0CS	;mode: temporizador
    bcf PSA	;prescaler para temporizador
    
   sel_prescaler preescalador
   reinicio_tmr0 frecuencia 
   
    return
    
config_reloj:
    banksel OSCCON
    bsf IRCF2
    bsf IRCF1
    bcf IRCF0 ;4MHz
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
    
 tabla_tmr0: 
    CLRF PCLATH
    BSF PCLATH, 0
    ANDLW 0X32
    ADDWF PCL ;PCL + PCLATH (W con PCL) PCL adquiere ese nuevo valor y salta a esa linea
    
    ;valores que regresa:
    
    ;prescaler 1:128
    retlw 178 ;100
    retlw 217 ;200
    retlw 230 ;300
    
    ;prescaler 1:64
    retlw 217 ;400
    retlw 225 ;500
    retlw 230 ;600
    
    ;prescaler 1:32
    retlw 212 ;700
    retlw 217 ;800
    retlw 221 ;900
    
    ;prescaler 1:16
    retlw 194 ;1000
    retlw 199 ;1100
    retlw 204 ;1200
    retlw 208 ;1300
    
    ;prescaler 1:8
    retlw 167 ;1400
    retlw 173 ;1500
    retlw 178 ;1600
    
    ;prescaler 1:4
    retlw 109 ;1700
    retlw 117 ;1800
    retlw 125 ;1900
    retlw 131 ;2000
    retlw 137 ;2100
    retlw 142 ;2200
    retlw 147 ;2300
    retlw 152 ;2400
    retlw 156 ;2500
    retlw 160 ;2600
    retlw 163 ;2700
    retlw 167 ;2800
    retlw 170 ;2900
    
    ;prescaler 1:2
    retlw 89 ;3000
    retlw 95 ;3100
    retlw 100 ;3200
    retlw 104 ;3300
    retlw 109 ;3400
    retlw 113 ;3500
    retlw 117 ;3600
    retlw 121 ;3700
    retlw 124 ;3800
    retlw 128 ;3900
    retlw 131 ;4000
    retlw 134 ;4100
    retlw 137 ;4200
    retlw 140 ;4300
    retlw 142 ;4400
    retlw 145 ;4500
    retlw 147 ;4600
    retlw 150 ;4700
    retlw 152 ;4800
    retlw 154 ;4900
    retlw 156 ;5000

END
