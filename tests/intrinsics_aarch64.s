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
  ldr w0, [x0]
  ret

__mem_load8:
  GET_COATL_MEM x8
  add x0, x0, x8
  ldrb w0, [x0]
  ret

__fd_write:
  // x0=fd, x1=iov_off, x2=cnt, x3=res_off
  GET_COATL_MEM x8
  sub sp, sp, #48
  str x8, [sp, #32]           // save coatl_mem base
  str x3, [sp, #24]           // save res_off
  add x9, x1, x8              // x9 = absolute iov struct address
  ldr w10, [x9]               // load iov_base offset from coatl memory
  add x10, x10, x8            // convert to absolute address
  str x10, [sp, #0]           // iovec[0].iov_base
  ldr w10, [x9, #4]           // load iov_len
  uxtw x10, w10               // zero-extend to 64-bit
  str x10, [sp, #8]           // iovec[0].iov_len
  mov x1, sp                  // x1 = pointer to iovec on stack
  mov x2, #1                  // x2 = iovcnt = 1
  mov x8, #66                 // writev
  svc #0
  ldr x8, [sp, #32]           // restore coatl_mem base
  ldr x3, [sp, #24]           // restore res_off
  add x3, x3, x8              // res = res_off + base
  str w0, [x3]                // store bytes written
  mov x0, #0                  // return 0 (success)
  add sp, sp, #48
  ret

__fd_read:
  // x0=fd, x1=iov_off, x2=cnt, x3=res_off
  GET_COATL_MEM x8
  sub sp, sp, #48
  str x8, [sp, #32]           // save coatl_mem base
  str x3, [sp, #24]           // save res_off
  add x9, x1, x8              // x9 = absolute iov struct address
  ldr w10, [x9]               // load iov_base offset from coatl memory
  add x10, x10, x8            // convert to absolute address
  str x10, [sp, #0]           // iovec[0].iov_base
  ldr w10, [x9, #4]           // load iov_len
  uxtw x10, w10               // zero-extend to 64-bit
  str x10, [sp, #8]           // iovec[0].iov_len
  mov x1, sp                  // x1 = pointer to iovec on stack
  mov x2, #1                  // x2 = iovcnt = 1
  mov x8, #65                 // readv
  svc #0
  ldr x8, [sp, #32]           // restore coatl_mem base
  ldr x3, [sp, #24]           // restore res_off
  add x3, x3, x8              // res = res_off + base
  str w0, [x3]                // store bytes read
  mov x0, #0                  // return 0 (success)
  add sp, sp, #48
  ret

__fd_close:
  mov x8, #57
  svc #0
  ret

__path_open:
  stp x29, x30, [sp, #-16]!
  mov x29, sp
  sub sp, sp, #32
  str x5, [sp, #16]          // save fd_ptr (coatl offset)
  mov x11, x1                // save oflags
  GET_COATL_MEM x8
  str x8, [sp, #8]           // save coatl_mem base
  ldr x1, [x29, #16]         // load path_off
  add x1, x1, x8             // path = path_off + base
  mov x0, #-100              // AT_FDCWD
  mov x2, #0
  tst x11, #1                // check CREAT bit
  beq .L_open_flags_done
  mov x2, #0x241
.L_open_flags_done:
  mov x3, #0x1A4             // mode 0644
  mov x8, #56                // openat
  svc #0
  ldr x8, [sp, #8]           // restore coatl_mem base
  ldr x5, [sp, #16]          // load fd_ptr (coatl offset)
  add x5, x5, x8             // fd_ptr + base
  str w0, [x5]               // store fd
  mov x0, #0                 // return 0 (success)
  add sp, sp, #32
  ldp x29, x30, [sp], #16
  ret

__tty_get_mode:
  stp x29, x30, [sp, #-16]!
  mov x29, sp
  GET_COATL_MEM x8
  add x1, x1, x8            // mode_ptr = out_ptr + base
  mov x2, x1
  mov x1, #0x5401           // TCGETS
  mov x8, #29               // ioctl
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
  stp x29, x30, [sp, #-80]!
  mov x29, sp
  str x0, [sp, #64]          // save fd
  str x2, [sp, #72]          // save vmin
  str x3, [sp, #76]         // save vtime
  GET_COATL_MEM x8
  add x1, x1, x8            // mode_ptr = out_ptr + base
  add x0, sp, #0            // x0 = stack buffer
  mov x2, #60               // termios size
.L_tty_copy:
  ldrb w3, [x1], #1
  strb w3, [x0], #1
  subs x2, x2, #1
  b.ne .L_tty_copy
  ldr w0, [sp, #12]
  mov w1, #0xFFFFFFF5        // ~(ICANON|ECHO)
  and w0, w0, w1
  str w0, [sp, #12]
  ldr x3, [sp, #76]         // vtime
  ldr x2, [sp, #72]         // vmin
  strb w2, [sp, #23]        // VMIN at offset 17+6
  strb w3, [sp, #22]        // VTIME at offset 17+5
  ldr x0, [sp, #64]         // fd
  mov x1, #0x5402           // TCSETS
  mov x2, sp                // &stack_termios
  mov x8, #29               // ioctl
  svc #0
  cmp x0, #0
  b.lt .L_tty_raw_fail
  mov x0, #0
  ldp x29, x30, [sp], #80
  ret
.L_tty_raw_fail:
  neg x0, x0
  ldp x29, x30, [sp], #80
  ret

__tty_restore:
  stp x29, x30, [sp, #-16]!
  mov x29, sp
  GET_COATL_MEM x8
  add x1, x1, x8            // mode_ptr = out_ptr + base
  mov x2, x1
  mov x1, #0x5402           // TCSETS
  mov x8, #29               // ioctl
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
