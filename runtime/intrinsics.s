.intel_syntax noprefix

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

  # openat(AT_FDCWD, "/proc/self/cmdline", O_RDONLY)
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

  # read(fd, buf, 4096)
  mov eax, 0
  mov rdi, r12
  lea rsi, [rip+__cmdline_buf]
  mov edx, 4096
  syscall
  mov r13, rax

  # close(fd)
  mov eax, 3
  mov rdi, r12
  syscall

  cmp r13, 0
  jle .L_init_fail

  xor r15d, r15d  # argc
  xor ecx, ecx    # buffer index
  mov r14d, 900000 # dst offset in __coatl_mem

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
