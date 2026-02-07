.intel_syntax noprefix
.globl __mem_store
.globl __mem_store8
.globl __mem_load
.globl __mem_load8
.globl __fd_write
.globl __fd_read
.globl __fd_close
.globl __path_open

__mem_store:
  lea r8, [rip+__coatl_mem]
  add rdi, r8
  mov [rdi], rsi
  ret

__mem_store8:
  lea r8, [rip+__coatl_mem]
  add rdi, r8
  mov [rdi], sil
  ret

__mem_load:
  lea r8, [rip+__coatl_mem]
  add rdi, r8
  mov rax, [rdi]
  ret

__mem_load8:
  lea r8, [rip+__coatl_mem]
  add rdi, r8
  movzx rax, byte ptr [rdi]
  ret

__fd_write:
  # rdi=fd, rsi=iov, rdx=cnt, rcx=res
  lea r8, [rip+__coatl_mem]
  push rcx             # save res_ptr
  add rsi, r8          # fix iov pointer
  # fix iov_base
  mov rax, [rsi]       # rax = msg_offset
  add rax, r8          # rax = real msg ptr
  mov [rsi], rax       # iov[0].iov_base = real msg ptr

  mov eax, 20          # writev
  syscall

  # store bytes written at res_ptr and return 0
  pop rcx              # rcx = res_ptr
  lea r8, [rip+__coatl_mem]
  add rcx, r8
  mov [rcx], eax       # *res_ptr = bytes written
  mov eax, 0           # WASI success
  ret

__fd_read:
  # rdi=fd, rsi=iov, rdx=cnt, rcx=res
  lea r8, [rip+__coatl_mem]
  push rcx             # save res_ptr
  add rsi, r8
  # fix iov_base
  mov rax, [rsi]
  add rax, r8
  mov [rsi], rax

  mov eax, 19          # readv
  syscall

  # store bytes read at res_ptr and return 0
  pop rcx
  lea r8, [rip+__coatl_mem]
  add rcx, r8
  mov [rcx], eax
  mov eax, 0           # WASI success
  ret

__fd_close:
  mov eax, 3
  syscall
  ret

__path_open:
  push rbp
  mov rbp, rsp
  # Compiler pushes args left-to-right, pops last 6 into regs:
  #   rdi=pathlen(arg4), rsi=oflags(arg5), rdx=fs_rights_base(arg6),
  #   rcx=fs_rights_inh(arg7), r8=fdflags(arg8), r9=fd_ptr(arg9)
  # Stack: [rbp+16]=path_off(arg3), [rbp+24]=dirflags(arg2), [rbp+32]=dirfd(arg1)

  # Save fd_ptr (r9) and oflags (rsi) before clobbering regs
  push r9              # save fd_ptr
  mov r11, rsi         # r11 = oflags

  # openat(dirfd, path, flags, mode)
  # Linux syscall: rdi=dirfd, rsi=path, rdx=flags, r10=mode
  lea r10, [rip+__coatl_mem]
  mov rsi, [rbp+16]    # path_off
  add rsi, r10         # real path pointer
  mov rdi, -100        # AT_FDCWD

  # Map WASI oflags to Linux flags
  mov rdx, 0
  test r11, 1          # CREAT bit
  jz .L_open_flags_done
  mov rdx, 0x241       # WRONLY|CREAT|TRUNC
.L_open_flags_done:

  mov r10, 0x1A4       # mode 0644 octal
  mov eax, 257         # openat
  syscall

  # Store result fd at fd_ptr in linear memory
  pop r11              # r11 = fd_ptr
  lea r10, [rip+__coatl_mem]
  add r11, r10
  mov [r11], eax       # store fd

  mov eax, 0           # WASI success
  pop rbp
  ret
