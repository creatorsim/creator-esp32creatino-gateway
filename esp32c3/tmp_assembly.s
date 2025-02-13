####################################################
# CREATINO EXAMPLE: Blink the integrated LED       #
#               BY ELISA UTRILLA                   #
####################################################      

#ARDUINO
.data
    delay:
        .word 1000
.text
setup:
    #pinMode(LED_BUILTIN, OUTPUT);
    li a0,30
    li a1,  0x03 
    jal ra, cr_pinMode
loop:
    #digitalWrite(LED_BUILTIN, HIGH);
    li a0,30 
    li a1, 0x1
    jal ra, cr_digitalWrite
    #li a0, 10000000 #1 s aprox
    #call cr_delay
    la a0, delay
    lw a0, 0(a0)
    addi sp, sp, -16      
    sw ra, 12(sp)
    #jal ra, creator_udelay
    jal ra, cr_delay
    lw ra, 12(sp)          
    addi sp, sp, 16 
    li a0,30 
    li a1, 0x0
    jal ra, cr_digitalWrite
    la a0, delay
    lw a0, 0(a0)
    addi sp, sp, -16      
    sw ra, 12(sp)
    #jal ra, creator_udelay
    jal ra, cr_delay
    lw ra, 12(sp)          
    addi sp, sp, 16 
    
main:
    #Inicializar Arduino y configurar pines
    addi sp, sp, -16       # Reservar espacio en el stack
    sw ra, 12(sp)          # Guardar el registro RA en el stack
    jal ra, cr_initArduino    
    jal ra, setup
    lw ra, 12(sp)          # Restaurar el registro RA desde el stack
    addi sp, sp, 16       # Liberar el espacio del stack         
    li  t0, 1
    beqz t0, loop   
    