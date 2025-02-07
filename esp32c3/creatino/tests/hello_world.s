.data
    .align 2 
    msg: .string "Hola Mundo"
    	.align 4
    delay: .word 3000
.text
setup:
    #Serial.println("Hola Mundo")
    la a0, msg
    addi sp, sp, -16       # Reservar espacio en el stack
    sw ra, 12(sp)          # Guardar el registro RA en el stack
    li a7,4
    jal ra,cr_serial_print
    lw ra, 12(sp)          # Restaurar el registro RA desde el stack
    addi sp, sp, 16       # Liberar el espacio del stack
    #delay(3000000)
    la a0, delay
    lw a0, 0(a0)
    addi sp, sp, -16      
    sw ra, 12(sp)
    jal ra, cr_delay
    lw ra, 12(sp)          
    addi sp, sp, 16

    jr ra
creatino_main:
    #call initArduino    #Llamada a una función que inicializa el hardware necesario (esto lo deberías implementar)
    #call setup          #Configura el pin de salida
    addi sp, sp, -16       # Reservar espacio en el stack
    sw ra, 12(sp)          # Guardar el registro RA en el stack
    jal ra,setup
    #jal t0 ,serial_print
    lw ra, 12(sp)          # Restaurar el registro RA desde el stack
    addi sp, sp, 16       # Liberar el espacio del stack
    #addi t0,t0,1
    jr ra