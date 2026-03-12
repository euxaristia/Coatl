.globl __mem_store
.globl __mem_store8
.globl __mem_load
.globl __mem_load8
.globl __fd_write
.globl __fd_read
.globl __fd_close
.globl __path_open
.globl __tty_get_mode
.globl __tty_set_raw
.globl __tty_restore
.globl __print
.globl __get_argc
.globl __get_argv
.globl __path_create
.globl __tty_has_input
.globl __tty_get_size

.section .rodata
__proc_self_cmdline:
  .asciz "/proc/self/cmdline"

.section .bss
.align 8
__args_inited:
  .long 0
__argc:
  .long 0
__argv_table:
  .zero 256
__cmdline_buf:
  .zero 4096
__pollfd:
  .zero 8

.text

.macro GET_COATL_MEM reg
  adrp \reg, __coatl_mem
  add \reg, \reg, :lo12:__coatl_mem
.endm

__mem_store:
  GET_COATL_MEM x8
  add x0, x0, x8
  str w1, [x0]
  ret

__mem_store8:
  GET_COATL_MEM x8
  add x0, x0, x8
  strb w1, [x0]
  ret

__mem_load:
  GET_COATL_MEM x8
  add x0, x0, x8
  ldrsw x0, [x0]
  ret

__mem_load8:
  GET_COATL_MEM x8
  add x0, x0, x8
  ldrsb x0, [x0]
  ret

