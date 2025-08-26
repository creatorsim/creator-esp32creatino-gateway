####################################################################
#########CREATOR aux library   ARDUINO proyects in RISC V #########
####################################################################
.text
# Sustituto de ecall
.globl cr_ecall
.extern ecall_print_int
.extern ecall_print
.extern ecall_read_int
.extern ecall_read

cr_ecall:
    mv a2, a1         # Guardar a1 (segundo argumento) en a2
    mv a1, a0         # Guardar a0 en a1 (primer argumento)
    mv a0, a7         # Mover el código de llamada a a0

    # Reservar espacio en el stack para t4 y ra (2 registros)
    addi sp, sp, -12
    sw t4, 8(sp)
    sw t0, 4(sp)
    sw ra, 0(sp)

    # Comparar código de llamada con cada caso
    li t4, 1
    beq a0, t4, call_print_int
    li t4, 4
    beq a0, t4, call_print
    li t4, 11
    beq a0, t4, call_print
    li t4, 10
    beq a0, t4, call_print

    li t4, 5
    beq a0, t4, call_read_int
    li t4, 8
    beq a0, t4, call_read
    li t4, 12
    beq a0, t4, call_read

    # Si no es un código válido, salir
    j exit_ecall  

call_print_int:
    jal ra, ecall_print_int
    j exit_ecall

call_print:
    jal ra, ecall_print
    j exit_ecall

call_read_int:
    jal ra, ecall_read_int
    j exit_ecall

call_read:
    jal ra, ecall_read
    mv a1,a0
    li a0, 4
    jal ra, ecall_print  #Make the echo from read stay in the monitor
    j exit_ecall

exit_ecall:
    # Restaurar registros y salir
    lw ra, 0(sp)
    lw t0, 4(sp)
    lw t4, 8(sp)
    addi sp, sp, 12
    jr ra


# Basic TODO)
.extern initArduino
.global cr_initArduino
cr_initArduino:
    addi sp, sp, -32       # Reservar espacio para ra + t0-t6 (1 + 7 registros = 8 * 4 bytes = 32 bytes)
    sw ra, 28(sp)          # Guardar ra en la parte superior del frame
    sw t0, 0(sp)           # Guardar t0
    sw t1, 4(sp)           # Guardar t1
    sw t2, 8(sp)           # Guardar t2
    sw t3, 12(sp)          # Guardar t3
    sw t4, 16(sp)          # Guardar t4
    sw t5, 20(sp)          # Guardar t5
    sw t6, 24(sp)          # Guardar t6
    jal ra, initArduino
    lw t0, 0(sp)           # Restaurar t0
    lw t1, 4(sp)           # Restaurar t1
    lw t2, 8(sp)           # Restaurar t2
    lw t3, 12(sp)          # Restaurar t3
    lw t4, 16(sp)          # Restaurar t4
    lw t5, 20(sp)          # Restaurar t5
    lw t6, 24(sp)          # Restaurar t6
    lw ra, 28(sp)          # Restaurar ra
    addi sp, sp, 32        # Liberar espacio del stack
    jr ra
.extern digitalRead
.global cr_digitalRead
cr_digitalRead:
    addi sp, sp, -32       # Reservar espacio para ra + t0-t6 (1 + 7 registros = 8 * 4 bytes = 32 bytes)
    sw ra, 28(sp)          # Guardar ra en la parte superior del frame
    sw t0, 0(sp)           # Guardar t0
    sw t1, 4(sp)           # Guardar t1
    sw t2, 8(sp)           # Guardar t2
    sw t3, 12(sp)          # Guardar t3
    sw t4, 16(sp)          # Guardar t4
    sw t5, 20(sp)          # Guardar t5
    sw t6, 24(sp)          # Guardar t6
    jal ra, digitalRead 
    lw t0, 0(sp)           # Restaurar t0
    lw t1, 4(sp)           # Restaurar t1
    lw t2, 8(sp)           # Restaurar t2
    lw t3, 12(sp)          # Restaurar t3
    lw t4, 16(sp)          # Restaurar t4
    lw t5, 20(sp)          # Restaurar t5
    lw t6, 24(sp)          # Restaurar t6
    lw ra, 28(sp)          # Restaurar ra
    addi sp, sp, 32        # Liberar espacio del stack
    ret  
.globl cr_pinMode
.extern pinMode
cr_pinMode:
    addi sp, sp, -32       # Reservar espacio para ra + t0-t6 (1 + 7 registros = 8 * 4 bytes = 32 bytes)
    sw ra, 28(sp)          # Guardar ra en la parte superior del frame
    sw t0, 0(sp)           # Guardar t0
    sw t1, 4(sp)           # Guardar t1
    sw t2, 8(sp)           # Guardar t2
    sw t3, 12(sp)          # Guardar t3
    sw t4, 16(sp)          # Guardar t4
    sw t5, 20(sp)          # Guardar t5
    sw t6, 24(sp)          # Guardar t6
    jal ra, pinMode
    lw t0, 0(sp)           # Restaurar t0
    lw t1, 4(sp)           # Restaurar t1
    lw t2, 8(sp)           # Restaurar t2
    lw t3, 12(sp)          # Restaurar t3
    lw t4, 16(sp)          # Restaurar t4
    lw t5, 20(sp)          # Restaurar t5
    lw t6, 24(sp)          # Restaurar t6
    lw ra, 28(sp)          # Restaurar ra
    addi sp, sp, 32        # Liberar espacio del stack
    ret
.globl cr_digitalWrite
.extern digitalWrite
cr_digitalWrite:
    addi sp, sp, -32       # Reservar espacio para ra + t0-t6 (1 + 7 registros = 8 * 4 bytes = 32 bytes)
    sw ra, 28(sp)          # Guardar ra en la parte superior del frame
    sw t0, 0(sp)           # Guardar t0
    sw t1, 4(sp)           # Guardar t1
    sw t2, 8(sp)           # Guardar t2
    sw t3, 12(sp)          # Guardar t3
    sw t4, 16(sp)          # Guardar t4
    sw t5, 20(sp)          # Guardar t5
    sw t6, 24(sp)          # Guardar t6

    jal ra, digitalWrite   # Llamar a digitalWrite

    lw t0, 0(sp)           # Restaurar t0
    lw t1, 4(sp)           # Restaurar t1
    lw t2, 8(sp)           # Restaurar t2
    lw t3, 12(sp)          # Restaurar t3
    lw t4, 16(sp)          # Restaurar t4
    lw t5, 20(sp)          # Restaurar t5
    lw t6, 24(sp)          # Restaurar t6
    lw ra, 28(sp)          # Restaurar ra
    addi sp, sp, 32        # Liberar espacio del stack
    ret
#Analog
.globl cr_analogRead
.extern analogRead
cr_analogRead:
    addi sp, sp, -32       # Reservar espacio para ra + t0-t6 (1 + 7 registros = 8 * 4 bytes = 32 bytes)
    sw ra, 28(sp)          # Guardar ra en la parte superior del frame
    sw t0, 0(sp)           # Guardar t0
    sw t1, 4(sp)           # Guardar t1
    sw t2, 8(sp)           # Guardar t2
    sw t3, 12(sp)          # Guardar t3
    sw t4, 16(sp)          # Guardar t4
    sw t5, 20(sp)          # Guardar t5
    sw t6, 24(sp)          # Guardar t6
    jal ra, analogRead
    lw t0, 0(sp)           # Restaurar t0
    lw t1, 4(sp)           # Restaurar t1
    lw t2, 8(sp)           # Restaurar t2
    lw t3, 12(sp)          # Restaurar t3
    lw t4, 16(sp)          # Restaurar t4
    lw t5, 20(sp)          # Restaurar t5
    lw t6, 24(sp)          # Restaurar t6
    lw ra, 28(sp)          # Restaurar ra
    addi sp, sp, 32        # Liberar espacio del stack
    ret
