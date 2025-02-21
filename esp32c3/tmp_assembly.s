
#
# Creator (https://creatorsim.github.io/creator/)
#

.text

main:
    addi sp, sp, -4
    sw ra, 0(sp)

    li   a0, 23
    li   a1, -77
    li   a2, 45
    jal  x1, sum
    jal  x1, sub
    li   a7, 1
    ecall

    lw ra, 0(sp)
    addi sp, sp, 4
    jr ra
loop:
    nop
main:

  li  t3,  1
  li  t4,  4
  la  t5,  w3
  li  t0,  0

  # loop initialization
  li  t1,  0
  li  t2,  5

  # loop header
loop1: beq t1, t2, end1      # if(t1 == t2) --> jump to fin1

  # loop body
  mul t6, t1, t4             # t1 * t4 -> t6
  lw  t6, 0(t5)              # Memory[t5] -> t6
  add t0, t0, t6             # t6 + t0 -> t0

  # loop next...
  add  t1, t1, t3            # t1 + t3 -> t1
  addi t5, t5, 4
  beq  x0, x0, loop1

  # loop end
end1: 
  #return
  jr ra


