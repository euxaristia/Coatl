macro_rules! x86_64_asm_body {
    () => {
        r#"
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

.globl __tty_get_size
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

__mem_store:
  lea r8, [rip+__coatl_mem]
  add rdi, r8
  mov [rdi], esi
  ret

__mem_store8:
  lea r8, [rip+__coatl_mem]
  add rdi, r8
  mov [rdi], sil
  ret

__mem_load:
  lea r8, [rip+__coatl_mem]
  add rdi, r8
  movsxd rax, dword ptr [rdi]
  ret

__mem_load8:
  lea r8, [rip+__coatl_mem]
  add rdi, r8
  movsx rax, byte ptr [rdi]
  ret

__fd_write:
  lea r8, [rip+__coatl_mem]
  push rcx
  add rsi, r8
  mov eax, [rsi+4]
  push rax
  mov eax, [rsi]
  add rax, r8
  push rax
  mov rsi, rsp
  mov eax, 20
  syscall
  add rsp, 16
  pop rcx
  lea r8, [rip+__coatl_mem]
  add rcx, r8
  mov [rcx], eax
  mov eax, 0
  ret

__fd_read:
  lea r8, [rip+__coatl_mem]
  push rcx
  add rsi, r8
  mov eax, [rsi+4]
  push rax
  mov eax, [rsi]
  add rax, r8
  push rax
  mov rsi, rsp
  mov eax, 19
  syscall
  add rsp, 16
  pop rcx
  lea r8, [rip+__coatl_mem]
  add rcx, r8
  mov [rcx], eax
  mov eax, 0
  ret

__fd_close:
  mov eax, 3
  syscall
  ret

__path_open:
  push rbx
  push r12
  mov r12, [rsp+40]
  lea rbx, [rip+__coatl_mem]
  mov rsi, rdx
  add rsi, rbx
  mov eax, 257
  mov edi, -100
  xor edx, edx
  xor r10d, r10d
  xor r8d, r8d
  xor r9d, r9d
  syscall
  cmp rax, 0
  jl .L_open_fail
  lea rbx, [rip+__coatl_mem]
  mov dword ptr [rbx + r12], eax
  xor eax, eax
  pop r12
  pop rbx
  ret
.L_open_fail:
  lea rbx, [rip+__coatl_mem]
  mov dword ptr [rbx + r12], -1
  mov eax, 1
  pop r12
  pop rbx
  ret

__print:
  push rbp
  mov rbp, rsp
  push r12
  push r13
  lea r8, [rip+__coatl_mem]
  mov r12, rdi
  add r12, r8
  mov r13, 0
.L_print_len_loop:
  mov al, byte ptr [r12 + r13]
  cmp al, 0
  je .L_print_len_done
  inc r13
  jmp .L_print_len_loop
.L_print_len_done:
  mov eax, 1
  mov edi, 1
  mov rsi, r12
  mov rdx, r13
  syscall
  mov eax, 0
  pop r13
  pop r12
  pop rbp
  ret

__tty_get_mode:
  push rbp
  mov rbp, rsp
  lea r8, [rip+__coatl_mem]
  add rsi, r8
  mov rdx, rsi
  mov rsi, 0x5401
  mov eax, 16
  syscall
  test rax, rax
  js .L_tty_get_fail
  mov eax, 0
  pop rbp
  ret
.L_tty_get_fail:
  neg rax
  pop rbp
  ret

__tty_set_raw:
  push rbp
  mov rbp, rsp
  sub rsp, 64
  push rdi
  push rdx
  push rcx
  lea r8, [rip+__coatl_mem]
  add rsi, r8
  lea rdi, [rbp-64]
  mov rcx, 60
.L_tty_copy:
  mov al, [rsi]
  mov [rdi], al
  inc rsi
  inc rdi
  dec rcx
  jnz .L_tty_copy
  mov eax, [rbp-64+0]
  and eax, ~0x05EB
  mov [rbp-64+0], eax
  mov eax, [rbp-64+4]
  and eax, ~0x0001
  mov [rbp-64+4], eax
  mov eax, [rbp-64+8]
  and eax, ~0x0130
  or eax, 0x0030
  mov [rbp-64+8], eax
  mov eax, [rbp-64+12]
  and eax, ~0x804B
  mov [rbp-64+12], eax
  pop rcx
  pop rdx
  mov [rbp-64+17+6], dl
  mov [rbp-64+17+5], cl
  pop rdi
  mov rsi, 0x5402
  lea rdx, [rbp-64]
  mov eax, 16
  syscall
  test rax, rax
  js .L_tty_raw_fail
  mov eax, 0
  leave
  ret
.L_tty_raw_fail:
  neg rax
  leave
  ret

__tty_restore:
  push rbp
  mov rbp, rsp
  lea r8, [rip+__coatl_mem]
  add rsi, r8
  mov rdx, rsi
  mov rsi, 0x5402
  mov eax, 16
  syscall
  test rax, rax
  js .L_tty_restore_fail
  mov eax, 0
  pop rbp
  ret
.L_tty_restore_fail:
  neg rax
  pop rbp
  ret

__tty_get_size:
  push rbp
  mov rbp, rsp
  lea r8, [rip+__coatl_mem]
  add rsi, r8
  mov rdx, rsi
  mov rsi, 0x5413
  mov eax, 16
  syscall
  test rax, rax
  js .L_tty_size_fail
  mov eax, 0
  pop rbp
  ret
.L_tty_size_fail:
  neg rax
  pop rbp
  ret

__init_args:
  push rbp
  mov rbp, rsp
  push rbx
  push r12
  push r13
  push r14
  push r15
  mov eax, dword ptr [rip+__args_inited]
  test eax, eax
  jne .L_init_done
  mov dword ptr [rip+__args_inited], 1
  mov eax, 257
  mov edi, -100
  lea rsi, [rip+__proc_self_cmdline]
  xor edx, edx
  xor r10d, r10d
  xor r8d, r8d
  xor r9d, r9d
  syscall
  cmp rax, 0
  jl .L_init_fail
  mov r12, rax
  mov eax, 0
  mov rdi, r12
  lea rsi, [rip+__cmdline_buf]
  mov edx, 4096
  syscall
  mov r13, rax
  mov eax, 3
  mov rdi, r12
  syscall
  cmp r13, 0
  jle .L_init_fail
  xor r15d, r15d
  xor ecx, ecx
  mov r14d, 900000
.L_parse_loop:
  cmp rcx, r13
  jge .L_parse_done
  lea rbx, [rip+__cmdline_buf]
  mov al, byte ptr [rbx + rcx]
  cmp al, 0
  jne .L_arg_start
  inc rcx
  jmp .L_parse_loop
.L_arg_start:
  cmp r15d, 64
  jge .L_parse_done
  mov edx, r14d
  lea rbx, [rip+__argv_table]
  mov dword ptr [rbx + r15*4], edx
.L_copy_loop:
  cmp rcx, r13
  jge .L_copy_end
  lea rbx, [rip+__cmdline_buf]
  mov al, byte ptr [rbx + rcx]
  cmp al, 0
  je .L_copy_end
  lea rbx, [rip+__coatl_mem]
  mov byte ptr [rbx + r14], al
  inc r14
  inc rcx
  jmp .L_copy_loop
.L_copy_end:
  lea rbx, [rip+__coatl_mem]
  mov byte ptr [rbx + r14], 0
  inc r14
  inc r15d
  cmp rcx, r13
  jge .L_parse_loop
  lea rbx, [rip+__cmdline_buf]
  mov al, byte ptr [rbx + rcx]
  cmp al, 0
  jne .L_parse_loop
  inc rcx
  jmp .L_parse_loop
.L_parse_done:
  mov dword ptr [rip+__argc], r15d
  jmp .L_init_done
.L_init_fail:
  mov dword ptr [rip+__argc], 0
.L_init_done:
  pop r15
  pop r14
  pop r13
  pop r12
  pop rbx
  leave
  ret

__get_argc:
  call __init_args
  mov eax, dword ptr [rip+__argc]
  ret

__get_argv:
  push rbx
  call __init_args
  mov ecx, dword ptr [rip+__argc]
  cmp edi, ecx
  jge .L_argv_fail
  lea rbx, [rip+__argv_table]
  mov eax, dword ptr [rbx + rdi*4]
  pop rbx
  ret
.L_argv_fail:
  pop rbx
  xor eax, eax
  ret

__path_create:
  push rbx
  push r12
  mov r12, rsi
  lea rbx, [rip+__coatl_mem]
  mov rsi, rdi
  add rsi, rbx
  mov eax, 257
  mov edi, -100
  mov edx, 577
  mov r10d, 420
  xor r8d, r8d
  xor r9d, r9d
  syscall
  cmp rax, 0
  jl .L_create_fail
  lea rbx, [rip+__coatl_mem]
  mov dword ptr [rbx + r12], eax
  xor eax, eax
  pop r12
  pop rbx
  ret
.L_create_fail:
  lea rbx, [rip+__coatl_mem]
  mov dword ptr [rbx + r12], -1
  mov eax, 1
  pop r12
  pop rbx
  ret

__tty_has_input:
  mov dword ptr [rip+__pollfd], edi
  mov word ptr [rip+__pollfd + 4], 1
  mov word ptr [rip+__pollfd + 6], 0
  mov edx, esi
  mov esi, 1
  lea rdi, [rip+__pollfd]
  mov eax, 7
  syscall
  cmp rax, 0
  jle .L_no_input
  mov ax, word ptr [rip+__pollfd + 6]
  test ax, 1
  jz .L_no_input
  mov eax, 1
  ret
.L_no_input:
  xor eax, eax
  ret
"#
    };
}

macro_rules! x86_64_asm_text {
    () => {
        concat!(".intel_syntax noprefix\n", x86_64_asm_body!())
    };
}

macro_rules! aarch64_asm_text {
    () => {
        r#".globl __mem_store
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
"#
    };
}

pub const INTRINSICS_X86_64: &str = x86_64_asm_text!();
pub const INTRINSICS_AARCH64: &str = aarch64_asm_text!();

#[cfg(target_arch = "x86_64")]
std::arch::global_asm!(
    ".weak __coatl_mem\n",
    x86_64_asm_body!(),
);

#[cfg(target_arch = "aarch64")]
std::arch::global_asm!(
    ".weak __coatl_mem\n",
    aarch64_asm_text!(),
);
