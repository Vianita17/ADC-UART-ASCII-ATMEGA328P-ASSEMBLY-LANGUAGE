;
; ADC_TXRX.asm
;
; Created: 11/10/2025 11:47:10 PM
; Author : Vp

; Logic to receive instructions via serial port to use
;   8/10 bits resolution ADC

.org 0x000

.def temp = r17
.def temp1 = r18
.def eight = r19
.def teen = r20
.def flag_eight = r21
.def flag_teen = r22
.def udata = r23

rjmp setup

setup:
    ldi eight, 0x08
    ldi teen, 0x10
    rjmp SERIAL_BEGIN

SERIAL_BEGIN:
    ldi temp, 0b00000110
    sts UCSR0C, temp
    ldi temp, 0b00000000
    sts UBRR0H, temp
    ldi temp, 0b01100111  ; 9600 baud @ 16MHz
    sts UBRR0L, temp
    ldi temp, 0b00011000  ; Habilitar TX y RX
    sts UCSR0B, temp
    
    ; Inicializar ADC por defecto (8 bits)
    rcall ADC8_INIT
    rjmp loop

UART_TRANSMIT:
UART_WAIT_TXL: 
    lds temp, UCSR0A
    sbrs temp, 5 
    rjmp UART_WAIT_TXL 
    sts UDR0, udata 
    ret

loop:
    ; --- Revision UART (siempre primero) ---

	in temp, PORTD
	ori temp, (1<<PD2)
	out PORTD, temp

    lds temp, UCSR0A
    sbrs temp, 7          ; RXC0 es bit 7
    rjmp ADC_RUN          ; si no hay dato, sigue al ADC

    lds udata, UDR0

    cp udata, eight
    breq SET_8BIT
    cp udata, teen
    breq SET_10BIT
    rjmp loop

SET_8BIT:
    rcall ADC8_INIT
    rjmp loop

SET_10BIT:
    rcall ADC10_INIT
    rjmp loop

ADC_RUN:
    ; Aqui se hace una conversion segun el modo actual
    ldi r27, 0x01
    cp flag_eight, r27
    breq DO_ADC8
    cp flag_teen, r27
    breq DO_ADC10
    rjmp loop


DO_ADC8:
    rcall ADC8_CONVERT
    rjmp loop

DO_ADC10:
    rcall ADC10_CONVERT
    rjmp loop

; ==================== CONFIGURACIONES ADC ====================

ADC8_INIT:
    ; Configuracion para 8 bits
    ldi temp, 0b01100000  ; REFS=01, ADLAR=1, MUX=0000
    sts ADMUX, temp
    
    ldi temp, 0b10000111  ; ADEN=1, prescaler=128
    sts ADCSRA, temp
    
    ldi flag_eight, 0x01
    ldi flag_teen, 0x00
    ret

ADC10_INIT:
    ; Configuracion para 10 bits
    ldi temp, 0b01000000  ; REFS=01, ADLAR=0, MUX=0000
    sts ADMUX, temp
    
    ldi temp, 0b10000111  ; ADEN=1, prescaler=128
    sts ADCSRA, temp
    
    ldi flag_eight, 0x00
    ldi flag_teen, 0x01
    ret

; ==================== CONVERSIONES ADC ====================

ADC8_CONVERT:
    ; Iniciar conversion
    lds temp, ADCSRA
    ori temp, (1 << 6)    ; ADSC=1
    sts ADCSRA, temp

WAITING_8BIT:
    lds temp, ADCSRA
    sbrs temp, 4          ; Esperar ADIF=1
    rjmp WAITING_8BIT
    
    ; Limpiar flag ADIF
    lds temp, ADCSRA
    ori temp, (1 << 4)
    sts ADCSRA, temp
    
    ; Leer resultado (8 bits en ADCH)
    lds r26, ADCH
    clr r25
    
    rcall SET_DATA
    ret

ADC10_CONVERT:
    ; Iniciar conversion
    lds temp, ADCSRA
    ori temp, (1 << 6)    ; ADSC=1
    sts ADCSRA, temp
    
WAITING_10BIT:
    lds temp, ADCSRA
    sbrs temp, 4          ; Esperar ADIF=1
    rjmp WAITING_10BIT
    
    ; Limpiar flag ADIF
    lds temp, ADCSRA
    ori temp, (1 << 4)
    sts ADCSRA, temp
    
    ; Leer resultado (10 bits - ADCL primero, luego ADCH)
    lds r25, ADCL
    lds r26, ADCH
    
    rcall SET_DATA
    ret

; ==================== PROCESAMIENTO DE DATOS ====================

SET_DATA:
    ldi r27, 0x01
    cp flag_eight, r27
    brne SET_DATA10
    
    ; Procesamiento para 8 bits
    mov temp, r26
    
    ldi r28, 100
    clr r29
    
DIV100:
    cp temp, r28
    brcs DIV10
    inc r29
    sub temp, r28
    rjmp DIV100

DIV10:
    ldi r30, 10
    clr r31
DIV10loop:
    cp temp, r30
    brcs DONE
    inc r31
    sub temp, r30
    rjmp DIV10loop

DONE:
	mov r26, temp 
	
    ldi udata, '0'
    add udata, r29
    call UART_TRANSMIT

    ldi udata, '0'
    add udata, r31
    call UART_TRANSMIT

    ldi udata, '0'
    add udata, r26
    call UART_TRANSMIT

    ; Salto de linea
    ldi udata, 0x0A
    call UART_TRANSMIT
    ret

SET_DATA10:
    ldi r27, 0x01
    cp flag_teen, r27
    brne END_SET_DATA

    ; Procesamiento para 10 bits
    mov temp, r25   ; LSB
    mov temp1, r26  ; MSB

    ldi r16, 0xE8   ; 232 (0xE8)
    ldi r27, 0x03   ; 3
    clr r14         ; contador de miles

DIV1000:
    cp temp, r16
    cpc temp1, r27
    brcs DIV1002
    inc r14
    sub temp, r16
    sbc temp1, r27
    rjmp DIV1000

DIV1002:
    ldi r16, 0x64   ; 100
    ldi r27, 0x00
    clr r29         ; centenas

DIV100loop2:
    cp temp, r16
    cpc temp1, r27
    brcs DIV102
    inc r29
    sub temp, r16
    sbc temp1, r27
    rjmp DIV100loop2

DIV102:
    ldi r16, 0x0A   ; 10
    ldi r27, 0x00
    clr r31         ; decenas

DIV10loop2:
    cp temp, r16
    cpc temp1, r27
    brcs DONE2
    inc r31
    sub temp, r16
    sbc temp1, r27
    rjmp DIV10loop2

DONE2:
	mov r26, temp 

    ldi udata, '0'
    add udata, r14
    call UART_TRANSMIT

    ldi udata, '0'
    add udata, r29
    call UART_TRANSMIT

    ldi udata, '0'
    add udata, r31
    call UART_TRANSMIT

    ldi udata, '0'
    add udata, r26
    call UART_TRANSMIT

    ; Salto de linea
    ldi udata, 0x0A
    call UART_TRANSMIT
    ret

END_SET_DATA:
    ret