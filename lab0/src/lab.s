.cpu cortex-m0
.thumb
.syntax unified
.fpu softvfp

.global main
main:
    movs r0, #0
    movs r1, #0
loop:
    adds r0, #1
    subs r1, #1
    b    loop