.globl cr_analogReadResolution
.extern analogReadResolution
cr_analogReadResolution:
    addi sp, sp, -32       # Reservar espacio para ra + t0-t6 (1 + 7 registros = 8 * 4 bytes = 32 bytes)
    sw ra, 28(sp)          # Guardar ra en la parte superior del frame
    sw t0, 0(sp)           # Guardar t0
    sw t1, 4(sp)           # Guardar t1
    sw t2, 8(sp)           # Guardar t2
    sw t3, 12(sp)          # Guardar t3
    sw t4, 16(sp)          # Guardar t4
    sw t5, 20(sp)          # Guardar t5
    sw t6, 24(sp)          # Guardar t6
    jal ra, analogReadResolution
    lw t0, 0(sp)           # Restaurar t0
    lw t1, 4(sp)           # Restaurar t1
    lw t2, 8(sp)           # Restaurar t2
    lw t3, 12(sp)          # Restaurar t3
    lw t4, 16(sp)          # Restaurar t4
    lw t5, 20(sp)          # Restaurar t5
    lw t6, 24(sp)          # Restaurar t6
    lw ra, 28(sp)          # Restaurar ra
    addi sp, sp, 32        # Liberar espacio del stack
    ret
.globl cr_analogWrite
.extern analogWrite
cr_analogWrite:
    addi sp, sp, -32       # Reservar espacio para ra + t0-t6 (1 + 7 registros = 8 * 4 bytes = 32 bytes)
    sw ra, 28(sp)          # Guardar ra en la parte superior del frame
    sw t0, 0(sp)           # Guardar t0
    sw t1, 4(sp)           # Guardar t1
    sw t2, 8(sp)           # Guardar t2
    sw t3, 12(sp)          # Guardar t3
    sw t4, 16(sp)          # Guardar t4
    sw t5, 20(sp)          # Guardar t5
    sw t6, 24(sp)          # Guardar t6
    jal ra, analogWrite
    lw t0, 0(sp)           # Restaurar t0
    lw t1, 4(sp)           # Restaurar t1
    lw t2, 8(sp)           # Restaurar t2
    lw t3, 12(sp)          # Restaurar t3
    lw t4, 16(sp)          # Restaurar t4
    lw t5, 20(sp)          # Restaurar t5
    lw t6, 24(sp)          # Restaurar t6
    lw ra, 28(sp)          # Restaurar ra
    addi sp, sp, 32        # Liberar espacio del stack
    ret               
# Maths
.globl cr_map
.extern aux_map
cr_map:
    addi sp, sp, -32       # Reservar espacio para ra + t0-t6 (1 + 7 registros = 8 * 4 bytes = 32 bytes)
    sw ra, 28(sp)          # Guardar ra en la parte superior del frame
    sw t0, 0(sp)           # Guardar t0
    sw t1, 4(sp)           # Guardar t1
    sw t2, 8(sp)           # Guardar t2
    sw t3, 12(sp)          # Guardar t3
    sw t4, 16(sp)          # Guardar t4
    sw t5, 20(sp)          # Guardar t5
    sw t6, 24(sp)          # Guardar t6
    jal ra, aux_map
    lw t0, 0(sp)           # Restaurar t0
    lw t1, 4(sp)           # Restaurar t1
    lw t2, 8(sp)           # Restaurar t2
    lw t3, 12(sp)          # Restaurar t3
    lw t4, 16(sp)          # Restaurar t4
    lw t5, 20(sp)          # Restaurar t5
    lw t6, 24(sp)          # Restaurar t6
    lw ra, 28(sp)          # Restaurar ra
    addi sp, sp, 32        # Liberar espacio del stack
    jr ra

.globl cr_constrain
.extern aux_constrain
cr_constrain:
    addi sp, sp, -32       # Reservar espacio para ra + t0-t6 (1 + 7 registros = 8 * 4 bytes = 32 bytes)
    sw ra, 28(sp)          # Guardar ra en la parte superior del frame
    sw t0, 0(sp)           # Guardar t0
    sw t1, 4(sp)           # Guardar t1
    sw t2, 8(sp)           # Guardar t2
    sw t3, 12(sp)          # Guardar t3
    sw t4, 16(sp)          # Guardar t4
    sw t5, 20(sp)          # Guardar t5
    sw t6, 24(sp)          # Guardar t6
    jal ra, aux_constrain
    lw t0, 0(sp)           # Restaurar t0
    lw t1, 4(sp)           # Restaurar t1
    lw t2, 8(sp)           # Restaurar t2
    lw t3, 12(sp)          # Restaurar t3
    lw t4, 16(sp)          # Restaurar t4
    lw t5, 20(sp)          # Restaurar t5
    lw t6, 24(sp)          # Restaurar t6
    lw ra, 28(sp)          # Restaurar ra
    addi sp, sp, 32        # Liberar espacio del stack

.globl cr_abs
cr_abs:
    bgez a0, skip_nop
    neg a0, a0
    ret
.globl cr_fabs
.extern fabs
cr_fabs:
    addi sp, sp, -32       # Reservar espacio para ra + t0-t6
    sw ra, 28(sp)
    sw t0, 0(sp)
    sw t1, 4(sp)
    sw t2, 8(sp)
    sw t3, 12(sp)
    sw t4, 16(sp)
    sw t5, 20(sp)
    sw t6, 24(sp)
    jal ra, fabs           # Llamar a la función C++ fabs
    lw t0, 0(sp)
    lw t1, 4(sp)
    lw t2, 8(sp)
    lw t3, 12(sp)
    lw t4, 16(sp)
    lw t5, 20(sp)
    lw t6, 24(sp)
    lw ra, 28(sp)
    addi sp, sp, 32
    jr ra    
.globl cr_max    
cr_max:
    bge a0, a1, skip_nop  
    mv a0, a1             
    jr ra

.globl cr_fmax
.extern fmax
cr_fmax:
    addi sp, sp, -32       # Reservar espacio para ra + t0-t6
    sw ra, 28(sp)
    sw t0, 0(sp)
    sw t1, 4(sp)
    sw t2, 8(sp)
    sw t3, 12(sp)
    sw t4, 16(sp)
    sw t5, 20(sp)
    sw t6, 24(sp)
    jal ra, fmax          
    lw t0, 0(sp)
    lw t1, 4(sp)
    lw t2, 8(sp)
    lw t3, 12(sp)
    lw t4, 16(sp)
    lw t5, 20(sp)
    lw t6, 24(sp)
    lw ra, 28(sp)
    addi sp, sp, 32
    jr ra
.globl cr_min    
cr_min:
    blt a0, a1, skip_nop 
    mv a0, a1
    jr ra
skip_nop:
    jr ra

.globl cr_fminf
.extern fminf
cr_fminf:
    addi sp, sp, -32       # Reservar espacio para ra + t0-t6
    sw ra, 28(sp)
    sw t0, 0(sp)
    sw t1, 4(sp)
    sw t2, 8(sp)
    sw t3, 12(sp)
    sw t4, 16(sp)
    sw t5, 20(sp)
    sw t6, 24(sp)
    jal ra, fminf           # fminf: Estas placas no soportan double
    lw t0, 0(sp)
    lw t1, 4(sp)
    lw t2, 8(sp)
    lw t3, 12(sp)
    lw t4, 16(sp)
    lw t5, 20(sp)
    lw t6, 24(sp)
    lw ra, 28(sp)
    addi sp, sp, 32
    jr ra
        
.globl cr_pow                       
.extern pow
cr_pow:
    addi sp, sp, -32       # Reservar espacio para ra + t0-t6
    sw ra, 28(sp)
    sw t0, 0(sp)
    sw t1, 4(sp)
    sw t2, 8(sp)
    sw t3, 12(sp)
    sw t4, 16(sp)
    sw t5, 20(sp)
    sw t6, 24(sp)
    jal ra, pow        
    lw t0, 0(sp)
    lw t1, 4(sp)
    lw t2, 8(sp)
    lw t3, 12(sp)
    lw t4, 16(sp)
    lw t5, 20(sp)
    lw t6, 24(sp)
    lw ra, 28(sp)
    addi sp, sp, 32
    jr ra
