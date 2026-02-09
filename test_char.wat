(module
 (import "wasi_snapshot_preview1" "fd_write" (func $f1000005 (param i32) (param i32) (param i32) (param i32) (result i32)))
 (import "wasi_snapshot_preview1" "fd_read" (func $f1000006 (param i32) (param i32) (param i32) (param i32) (result i32)))
 (import "wasi_snapshot_preview1" "path_open" (func $f1000007 (param i32) (param i32) (param i32) (param i32) (param i32) (param i64) (param i64) (param i32) (param i32) (result i32)))
 (import "wasi_snapshot_preview1" "fd_close" (func $f1000008 (param i32) (result i32)))
 (memory 2048)
 (export "memory" (memory 0))
 (data (i32.const 0) "A\0a")
 (func $f0 (result i32)
  (local $l0 i32)
  (local $l1 i32)
  i32.const 0
  local.set $l0
  i32.const 0
  local.set $l1
  block
  loop
  local.get $l0
  local.get $l1
  i32.add
  i32.load8_u
  i32.const 0
  i32.ne
  i32.const 0
  i32.eq
  br_if 1
  local.get $l1
  i32.const 1
  i32.add
  local.set $l1
  br 0
  end
  end
  i32.const 1
  local.get $l0
  i32.const 1
  local.get $l1
  call $f1000005
  drop
  i32.const 0
  return
 )
 (export "main" (func $f0))
 (func $_start
  call $f0
  drop
 )
 (export "_start" (func $_start))
)
