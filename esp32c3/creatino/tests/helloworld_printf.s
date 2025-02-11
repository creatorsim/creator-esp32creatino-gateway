####################################################
# CREATINO EXAMPLE: Hello world                    #
#               BY ELISA UTRILLA                   #
####################################################      

#ARDUINO
.data
    msg: .string "Hola %s\n"
    arg: .string "Mundo"


.text
setup:
    li a0,115200 
    addi sp, sp, -4      
    sw ra, 0(sp)     # Guardar el valor de ra (return address)
    jal ra,cr_serial_begin
    lw ra, 0(sp)     # Recupera el valor de ra
    addi sp, sp,4 

    la a0, msg
    la a1, arg
    addi sp, sp, -16       # Reservar espacio en el stack
    sw ra, 12(sp)          # Guardar el registro RA en el stack
    jal ra,cr_serial_printf
    lw ra, 12(sp)          # Restaurar el registro RA desde el stack
    addi sp, sp, 16       # Liberar el espacio del stack
    jr ra
loop:
    nop
main:
    addi sp, sp, -16       # Reservar espacio en el stack
    sw ra, 12(sp)          # Guardar el registro RA en el stack
    jal ra, cr_initArduino
    jal ra,setup
    lw ra, 12(sp)          # Restaurar el registro RA desde el stack
    addi sp, sp, 16       # Liberar el espacio del stack
    jr ra