.globl cr_sqrt
.extern sqrt
cr_sqrt:
    addi sp, sp, -32       # Reservar espacio para ra + t0-t6 (1 + 7 registros = 8 * 4 bytes = 32 bytes)
    sw ra, 28(sp)          # Guardar ra en la parte superior del frame
    sw t0, 0(sp)           # Guardar t0
    sw t1, 4(sp)           # Guardar t1
    sw t2, 8(sp)           # Guardar t2
    sw t3, 12(sp)          # Guardar t3
    sw t4, 16(sp)          # Guardar t4
    sw t5, 20(sp)          # Guardar t5
    sw t6, 24(sp)          # Guardar t6
    jal ra, sqrt
    lw t0, 0(sp)           # Restaurar t0
    lw t1, 4(sp)           # Restaurar t1
    lw t2, 8(sp)           # Restaurar t2
    lw t3, 12(sp)          # Restaurar t3
    lw t4, 16(sp)          # Restaurar t4
    lw t5, 20(sp)          # Restaurar t5
    lw t6, 24(sp)          # Restaurar t6
    lw ra, 28(sp)          # Restaurar ra
    addi sp, sp, 32        # Liberar espacio del stack
    jr ra
    # Se llamaría a c porque esta placa no soporta punto flotante
.globl cr_sqrtf
.extern sqrtf
cr_sqrtf:
    addi sp, sp, -32       # Reservar espacio para ra + t0-t6 (1 + 7 registros = 8 * 4 bytes = 32 bytes)
    sw ra, 28(sp)          # Guardar ra en la parte superior del frame
    sw t0, 0(sp)           # Guardar t0
    sw t1, 4(sp)           # Guardar t1
    sw t2, 8(sp)           # Guardar t2
    sw t3, 12(sp)          # Guardar t3
    sw t4, 16(sp)          # Guardar t4
    sw t5, 20(sp)          # Guardar t5
    sw t6, 24(sp)          # Guardar t6
    jal ra, sqrtf
    lw t0, 0(sp)           # Restaurar t0
    lw t1, 4(sp)           # Restaurar t1
    lw t2, 8(sp)           # Restaurar t2
    lw t3, 12(sp)          # Restaurar t3
    lw t4, 16(sp)          # Restaurar t4
    lw t5, 20(sp)          # Restaurar t5
    lw t6, 24(sp)          # Restaurar t6
    lw ra, 28(sp)          # Restaurar ra
    addi sp, sp, 32        # Liberar espacio del stack
    jr ra
    # Se llamaría a c porque esta placa no soporta punto flotante    
.globl cr_sq   
cr_sq:
    mul a0, a0, a0  # a0 = a0 * a0 
    jr ra

.globl cr_fsq
cr_fsq:
    fmul.s f0, f0, f0  # f0 = f0 * f0 (single-precision float)
    jr ra

.globl cr_cos
.extern cos   
cr_cos:
   # Se llamaría a c porque esta placa no soporta punto flotante (no tiene FPU )
    addi sp, sp, -32       # Reservar espacio para ra + t0-t6 (1 + 7 registros = 8 * 4 bytes = 32 bytes)
    sw ra, 28(sp)          # Guardar ra en la parte superior del frame
    sw t0, 0(sp)           # Guardar t0
    sw t1, 4(sp)           # Guardar t1
    sw t2, 8(sp)           # Guardar t2
    sw t3, 12(sp)          # Guardar t3
    sw t4, 16(sp)          # Guardar t4
    sw t5, 20(sp)          # Guardar t5
    sw t6, 24(sp)          # Guardar t6
    jal ra, cos
    lw t0, 0(sp)           # Restaurar t0
    lw t1, 4(sp)           # Restaurar t1
    lw t2, 8(sp)           # Restaurar t2
    lw t3, 12(sp)          # Restaurar t3
    lw t4, 16(sp)          # Restaurar t4
    lw t5, 20(sp)          # Restaurar t5
    lw t6, 24(sp)          # Restaurar t6
    lw ra, 28(sp)          # Restaurar ra
    addi sp, sp, 32        # Liberar espacio del stack
    jr ra
.globl cr_sin
.extern sin   
cr_sin:
   # Se llamaría a c porque esta placa no soporta punto flotante (no tiene FPU )
    addi sp, sp, -32       # Reservar espacio para ra + t0-t6 (1 + 7 registros = 8 * 4 bytes = 32 bytes)
    sw ra, 28(sp)          # Guardar ra en la parte superior del frame
    sw t0, 0(sp)           # Guardar t0
    sw t1, 4(sp)           # Guardar t1
    sw t2, 8(sp)           # Guardar t2
    sw t3, 12(sp)          # Guardar t3
    sw t4, 16(sp)          # Guardar t4
    sw t5, 20(sp)          # Guardar t5
    sw t6, 24(sp)          # Guardar t6
    jal ra, sin
    lw t0, 0(sp)           # Restaurar t0
    lw t1, 4(sp)           # Restaurar t1
    lw t2, 8(sp)           # Restaurar t2
    lw t3, 12(sp)          # Restaurar t3
    lw t4, 16(sp)          # Restaurar t4
    lw t5, 20(sp)          # Restaurar t5
    lw t6, 24(sp)          # Restaurar t6
    lw ra, 28(sp)          # Restaurar ra
    addi sp, sp, 32        # Liberar espacio del stack
    jr ra
.globl cr_tan
.extern tan   
cr_tan:
   # Se llamaría a c porque esta placa no soporta punto flotante (no tiene FPU )
    addi sp, sp, -32       # Reservar espacio para ra + t0-t6 (1 + 7 registros = 8 * 4 bytes = 32 bytes)
    sw ra, 28(sp)          # Guardar ra en la parte superior del frame
    sw t0, 0(sp)           # Guardar t0
    sw t1, 4(sp)           # Guardar t1
    sw t2, 8(sp)           # Guardar t2
    sw t3, 12(sp)          # Guardar t3
    sw t4, 16(sp)          # Guardar t4
    sw t5, 20(sp)          # Guardar t5
    sw t6, 24(sp)          # Guardar t6
    jal ra, tan
    lw t0, 0(sp)           # Restaurar t0
    lw t1, 4(sp)           # Restaurar t1
    lw t2, 8(sp)           # Restaurar t2
    lw t3, 12(sp)          # Restaurar t3
    lw t4, 16(sp)          # Restaurar t4
    lw t5, 20(sp)          # Restaurar t5
    lw t6, 24(sp)          # Restaurar t6
    lw ra, 28(sp)          # Restaurar ra
    addi sp, sp, 32        # Liberar espacio del stack
    jr ra                      
# Bits and bytes ==> watchout 4 ports
.globl cr_bit
cr_bit:
    li t0, 1 # bit(0) = 1
    sll t0, t0, a0   # 1 << a0 times
    mv a0, t0
    ret
.globl cr_bitClear    
cr_bitClear:
    li t0, 1 # bit(0) = 1
    sll t0, t0, a1   # 1 << a0 times
    not t0, t0 #Creates a mask to disable the bit in the position asked
    and a0, a0, t0 
    ret
.globl cr_bitRead
cr_bitRead:
    li t0, 1 # bit(0) = 1
    sll t0, t0, a1   # 1 << a0 times
    and a0, a0, t0
    srl a0, a0, a1
    ret
.globl cr_bitSet
cr_bitSet:
    li t0, 1 # bit(0) = 1
    sll t0, t0, a1   # 1 << a0 times
    or a0, a0, t0
    ret
.globl cr_bitWrite  
cr_bitWrite:
    li t0, 1 # bit(0) = 1
    addi sp, sp, -4     
    sw ra, 0(sp) 
    beqz a2, cr_bitClear
    call cr_bitSet
    lw ra, 0(sp)          
    addi sp, sp, 4
    ret
