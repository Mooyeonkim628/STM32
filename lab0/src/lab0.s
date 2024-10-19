.cpu cortex-m0
.thumb
.syntax unified
.fpu softvfp

.global main
main:
	ldr   r1,=0xd7685983
	lsls  r0,r1,#11
	movs  r0,#222
	bcc login
    bkpt

.global login
login:
    nop
