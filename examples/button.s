
.data
    time:  .word 100
    buttonPin: .word  6
    ledpin: .word 4
    buttonState:    .word   0

.text
setup:
    #pinMode(buttonPin,INPUT_PULLUP)
    la a0, buttonPin   
    lw a0, 0(a0)       
    li a1,  0x05 #INPUT_PULLUP
    addi sp, sp, -4      
    sw ra, 0(sp)   
    jal ra, pinMode
    lw ra, 0(sp)          
    addi sp, sp, 4
    
    #pinMode(ledpin,OUTPUT)
    la a0, ledpin
    lw a0, 0(a0)       
    li a1,  0x03 #OUTPUT
    addi sp, sp, -4      
    sw ra, 0(sp)   
    jal ra, pinMode
    lw ra, 0(sp)          
    addi sp, sp, 4

    jr ra

button_pressed:    
    la a0, ledpin
    lw a0, 0(a0)
    li a1, 0x1
    addi sp, sp, -4      
    sw ra, 0(sp) 
    jal ra, digitalWrite
    lw ra, 0(sp)          
    addi sp, sp, 4
     

    jal ra, loop


loop:
    la a0, buttonPin   
    lw a0, 0(a0)       
    addi sp, sp, -4      
    sw ra, 0(sp)          
    jal ra, digitalRead
    lw ra, 0(sp)          
    addi sp, sp, 4

    mv t0,a0

    li t1 ,0 #LOW

    beq t0,t1,button_pressed
    
    la a0, ledpin
    lw a0, 0(a0)
    li a1, 0x0
    jal ra, digitalWrite
    
    la a0, time
    lw a0, 0(a0)
    addi sp, sp, -16      
    sw ra, 12(sp)
    jal ra, delay
    lw ra, 12(sp)          
    addi sp, sp, 16 

    j loop

main:
    addi sp, sp, -8       
    sw ra, 0(sp)          
    jal ra, initArduino    
    jal ra, setup
    lw ra, 0(sp)          
    addi sp, sp, 8 
    j loop
    jr ra
    ret 