.globl cr_highByte    
cr_highByte: 
    # Obtener el byte alto (bits 8-15)
    srli t0, a0, 8       
    andi a0, t0, 0x00FF 
    ret 
.globl cr_lowByte     
cr_lowByte: 
    # Obtener el byte bajo (bits 0-7)
    andi a0, a0, 0x00FF  # Enmascarar los 8 bits inferiores 
    ret                        
# Interrupts
.extern attachInterrupt
.global cr_attachInterrupt
cr_attachInterrupt:
    addi sp, sp, -32       # Reservar espacio para ra + t0-t6 (1 + 7 registros = 8 * 4 bytes = 32 bytes)
    sw ra, 28(sp)          # Guardar ra en la parte superior del frame
    sw t0, 0(sp)           # Guardar t0
    sw t1, 4(sp)           # Guardar t1
    sw t2, 8(sp)           # Guardar t2
    sw t3, 12(sp)          # Guardar t3
    sw t4, 16(sp)          # Guardar t4
    sw t5, 20(sp)          # Guardar t5
    sw t6, 24(sp)          # Guardar t6
    jal ra, attachInterrupt 
    lw t0, 0(sp)           # Restaurar t0
    lw t1, 4(sp)           # Restaurar t1
    lw t2, 8(sp)           # Restaurar t2
    lw t3, 12(sp)          # Restaurar t3
    lw t4, 16(sp)          # Restaurar t4
    lw t5, 20(sp)          # Restaurar t5
    lw t6, 24(sp)          # Restaurar t6
    lw ra, 28(sp)          # Restaurar ra
    addi sp, sp, 32        # Liberar espacio del stack
    ret

.extern detachInterrupt
.global cr_detachInterrupt
cr_detachInterrupt:
    addi sp, sp, -32       # Reservar espacio para ra + t0-t6 (1 + 7 registros = 8 * 4 bytes = 32 bytes)
    sw ra, 28(sp)          # Guardar ra en la parte superior del frame
    sw t0, 0(sp)           # Guardar t0
    sw t1, 4(sp)           # Guardar t1
    sw t2, 8(sp)           # Guardar t2
    sw t3, 12(sp)          # Guardar t3
    sw t4, 16(sp)          # Guardar t4
    sw t5, 20(sp)          # Guardar t5
    sw t6, 24(sp)          # Guardar t6
    jal ra, detachInterrupt 
    lw t0, 0(sp)           # Restaurar t0
    lw t1, 4(sp)           # Restaurar t1
    lw t2, 8(sp)           # Restaurar t2
    lw t3, 12(sp)          # Restaurar t3
    lw t4, 16(sp)          # Restaurar t4
    lw t5, 20(sp)          # Restaurar t5
    lw t6, 24(sp)          # Restaurar t6
    lw ra, 28(sp)          # Restaurar ra
    addi sp, sp, 32        # Liberar espacio del stack
    ret
.extern cr_digitalPinToGPIONumber
.global cr_digitalPinToInterrupt
#(((uint8_t)digitalPinToGPIONumber(p)) < NUM_DIGITAL_PINS) ? (p) : NOT_AN_INTERRUPT
cr_digitalPinToInterrupt:
    addi sp, sp, -36       # Reservar espacio para ra + t0-t6 + argumento original (9 * 4 bytes = 36 bytes)
    sw ra, 32(sp)          # Guardar ra
    sw t0, 0(sp)
    sw t1, 4(sp)
    sw t2, 8(sp)
    sw t3, 12(sp)
    sw t4, 16(sp)
    sw t5, 20(sp)
    sw t6, 24(sp)
    sw a0, 28(sp)          # Guardar argumento original (p)
    jal ra, cr_digitalPinToGPIONumber 
    li t1, 49            
    bltu a0, t1, valid_pin 
    li a0, -1             # NOT_AN_INTERRUPT
    j end_function

valid_pin:
    lw a0, 28(sp)         # Restaurar el argumento original (p)

end_function:
    lw t0, 0(sp)
    lw t1, 4(sp)
    lw t2, 8(sp)
    lw t3, 12(sp)
    lw t4, 16(sp)
    lw t5, 20(sp)
    lw t6, 24(sp)
    lw ra, 32(sp)
    addi sp, sp, 36
    ret     

.extern pulseIn
.global cr_pulseIn
cr_pulseIn:
    addi sp, sp, -32       # Reservar espacio para ra + t0-t6 (1 + 7 registros = 8 * 4 bytes = 32 bytes)
    sw ra, 28(sp)          # Guardar ra en la parte superior del frame
    sw t0, 0(sp)           # Guardar t0
    sw t1, 4(sp)           # Guardar t1
    sw t2, 8(sp)           # Guardar t2
    sw t3, 12(sp)          # Guardar t3
    sw t4, 16(sp)          # Guardar t4
    sw t5, 20(sp)          # Guardar t5
    sw t6, 24(sp)          # Guardar t6
    jal ra, pulseIn 
    lw t0, 0(sp)           # Restaurar t0
    lw t1, 4(sp)           # Restaurar t1
    lw t2, 8(sp)           # Restaurar t2
    lw t3, 12(sp)          # Restaurar t3
    lw t4, 16(sp)          # Restaurar t4
    lw t5, 20(sp)          # Restaurar t5
    lw t6, 24(sp)          # Restaurar t6
    lw ra, 28(sp)          # Restaurar ra
    addi sp, sp, 32        # Liberar espacio del stack
    ret

.extern pulseInLong
.global cr_pulseInLong
cr_pulseInLong:
    addi sp, sp, -32       # Reservar espacio para ra + t0-t6 (1 + 7 registros = 8 * 4 bytes = 32 bytes)
    sw ra, 28(sp)          # Guardar ra en la parte superior del frame
    sw t0, 0(sp)           # Guardar t0
    sw t1, 4(sp)           # Guardar t1
    sw t2, 8(sp)           # Guardar t2
    sw t3, 12(sp)          # Guardar t3
    sw t4, 16(sp)          # Guardar t4
    sw t5, 20(sp)          # Guardar t5
    sw t6, 24(sp)          # Guardar t6
    jal ra, pulseInLong
    lw t0, 0(sp)           # Restaurar t0
    lw t1, 4(sp)           # Restaurar t1
    lw t2, 8(sp)           # Restaurar t2
    lw t3, 12(sp)          # Restaurar t3
    lw t4, 16(sp)          # Restaurar t4
    lw t5, 20(sp)          # Restaurar t5
    lw t6, 24(sp)          # Restaurar t6
    lw ra, 28(sp)          # Restaurar ra
    addi sp, sp, 32        # Liberar espacio del stack
    ret

.extern shiftIn
.global cr_shiftIn
cr_shiftIn:
    addi sp, sp, -32       # Reservar espacio para ra + t0-t6 (1 + 7 registros = 8 * 4 bytes = 32 bytes)
    sw ra, 28(sp)          # Guardar ra en la parte superior del frame
    sw t0, 0(sp)           # Guardar t0
    sw t1, 4(sp)           # Guardar t1
    sw t2, 8(sp)           # Guardar t2
    sw t3, 12(sp)          # Guardar t3
    sw t4, 16(sp)          # Guardar t4
    sw t5, 20(sp)          # Guardar t5
    sw t6, 24(sp)          # Guardar t6
    jal ra, shiftIn
    lw t0, 0(sp)           # Restaurar t0
    lw t1, 4(sp)           # Restaurar t1
    lw t2, 8(sp)           # Restaurar t2
    lw t3, 12(sp)          # Restaurar t3
    lw t4, 16(sp)          # Restaurar t4
    lw t5, 20(sp)          # Restaurar t5
    lw t6, 24(sp)          # Restaurar t6
    lw ra, 28(sp)          # Restaurar ra
    addi sp, sp, 32        # Liberar espacio del stack
    ret

