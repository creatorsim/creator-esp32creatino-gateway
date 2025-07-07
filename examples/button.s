#ARDUINO

.data
    delay:  .word 1000
    buttonPin: .word  4
    buttonState:    .word   0
    msg:    .string     "Button Pressed!"

.text
setup:
    li a0, 115200
    addi sp, sp, -4      
    sw ra, 0(sp)          
    jal ra, cr_serial_begin
    lw ra, 0(sp)          
    addi sp, sp, 4            

    la a0, buttonPin   # Carga la dirección de buttonPin
    lw a0, 0(a0)       # Lee el valor almacenado en la dirección
    li a1,  0x05 #INPUT_PULLUP
    addi sp, sp, -4      
    sw ra, 0(sp)   
    jal ra, cr_pinMode
    lw ra, 0(sp)          
    addi sp, sp, 4

    jr ra

button_pressed:
    la a0, msg
    addi sp, sp, -16       # Reservar espacio en el stack
    sw ra, 12(sp)          # Guardar el registro RA en el stack
    jal ra,cr_serial_printf
    lw ra, 12(sp)          # Restaurar el registro RA desde el stack
    addi sp, sp, 16       # Liberar el espacio del stack
    jal ra, loop


loop:
    la a0, buttonPin   
    lw a0, 0(a0)       
    addi sp, sp, -4      
    sw ra, 0(sp)          
    jal ra, cr_digitalRead
    lw ra, 0(sp)          
    addi sp, sp, 4

    mv t0,a0

    li t1 ,0 #LOW

    beq t0,t1,button_pressed

    la a0, delay
    lw a0, 0(a0)
    addi sp, sp, -16      
    sw ra, 12(sp)
    jal ra, cr_delay
    lw ra, 12(sp)          
    addi sp, sp, 16 

    j loop

main:
    #Inicializar Arduino y configurar pines
    addi sp, sp, -16       # Reservar espacio en el stack
    sw ra, 12(sp)          # Guardar el registro RA en el stack
    jal ra, cr_initArduino    
    jal ra, setup
    lw ra, 12(sp)          # Restaurar el registro RA desde el stack
    addi sp, sp, 16       # Liberar el espacio del stack         
    li  t4, 0
    beqz t4, loop 
    jr ra
    ret 
