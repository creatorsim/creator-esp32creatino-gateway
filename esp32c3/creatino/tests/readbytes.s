.data
      .align 4                # Alinear las variables a 4 bytes
  msg: 
      .string "Esperando datos...\n"

      .align 4                # Alinear bufferSize y otras variables de tipo word
  bufferSize: 
      .word 50

      .align 4                # Alinear recibidos a 4 bytes si se desea optimizar acceso
  received_data: 
      .space 50

      .align 1                # Alinear el delimitador a 1 byte (byte)
  delimiter: 
      .byte 'e'

      .align 4                # Alinear las cadenas de texto a 4 bytes para optimización
  sol: 
      .string "Result: %s\n"

      .align 4                # Alinear fin a 4 bytes (word)
  fin: 
      .word '\0'

.text 
setup:
    li a0,115200 
    addi sp, sp, -4      
    sw ra, 0(sp)     # Guardar el valor de ra (return address)
    jal ra, cr_serial_begin
    lw ra, 0(sp)     # Recupera el valor de ra
    addi sp, sp,4

    la a0, msg
    addi sp, sp, -16       # Reservar espacio en el stack
    sw ra, 12(sp)          # Guardar el registro RA en el stack
    jal ra, cr_serial_printf
    lw ra, 12(sp)          # Restaurar el registro RA desde el stack
    addi sp, sp, 16       # Liberar el espacio del stack
    jr ra

loop:
    addi sp, sp, -16      
    sw ra, 12(sp)     # Guardar el valor de ra (return address)
    jal ra, cr_serial_available
    lw ra, 12(sp)     # Recupera el valor de ra
    addi sp, sp,16 
    mv t2,a0
    bgez t2, loop_2
    jr ra
loop_2:
    addi sp, sp, -16      
    sw ra, 12(sp)     # Guardar el valor de ra (return address)
    la a1, received_data
    lb a2, bufferSize
    addi a2,a2 ,-1
    lb a0, delimiter
    jal ra, cr_serial_readBytesUntil
    lw ra, 12(sp)     # Recupera el valor de ra
    addi sp, sp,16 

    # Suponiendo que el número de bytes leídos está en a0 (resultado de cr_serial_readBytesUntil)
    la t1, received_data  # Cargar la dirección base de received_data en t1
    add t1, t1, a0        # Desplazar la dirección a received_data[bytesRead]
    sb zero, 0(t1)        # Almacenar '\0' (0x00) en received_data[bytesRead]


    mv t0,a0
    la a0, sol
    la a1, received_data
    addi sp, sp, -16       # Reservar espacio en el stack
    sw ra, 12(sp)
    li a7, 1 
    jal ra,cr_serial_printf        
    lw ra, 12(sp)          # Restaurar el registro RA desde el stack
    addi sp, sp, 16       # Liberar el espacio del stack


    bgez t2, loop
    jr ra

main:
    #Inicializar Arduino y configurar pines
    addi sp, sp, -16       # Reservar espacio en el stack
    sw ra, 12(sp)          # Guardar el registro RA en el stack
    jal ra,  cr_initArduino    
    jal ra, setup
    lw ra, 12(sp)          # Restaurar el registro RA desde el stack
    addi sp, sp, 16       # Liberar el espacio del stack     
    li  t0, 0
    beqz t0, loop
    jr ra