.extern shiftOut
.global cr_shiftOut
cr_shiftOut:
    addi sp, sp, -32       # Reservar espacio para ra + t0-t6 (1 + 7 registros = 8 * 4 bytes = 32 bytes)
    sw ra, 28(sp)          # Guardar ra en la parte superior del frame
    sw t0, 0(sp)           # Guardar t0
    sw t1, 4(sp)           # Guardar t1
    sw t2, 8(sp)           # Guardar t2
    sw t3, 12(sp)          # Guardar t3
    sw t4, 16(sp)          # Guardar t4
    sw t5, 20(sp)          # Guardar t5
    sw t6, 24(sp)          # Guardar t6
    jal ra, shiftOut
    lw t0, 0(sp)           # Restaurar t0
    lw t1, 4(sp)           # Restaurar t1
    lw t2, 8(sp)           # Restaurar t2
    lw t3, 12(sp)          # Restaurar t3
    lw t4, 16(sp)          # Restaurar t4
    lw t5, 20(sp)          # Restaurar t5
    lw t6, 24(sp)          # Restaurar t6
    lw ra, 28(sp)          # Restaurar ra
    addi sp, sp, 32        # Liberar espacio del stack
    ret                           
.extern interrupts
.globl cr_interrupts     
cr_interrupts:
    addi sp, sp, -32       
    sw ra, 28(sp)          
    sw t0, 0(sp)           
    sw t1, 4(sp)           
    sw t2, 8(sp)           
    sw t3, 12(sp)          
    sw t4, 16(sp)          
    sw t5, 20(sp)          
    sw t6, 24(sp)          
    li a0, 1
    call vPortClearInterruptMaskFromISR
    lw t0, 0(sp)           # Restaurar t0
    lw t1, 4(sp)           # Restaurar t1
    lw t2, 8(sp)           # Restaurar t2
    lw t3, 12(sp)          # Restaurar t3
    lw t4, 16(sp)          # Restaurar t4
    lw t5, 20(sp)          # Restaurar t5
    lw t6, 24(sp)          # Restaurar t6
    lw ra, 28(sp)          # Restaurar ra
    addi sp, sp, 32        # Liberar espacio del stack
    ret
.globl cr_noInterrupts
.extern xPortSetInterruptMaskFromISR
cr_noInterrupts:
    #csrc mstatus, 0x8   # Deshabilitar el bit MIE en el registro mstatus
    addi sp, sp, -8       # Reservar espacio en el stack
    sw ra, 4(sp)
    call xPortSetInterruptMaskFromISR
    lw ra, 4(sp)           
    addi sp, sp, 8      # Liberar el espacio del stack
    ret     
# Characters
.globl cr_isDigit
cr_isDigit:
    mv a5,a0
    addi sp, sp, -4
    sw ra, 0(sp)
    call isdigit
    lw ra, 0(sp)           
    addi sp, sp, 4
    mv      a5,a0
    beq     a5,zero,.L2
    #Para True
    li      a5,1
    j       .L3
    ret  
.globl cr_isAlpha
cr_isAlpha:
    mv a5,a0
    addi sp, sp, -4     
    sw ra, 0(sp)          
    call isalpha
    lw ra, 0(sp)           
    addi sp, sp, 4
    mv      a5,a0
    beq     a5,zero,.L2
    #Para True
    li      a5,1
    j       .L3
    ret
.globl cr_isAlphaNumeric
cr_isAlphaNumeric:
    mv      a5,a0
    addi sp, sp, -4     
    sw ra, 0(sp)
    call    isalnum
    lw ra, 0(sp)           
    addi sp, sp, 4
    mv      a5,a0
    beq     a5,zero,.L2
    #Para True
    li      a5,1
    j       .L3 
    ret
.globl cr_isAscii
cr_isAscii:
    addi sp, sp, -4     
    sw ra, 0(sp) 
    mv      a0,a5
    call    isascii
    lw ra, 0(sp)           
    addi sp, sp, 4
    mv      a5,a0
    beq     a5,zero,.L2
    #Para True
    li      a5,1
    j       .L3 
    ret
.globl cr_isControl
cr_isControl:
    addi sp, sp, -4     
    sw ra, 0(sp) 
    mv      a0,a5
    call    iscntrl
    lw ra, 0(sp)           
    addi sp, sp, 4
    mv      a5,a0
    beq     a5,zero,.L2
    #Para True
    li      a5,1
    j       .L3 
    ret 
.globl cr_isPunct
cr_isPunct:
    addi sp, sp, -4     
    sw ra, 0(sp) 
    mv      a0,a5
    call    ispunct
    lw ra, 0(sp)           
    addi sp, sp, 4
    mv      a5,a0
    beq     a5,zero,.L2
    #Para True
    li      a5,1
    j       .L3 
    ret
.globl cr_isHexadecimalDigit
cr_isHexadecimalDigit:
    addi sp, sp, -4     
    sw ra, 0(sp) 
    mv      a0,a5
    call    isxdigit
    lw ra, 0(sp)           
    addi sp, sp, 4
    mv      a5,a0
    beq     a5,zero,.L2
    #Para True
    li      a5,1
    j       .L3 
    ret    
.globl cr_isUpperCase
cr_isUpperCase:
    addi sp, sp, -4     
    sw ra, 0(sp)
    mv      a0,a5
    call    isupper
    lw ra, 0(sp)           
    addi sp, sp, 4
    mv      a5,a0
    beq     a5,zero,.L2
    #Para True
    li      a5,1
    j       .L3 
    ret 
.globl cr_isLowerCase
cr_isLowerCase:
    addi sp, sp, -4     
    sw ra, 0(sp) 
    mv      a0,a5
    call    islower
    lw ra, 0(sp)           
    addi sp, sp, 4
    mv      a5,a0
    beq     a5,zero,.L2
    #Para True
    li      a5,1
    j       .L3 
    ret               
.globl cr_isPrintable
cr_isPrintable:
    addi sp, sp, -4     
    sw ra, 0(sp) 
    mv      a0,a5
    call    isprint
    lw ra, 0(sp)           
    addi sp, sp, 4
    mv      a5,a0
    beq     a5,zero,.L2
    #Para True
    li      a5,1
    j       .L3 
    ret 
.globl cr_isGraph
cr_isGraph:
    li      a5,32            # Carga el valor de un espacio en blanco (' ')
    beq     a0,a5,.L2        # Si el valor de a0 es un espacio (' '), salta a .L2
    addi sp, sp, -4     
    sw ra, 0(sp) 
    call    isprint
    lw ra, 0(sp)           
    addi sp, sp, 4
    mv      a5,a0
    beq     a5,zero,.L2
    #Para True
    li      a5,1
    j       .L3 
    ret

.globl cr_isSpace
cr_isSpace:
    mv      a0,a5
    li      a5,32            #' '
    beq     a0,a5,.L2        
    li      a5,12            #\f
    beq     a0,a5,.L2        
    li      a5,9            #\t
    beq     a0,a5,.L2        
    li      a5,10           #\n
    beq     a0,a5,.L2        
    li      a5,13           #\r 
    beq     a0,a5,.L2
    li      a5,11           #\v 
    beq     a0,a5,.L2           
    #Para True
    li      a0,1
    j       .L3 
    ret
.globl cr_isWhiteSpace
cr_isWhitespace:
    mv      a0,a5
    li      a5,32            # Carga el valor de un espacio en blanco (' ')
    beq     a0,a5,.L2        # Si el valor de a0 es un espacio (' '), salta a .L2
    li      a5,9            # Carga el valor de una tabulación ('\t')
    beq     a0,a5,.L2        # Si el valor de a0 es un espacio (' \t'), salta a .L2
    #Para True
    li      a0,1
    j       .L3 
    ret                                   
# Delay 
.globl cr_delay
cr_delay:
    li t0, 1000
    mul a0, a0, t0  #(creator_udelay uses microseconds)
    addi sp, sp, -4       
    sw ra, 0(sp)     
    call    creator_udelay
    lw ra, 0(sp)     
    addi sp, sp, 4
    jr ra             