__fd_write:
  GET_COATL_MEM x8
  sub sp, sp, #48
  str x8, [sp, #32]
  str x3, [sp, #24]
  add x9, x1, x8
  ldr w10, [x9]
  add x10, x10, x8
  str x10, [sp, #0]
  ldr w10, [x9, #4]
  uxtw x10, w10
  str x10, [sp, #8]
  mov x1, sp
  mov x2, #1
  mov x8, #66
  svc #0
  ldr x8, [sp, #32]
  ldr x3, [sp, #24]
  add x3, x3, x8
  str w0, [x3]
  mov x0, #0
  add sp, sp, #48
  ret

__fd_read:
  GET_COATL_MEM x8
  sub sp, sp, #48
  str x8, [sp, #32]
  str x3, [sp, #24]
  add x9, x1, x8
  ldr w10, [x9]
  add x10, x10, x8
  str x10, [sp, #0]
  ldr w10, [x9, #4]
  uxtw x10, w10
  str x10, [sp, #8]
  mov x1, sp
  mov x2, #1
  mov x8, #65
  svc #0
  ldr x8, [sp, #32]
  ldr x3, [sp, #24]
  add x3, x3, x8
  str w0, [x3]
  mov x0, #0
  add sp, sp, #48
  ret

__fd_close:
  mov x8, #57
  svc #0
  ret

__path_open:
  stp x29, x30, [sp, #-16]!
  mov x29, sp
  ldr x12, [x29, #16]
  GET_COATL_MEM x8
  add x1, x2, x8
  mov x0, #-100
  mov x2, #0
  mov x3, #0
  mov x8, #56
  svc #0
  cmp x0, #0
  b.lt .L_open_fail
  GET_COATL_MEM x8
  add x12, x12, x8
  str w0, [x12]
  mov x0, #0
  ldp x29, x30, [sp], #16
  ret
.L_open_fail:
  GET_COATL_MEM x8
  add x12, x12, x8
  mov w1, #-1
  str w1, [x12]
  mov x0, #1
  ldp x29, x30, [sp], #16
  ret

__print:
  stp x29, x30, [sp, #-32]!
  mov x29, sp
  str x19, [sp, #16]
  str x20, [sp, #24]
  GET_COATL_MEM x8
  add x19, x0, x8
  mov x20, #0
.L_print_len_loop:
  ldrb w9, [x19, x20]
  cbz w9, .L_print_len_done
  add x20, x20, #1
  b .L_print_len_loop
.L_print_len_done:
  mov x0, #1
  mov x1, x19
  mov x2, x20
  mov x8, #64
  svc #0
  mov x0, #0
  ldr x19, [sp, #16]
  ldr x20, [sp, #24]
  ldp x29, x30, [sp], #32
  ret


__init_args:
  stp x29, x30, [sp, #-16]!
  mov x29, sp
  adrp x0, __args_inited; ldr w1, [x0, :lo12:__args_inited]
  cbnz w1, .L_init_done
  mov w1, #1; str w1, [x0, :lo12:__args_inited]
  mov x0, #-100
  adrp x1, __proc_self_cmdline; add x1, x1, :lo12:__proc_self_cmdline
  mov x2, #0; mov x3, #0; mov x8, #56; svc #0
  cmp x0, #0; b.lt .L_init_fail
  mov x19, x0
  mov x0, x19
  adrp x1, __cmdline_buf; add x1, x1, :lo12:__cmdline_buf
  mov x2, #4096; mov x8, #63; svc #0
  mov x20, x0
  mov x0, x19; mov x8, #57; svc #0
  cmp x20, #0; b.le .L_init_fail
  mov w21, #0; mov x22, #0; mov w23, #48032; movk w23, #13, lsl #16
.L_parse_loop:
  cmp x22, x20; b.ge .L_parse_done
  adrp x0, __cmdline_buf; add x0, x0, :lo12:__cmdline_buf
  ldrb w1, [x0, x22]
  cbz w1, .L_parse_skip
  cmp w21, #64; b.ge .L_parse_done
  adrp x0, __argv_table; add x0, x0, :lo12:__argv_table
  str w21, [x0, x21, lsl #2]
.L_copy_loop:
  cmp x22, x20; b.ge .L_copy_end
  adrp x0, __cmdline_buf; add x0, x0, :lo12:__cmdline_buf
  ldrb w1, [x0, x22]
  cbz w1, .L_copy_end
  GET_COATL_MEM x2; strb w1, [x2, x23]
  add x23, x23, #1; add x22, x22, #1; b .L_copy_loop
.L_copy_end:
  GET_COATL_MEM x2; strb wzr, [x2, x23]
  add x23, x23, #1; add w21, w21, #1; b .L_parse_loop
.L_parse_skip:
  add x22, x22, #1; b .L_parse_loop
.L_parse_done:
  adrp x0, __argc; str w21, [x0, :lo12:__argc]; b .L_init_done
.L_init_fail:
  adrp x0, __argc; str wzr, [x0, :lo12:__argc]
.L_init_done:
  ldp x29, x30, [sp], #16; ret

__get_argc:
  stp x29, x30, [sp, #-16]!
  bl __init_args
  adrp x0, __argc; ldr w0, [x0, :lo12:__argc]
  ldp x29, x30, [sp], #16; ret

__get_argv:
  stp x29, x30, [sp, #-16]!
  str x0, [sp, #16]
  bl __init_args
  ldr x0, [sp, #16]
  adrp x1, __argc; ldr w1, [x1, :lo12:__argc]
  cmp w0, w1; b.ge .L_argv_fail
  adrp x1, __argv_table; add x1, x1, :lo12:__argv_table
  ldr w0, [x1, x0, lsl #2]
  ldp x29, x30, [sp], #16; ret
.L_argv_fail:
  mov x0, #0; ldp x29, x30, [sp], #16; ret

__path_create:
  stp x29, x30, [sp, #-16]!
  mov x29, sp
  mov x12, x1
  GET_COATL_MEM x8
  add x1, x0, x8
  mov x0, #-100
  mov x2, #577
  mov x3, #420
  mov x8, #56
  svc #0
  cmp x0, #0
  b.lt .L_create_fail
  GET_COATL_MEM x8
  add x12, x12, x8
  str w0, [x12]
  mov x0, #0
  ldp x29, x30, [sp], #16
  ret
.L_create_fail:
  GET_COATL_MEM x8
  add x12, x12, x8
  mov w1, #-1
  str w1, [x12]
  mov x0, #1
  ldp x29, x30, [sp], #16
  ret

__tty_has_input:
  adrp x8, __pollfd; add x8, x8, :lo12:__pollfd
  str w0, [x8]
  mov w9, #1
  strh w9, [x8, #4]
  strh wzr, [x8, #6]
  mov x2, x1
  mov x1, #1
  mov x0, x8
  mov x8, #73
  svc #0
  cmp x0, #0
  b.le .L_no_input
  adrp x8, __pollfd; add x8, x8, :lo12:__pollfd
  ldrh w9, [x8, #6]
  tst w9, #1
  beq .L_no_input
  mov x0, #1
  ret
.L_no_input:
  mov x0, #0
  ret


__tty_get_mode:
  stp x29, x30, [sp, #-16]!
  mov x29, sp
  GET_COATL_MEM x8
  add x1, x1, x8
  mov x2, x1
  mov x1, #0x5401
  mov x8, #29
  svc #0
  cmp x0, #0
  b.lt .L_tty_get_fail
  mov x0, #0
  ldp x29, x30, [sp], #16
  ret
.L_tty_get_fail:
  neg x0, x0
  ldp x29, x30, [sp], #16
  ret

__tty_set_raw:
  stp x29, x30, [sp, #-96]!
  mov x29, sp
  str x0, [sp, #80]
  str w2, [sp, #88]
  str w3, [sp, #92]
  GET_COATL_MEM x8
  add x1, x1, x8
  add x0, sp, #16
  mov x2, #60
.L_tty_copy:
  ldrb w3, [x1], #1
  strb w3, [x0], #1
  subs x2, x2, #1
  b.ne .L_tty_copy
  ldr w0, [sp, #16]
  mov w1, #0x05EB
  mvn w1, w1
  and w0, w0, w1
  str w0, [sp, #16]
  ldr w0, [sp, #20]
  mov w1, #0x0001
  mvn w1, w1
  and w0, w0, w1
  str w0, [sp, #20]
  ldr w0, [sp, #24]
  mov w1, #0x0130
  mvn w1, w1
  and w0, w0, w1
  mov w1, #0x0030
  orr w0, w0, w1
  str w0, [sp, #24]
  ldr w0, [sp, #28]
  mov w1, #0x804B
  mvn w1, w1
  and w0, w0, w1
  str w0, [sp, #28]
  ldr w3, [sp, #92]
  ldr w2, [sp, #88]
  strb w2, [sp, #39]
  strb w3, [sp, #38]
  ldr x0, [sp, #80]
  mov x1, #0x5402
  add x2, sp, #16
  mov x8, #29
  svc #0
  cmp x0, #0
  b.lt .L_tty_raw_fail
  mov x0, #0
  ldp x29, x30, [sp], #96
  ret
.L_tty_raw_fail:
  neg x0, x0
  ldp x29, x30, [sp], #96
  ret

__tty_restore:
  stp x29, x30, [sp, #-16]!
  mov x29, sp
  GET_COATL_MEM x8
  add x1, x1, x8
  mov x2, x1
  mov x1, #0x5402
  mov x8, #29
  svc #0
  cmp x0, #0
  b.lt .L_tty_restore_fail
  mov x0, #0
  ldp x29, x30, [sp], #16
  ret
.L_tty_restore_fail:
  neg x0, x0
  ldp x29, x30, [sp], #16
  ret

__tty_get_size:
  stp x29, x30, [sp, #-16]!
  mov x29, sp
  GET_COATL_MEM x8
  add x1, x1, x8
  mov x2, x1
  mov x1, #0x5413
  mov x8, #29
  svc #0
  cmp x0, #0
  b.lt .L_tty_size_fail
  mov x0, #0
  ldp x29, x30, [sp], #16
  ret
.L_tty_size_fail:
  neg x0, x0
  ldp x29, x30, [sp], #16
  ret