.globl cr_delayMicroseconds
cr_delayMicroseconds:
    addi sp, sp, -4       
    sw ra, 0(sp)     # Guardar el valor de ra (return address)
    call    creator_udelay
    lw ra, 0(sp)     # Recupera el valor de ra
    addi sp, sp, 4
    jr ra
#AUX    
.L2:
    #Para false
    li      a0,0
    jr      ra 
.L3:
    li      a0,1
    jr      ra                    
.globl cr_randomSeed
cr_randomSeed:
    mv t0, a0        # Valor semilla
    addi sp, sp, -4       
    sw ra, 0(sp)     # Guardar el valor de ra (return address)
    call    srand
    lw ra, 0(sp)     # Recupera el valor de ra
    addi sp, sp, 4

    jr ra             # Retorna al programa principal

.globl cr_random
cr_random:
    mv t0, a0        # Valor máximo
    #li t0, 20
    #li t1, 10
    
    addi sp, sp, -4      
    sw ra, 0(sp)     # Guardar el valor de ra (return address)

    li a0, 0
    call    rand      # rand() genera un valor en a0

    lw ra, 0(sp)     # Recupera el valor de ra
    addi sp, sp, 4
    # a0 contiene el número aleatorio
    mv t2, a0         # Guarda el número aleatorio en t2
    bnez a1,random_maxmin
    addi t0,t0,1 #t0 = max + 1
    rem t0, t2, t0    # t0 = rand() % (max + 1)
    mv a0, t0         # Regresa el número aleatorio generado
    jr ra             # Retorna al programa principal

random_maxmin:
    mv t1, a1        # Valor mínimo
    # Calcula (max - min + 1)
    sub t3, t0, t1    # t3 = max - min
    addi t3, t3, 1    # t3 = max - min + 1
    rem t0, t2, t3    # t0 = rand() % (max - min + 1)
    add a0, t0, t1    # t0 = rand() % (max - min + 1) + min

    jr ra             # Retorna al programa principal
# Serial: Doing things with the monitor
.globl cr_serial_available
.extern serial_available
cr_serial_available:
    addi sp, sp, -32       # Reservar espacio para ra + t0-t6 (1 + 7 registros = 8 * 4 bytes = 32 bytes)
    sw ra, 28(sp)          # Guardar ra en la parte superior del frame
    sw t0, 0(sp)           # Guardar t0
    sw t1, 4(sp)           # Guardar t1
    sw t2, 8(sp)           # Guardar t2
    sw t3, 12(sp)          # Guardar t3
    sw t4, 16(sp)          # Guardar t4
    sw t5, 20(sp)          # Guardar t5
    sw t6, 24(sp)          # Guardar t6
    jal ra,serial_available
    lw t0, 0(sp)           # Restaurar t0
    lw t1, 4(sp)           # Restaurar t1
    lw t2, 8(sp)           # Restaurar t2
    lw t3, 12(sp)          # Restaurar t3
    lw t4, 16(sp)          # Restaurar t4
    lw t5, 20(sp)          # Restaurar t5
    lw t6, 24(sp)          # Restaurar t6
    lw ra, 28(sp)          # Restaurar ra
    addi sp, sp, 32        # Liberar espacio del stack
    jr ra

.globl cr_serial_availableForWrite
.extern serial_availableForWrite
cr_serial_availableForWrite:
    addi sp, sp, -32       # Reservar espacio para ra + t0-t6 (1 + 7 registros = 8 * 4 bytes = 32 bytes)
    sw ra, 28(sp)          # Guardar ra en la parte superior del frame
    sw t0, 0(sp)           # Guardar t0
    sw t1, 4(sp)           # Guardar t1
    sw t2, 8(sp)           # Guardar t2
    sw t3, 12(sp)          # Guardar t3
    sw t4, 16(sp)          # Guardar t4
    sw t5, 20(sp)          # Guardar t5
    sw t6, 24(sp)          # Guardar t6
    jal ra,serial_availableForWrite
    lw t0, 0(sp)           # Restaurar t0
    lw t1, 4(sp)           # Restaurar t1
    lw t2, 8(sp)           # Restaurar t2
    lw t3, 12(sp)          # Restaurar t3
    lw t4, 16(sp)          # Restaurar t4
    lw t5, 20(sp)          # Restaurar t5
    lw t6, 24(sp)          # Restaurar t6
    lw ra, 28(sp)          # Restaurar ra
    addi sp, sp, 32        # Liberar espacio del stack
    jr ra

.globl cr_serial_begin
.extern serial_begin
cr_serial_begin:
    addi sp, sp, -40       # Reservar espacio para ra + t0-t6 + a0 + a1 (10 * 4 bytes = 40 bytes)
    sw ra, 36(sp)          # Guardar ra en la parte superior del frame
    sw t0, 0(sp)           # Guardar t0
    sw t1, 4(sp)           # Guardar t1
    sw t2, 8(sp)           # Guardar t2
    sw t3, 12(sp)          # Guardar t3
    sw t4, 16(sp)          # Guardar t4
    sw t5, 20(sp)          # Guardar t5
    sw t6, 24(sp)          # Guardar t6
    sw a0, 28(sp)          # Guardar a0
    sw a1, 32(sp)          # Guardar a1
    jal ra,serial_begin
    lw t0, 0(sp)           # Restaurar t0
    lw t1, 4(sp)           # Restaurar t1
    lw t2, 8(sp)           # Restaurar t2
    lw t3, 12(sp)          # Restaurar t3
    lw t4, 16(sp)          # Restaurar t4
    lw t5, 20(sp)          # Restaurar t5
    lw t6, 24(sp)          # Restaurar t6
    lw a0, 28(sp)          # Restaurar a0
    lw a1, 32(sp)          # Restaurar a1
    lw ra, 36(sp)          # Restaurar ra
    addi sp, sp, 40        # Liberar espacio del stack
    jr ra

.globl cr_serial_end
.extern serial_end
cr_serial_end: 
    addi sp, sp, -32       # Reservar espacio para ra + t0-t6 (1 + 7 registros = 8 * 4 bytes = 32 bytes)
    sw ra, 28(sp)          # Guardar ra en la parte superior del frame
    sw t0, 0(sp)           # Guardar t0
    sw t1, 4(sp)           # Guardar t1
    sw t2, 8(sp)           # Guardar t2
    sw t3, 12(sp)          # Guardar t3
    sw t4, 16(sp)          # Guardar t4
    sw t5, 20(sp)          # Guardar t5
    sw t6, 24(sp)          # Guardar t6
    jal ra,serial_end
    lw t0, 0(sp)           # Restaurar t0
    lw t1, 4(sp)           # Restaurar t1
    lw t2, 8(sp)           # Restaurar t2
    lw t3, 12(sp)          # Restaurar t3
    lw t4, 16(sp)          # Restaurar t4
    lw t5, 20(sp)          # Restaurar t5
    lw t6, 24(sp)          # Restaurar t6
    lw ra, 28(sp)          # Restaurar ra
    addi sp, sp, 32        # Liberar espacio del stack
    jr ra

.globl cr_serial_find
.extern serial_find
cr_serial_find: 
    addi sp, sp, -32       # Reservar espacio para ra + t0-t6 (1 + 7 registros = 8 * 4 bytes = 32 bytes)
    sw ra, 28(sp)          # Guardar ra en la parte superior del frame
    sw t0, 0(sp)           # Guardar t0
    sw t1, 4(sp)           # Guardar t1
    sw t2, 8(sp)           # Guardar t2
    sw t3, 12(sp)          # Guardar t3
    sw t4, 16(sp)          # Guardar t4
    sw t5, 20(sp)          # Guardar t5
    sw t6, 24(sp)          # Guardar t6
    jal ra,serial_find
    lw t0, 0(sp)           # Restaurar t0
    lw t1, 4(sp)           # Restaurar t1
    lw t2, 8(sp)           # Restaurar t2
    lw t3, 12(sp)          # Restaurar t3
    lw t4, 16(sp)          # Restaurar t4
    lw t5, 20(sp)          # Restaurar t5
    lw t6, 24(sp)          # Restaurar t6
    lw ra, 28(sp)          # Restaurar ra
    addi sp, sp, 32        # Liberar espacio del stack
    jr ra

.globl cr_serial_findUntil
.extern serial_findUntil
cr_serial_findUntil: 
    addi sp, sp, -32       # Reservar espacio para ra + t0-t6 (1 + 7 registros = 8 * 4 bytes = 32 bytes)
    sw ra, 28(sp)          # Guardar ra en la parte superior del frame
    sw t0, 0(sp)           # Guardar t0
    sw t1, 4(sp)           # Guardar t1
    sw t2, 8(sp)           # Guardar t2
    sw t3, 12(sp)          # Guardar t3
    sw t4, 16(sp)          # Guardar t4
    sw t5, 20(sp)          # Guardar t5
    sw t6, 24(sp)          # Guardar t6
    jal ra,serial_findUntil
    lw t0, 0(sp)           # Restaurar t0
    lw t1, 4(sp)           # Restaurar t1
    lw t2, 8(sp)           # Restaurar t2
    lw t3, 12(sp)          # Restaurar t3
    lw t4, 16(sp)          # Restaurar t4
    lw t5, 20(sp)          # Restaurar t5
    lw t6, 24(sp)          # Restaurar t6
    lw ra, 28(sp)          # Restaurar ra
    addi sp, sp, 32        # Liberar espacio del stack
    jr ra 

.globl cr_serial_flush
.extern serial_flush
cr_serial_flush:
    addi sp, sp, -32       # Reservar espacio para ra + t0-t6 (1 + 7 registros = 8 * 4 bytes = 32 bytes)
    sw ra, 28(sp)          # Guardar ra en la parte superior del frame
    sw t0, 0(sp)           # Guardar t0
    sw t1, 4(sp)           # Guardar t1
    sw t2, 8(sp)           # Guardar t2
    sw t3, 12(sp)          # Guardar t3
    sw t4, 16(sp)          # Guardar t4
    sw t5, 20(sp)          # Guardar t5
    sw t6, 24(sp)          # Guardar t6
    jal ra,serial_flush
    lw t0, 0(sp)           # Restaurar t0
    lw t1, 4(sp)           # Restaurar t1
    lw t2, 8(sp)           # Restaurar t2
    lw t3, 12(sp)          # Restaurar t3
    lw t4, 16(sp)          # Restaurar t4
    lw t5, 20(sp)          # Restaurar t5
    lw t6, 24(sp)          # Restaurar t6
    lw ra, 28(sp)          # Restaurar ra
    addi sp, sp, 32        # Liberar espacio del stack
    jr ra
.global cr_serial_peek
.extern serial_peek   
cr_serial_peek:
    addi sp, sp, -32       # Reservar espacio para ra + t0-t6 (1 + 7 registros = 8 * 4 bytes = 32 bytes)
    sw ra, 28(sp)          # Guardar ra en la parte superior del frame
    sw t0, 0(sp)           # Guardar t0
    sw t1, 4(sp)           # Guardar t1
    sw t2, 8(sp)           # Guardar t2
    sw t3, 12(sp)          # Guardar t3
    sw t4, 16(sp)          # Guardar t4
    sw t5, 20(sp)          # Guardar t5
    sw t6, 24(sp)          # Guardar t6
    jal ra,serial_peek
    lw t0, 0(sp)           # Restaurar t0
    lw t1, 4(sp)           # Restaurar t1
    lw t2, 8(sp)           # Restaurar t2
    lw t3, 12(sp)          # Restaurar t3
    lw t4, 16(sp)          # Restaurar t4
    lw t5, 20(sp)          # Restaurar t5
    lw t6, 24(sp)          # Restaurar t6
    lw ra, 28(sp)          # Restaurar ra
    addi sp, sp, 32        # Liberar espacio del stack
    ret     
.globl cr_serial_parseFloat
#.extern serial_parseFloat
cr_serial_parseFloat: #TODO
    /*addi sp, sp, -4      
    sw ra, 0(sp)     # Guardar el valor de ra (return address)
    jal ra,serial_flush
    lw ra, 0(sp)     # Recupera el valor de ra
    addi sp, sp, 4*/
    jr ra

.globl cr_serial_printf
.extern aux_serial_printf
cr_serial_printf: #Only Char
    addi sp, sp, -32       # Reservar espacio para ra + t0-t6 (1 + 7 registros = 8 * 4 bytes = 32 bytes)
    sw ra, 28(sp)          # Guardar ra en la parte superior del frame
    sw t0, 0(sp)           # Guardar t0
    sw t1, 4(sp)           # Guardar t1
    sw t2, 8(sp)           # Guardar t2
    sw t3, 12(sp)          # Guardar t3
    sw t4, 16(sp)          # Guardar t4
    sw t5, 20(sp)          # Guardar t5
    sw t6, 24(sp)          # Guardar t6
    jal ra,aux_serial_printf
    lw t0, 0(sp)           # Restaurar t0
    lw t1, 4(sp)           # Restaurar t1
    lw t2, 8(sp)           # Restaurar t2
    lw t3, 12(sp)          # Restaurar t3
    lw t4, 16(sp)          # Restaurar t4
    lw t5, 20(sp)          # Restaurar t5
    lw t6, 24(sp)          # Restaurar t6
    lw ra, 28(sp)          # Restaurar ra
    addi sp, sp, 32        # Liberar espacio del stack
    jr ra             

                 

/*.globl cr_serial_println
#.extern serial_println     
cr_serial_println: #TODO
    addi sp, sp, -4      
    sw ra, 0(sp)     # Guardar el valor de ra (return address)
    jal ra,cr_serial_print 
    lw ra, 0(sp)     # Recupera el valor de ra
    addi sp, sp, 4

    la a0, cr_newline
    li a7,4
    addi sp, sp, -4      
    sw ra, 0(sp)     # Guardar el valor de ra (return address)
    jal ra,cr_serial_print 
    lw ra, 0(sp)     # Recupera el valor de ra
    addi sp, sp, 4
    jr ra */
.globl cr_serial_parseInt #ATM Serial.parseint(SKIP_NONE)
.extern serial_parseInt
cr_serial_parseInt: #Lee números
    addi sp, sp, -32       # Reservar espacio para ra + t0-t6 (1 + 7 registros = 8 * 4 bytes = 32 bytes)
    sw ra, 28(sp)          # Guardar ra en la parte superior del frame
    sw t0, 0(sp)           # Guardar t0
    sw t1, 4(sp)           # Guardar t1
    sw t2, 8(sp)           # Guardar t2
    sw t3, 12(sp)          # Guardar t3
    sw t4, 16(sp)          # Guardar t4
    sw t5, 20(sp)          # Guardar t5
    sw t6, 24(sp)          # Guardar t6
    jal ra,serial_parseInt
    lw t0, 0(sp)           # Restaurar t0
    lw t1, 4(sp)           # Restaurar t1
    lw t2, 8(sp)           # Restaurar t2
    lw t3, 12(sp)          # Restaurar t3
    lw t4, 16(sp)          # Restaurar t4
    lw t5, 20(sp)          # Restaurar t5
    lw t6, 24(sp)          # Restaurar t6
    lw ra, 28(sp)          # Restaurar ra
    addi sp, sp, 32        # Liberar espacio del stack
    jr ra      
# .globl cr_serial_parseInt #ATM Serial.parseint(SKIP_NONE)
# cr_serial_parseInt: #Lee números
#     addi sp, sp, -4       # Reservar espacio en el stack
#     sw ra, 0(sp)          # Guardar el registro RA en el stack 
#     li a7, 5
#     addi sp, sp, -128
#     sw x1,  120(sp)
#     sw x3,  112(sp)
#     sw x4,  108(sp)
#     sw x5,  104(sp)
#     sw x6,  100(sp)
#     sw x7,  96(sp)
#     sw x8,  92(sp)
#     sw x9,  88(sp)
#     sw x18, 52(sp)
#     sw x19, 48(sp)
#     sw x20, 44(sp)
#     sw x21, 40(sp)
#     sw x22, 36(sp)
#     sw x23, 32(sp)
#     sw x24, 28(sp)
#     sw x25, 24(sp)
#     sw x26, 20(sp)
#     sw x27, 16(sp)
#     sw x28, 12(sp)
#     sw x29, 8(sp)
#     sw x30, 4(sp)
#     sw x31, 0(sp)
#     jal _myecall
#     lw x1,  120(sp)
#     lw x3,  112(sp)
#     lw x4,  108(sp)
#     lw x5,  104(sp)
#     lw x6,  100(sp)
#     lw x7,  96(sp)
#     lw x8,  92(sp)
#     lw x9,  88(sp)
#     lw x18, 52(sp)
#     lw x19, 48(sp)
#     lw x20, 44(sp)
#     lw x21, 40(sp)
#     lw x22, 36(sp)
#     lw x23, 32(sp)
#     lw x24, 28(sp)
#     lw x25, 24(sp)
#     lw x26, 20(sp)
#     lw x27, 16(sp)
#     lw x28, 12(sp)
#     lw x29, 8(sp)
#     lw x30, 4(sp)
#     lw x31, 0(sp)
#     addi sp, sp, 128
#     lw ra, 0(sp)           
#     addi sp, sp, 4       # Liberar el espacio del stack

#     add t0, a0, zero
#     jr ra
#     ret    

.globl cr_serial_read
.extern serial_read
cr_serial_read: #Lee números
    addi sp, sp, -32       # Reservar espacio para ra + t0-t6 (1 + 7 registros = 8 * 4 bytes = 32 bytes)
    sw ra, 28(sp)          # Guardar ra en la parte superior del frame
    sw t0, 0(sp)           # Guardar t0
    sw t1, 4(sp)           # Guardar t1
    sw t2, 8(sp)           # Guardar t2
    sw t3, 12(sp)          # Guardar t3
    sw t4, 16(sp)          # Guardar t4
    sw t5, 20(sp)          # Guardar t5
    sw t6, 24(sp)          # Guardar t6
    jal ra,serial_read
    lw t0, 0(sp)           # Restaurar t0
    lw t1, 4(sp)           # Restaurar t1
    lw t2, 8(sp)           # Restaurar t2
    lw t3, 12(sp)          # Restaurar t3
    lw t4, 16(sp)          # Restaurar t4
    lw t5, 20(sp)          # Restaurar t5
    lw t6, 24(sp)          # Restaurar t6
    lw ra, 28(sp)          # Restaurar ra
    addi sp, sp, 32        # Liberar espacio del stack
    ret

.globl aux_readBytes
aux_readBytes: #Serial.readBytes(buffer, length) lee letras
    #la a0, space 
    #add a1, a1, zero
    #li a1,5
    add a1,a1,zero

    addi sp, sp, -4       # Reservar espacio en el stack
    sw ra, 0(sp)          # Guardar el registro RA en el stack 
    li a7, 8
    addi sp, sp, -128
    sw x1,  120(sp)
    sw x3,  112(sp)
    sw x4,  108(sp)
    sw x5,  104(sp)
    sw x6,  100(sp)
    sw x7,  96(sp)
    sw x8,  92(sp)
    sw x9,  88(sp)
    sw x18, 52(sp)
    sw x19, 48(sp)
    sw x20, 44(sp)
    sw x21, 40(sp)
    sw x22, 36(sp)
    sw x23, 32(sp)
    sw x24, 28(sp)
    sw x25, 24(sp)
    sw x26, 20(sp)
    sw x27, 16(sp)
    sw x28, 12(sp)
    sw x29, 8(sp)
    sw x30, 4(sp)
    sw x31, 0(sp)
    jal _myecall
    lw x1,  120(sp)
    lw x3,  112(sp)
    lw x4,  108(sp)
    lw x5,  104(sp)
    lw x6,  100(sp)
    lw x7,  96(sp)
    lw x8,  92(sp)
    lw x9,  88(sp)
    lw x18, 52(sp)
    lw x19, 48(sp)
    lw x20, 44(sp)
    lw x21, 40(sp)
    lw x22, 36(sp)
    lw x23, 32(sp)
    lw x24, 28(sp)
    lw x25, 24(sp)
    lw x26, 20(sp)
    lw x27, 16(sp)
    lw x28, 12(sp)
    lw x29, 8(sp)
    lw x30, 4(sp)
    lw x31, 0(sp)
    addi sp, sp, 128
    lw ra, 0(sp)           
    addi sp, sp, 4       # Liberar el espacio del stack

    add t0, a0, zero
    jr ra
    ret
.global cr_serial_readBytes   
cr_serial_readBytes:
    addi sp, sp, -32       # Reservar espacio para ra + t0-t6 (1 + 7 registros = 8 * 4 bytes = 32 bytes)
    sw ra, 28(sp)          # Guardar ra en la parte superior del frame
    sw t0, 0(sp)           # Guardar t0
    sw t1, 4(sp)           # Guardar t1
    sw t2, 8(sp)           # Guardar t2
    sw t3, 12(sp)          # Guardar t3
    sw t4, 16(sp)          # Guardar t4
    sw t5, 20(sp)          # Guardar t5
    sw t6, 24(sp)          # Guardar t6
    jal ra,serial_readBytes
    lw t0, 0(sp)           # Restaurar t0
    lw t1, 4(sp)           # Restaurar t1
    lw t2, 8(sp)           # Restaurar t2
    lw t3, 12(sp)          # Restaurar t3
    lw t4, 16(sp)          # Restaurar t4
    lw t5, 20(sp)          # Restaurar t5
    lw t6, 24(sp)          # Restaurar t6
    lw ra, 28(sp)          # Restaurar ra
    addi sp, sp, 32        # Liberar espacio del stack
    ret    
.global cr_serial_readBytesUntil 
.extern serial_readBytesUntil   
cr_serial_readBytesUntil:
    #Searches until it founds the char in a2
    addi sp, sp, -32       # Reservar espacio para ra + t0-t6 (1 + 7 registros = 8 * 4 bytes = 32 bytes)
    sw ra, 28(sp)          # Guardar ra en la parte superior del frame
    sw t0, 0(sp)           # Guardar t0
    sw t1, 4(sp)           # Guardar t1
    sw t2, 8(sp)           # Guardar t2
    sw t3, 12(sp)          # Guardar t3
    sw t4, 16(sp)          # Guardar t4
    sw t5, 20(sp)          # Guardar t5
    sw t6, 24(sp)          # Guardar t6
    jal ra,serial_readBytesUntil
    lw t0, 0(sp)           # Restaurar t0
    lw t1, 4(sp)           # Restaurar t1
    lw t2, 8(sp)           # Restaurar t2
    lw t3, 12(sp)          # Restaurar t3
    lw t4, 16(sp)          # Restaurar t4
    lw t5, 20(sp)          # Restaurar t5
    lw t6, 24(sp)          # Restaurar t6
    lw ra, 28(sp)          # Restaurar ra
    addi sp, sp, 32        # Liberar espacio del stack
    ret
# .global cr_serial_readString
# .extern serial_readString   
# cr_serial_readString:
#     addi sp, sp, -4      
#     sw ra, 0(sp)     # Guardar el valor de ra (return address)
#     jal ra, serial_readString
#     lw ra, 0(sp)     # Recupera el valor de ra
#     addi sp, sp, 4
#     jr ra
# .global cr_serial_readStringUntil  
# cr_serial_readStringUntil:
#     jr ra  
.global cr_serial_write 
.extern serial_write   
cr_serial_write:
    addi sp, sp, -4      
    sw ra, 0(sp)     # Guardar el valor de ra (return address)
    jal ra,serial_write 
    lw ra, 0(sp)     # Recupera el valor de ra
    addi sp, sp, 4
    jr ra              