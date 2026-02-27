(module
  (import "wasi_snapshot_preview1" "fd_write"
    (func $fd_write (param i32 i32 i32 i32) (result i32)))
  (memory (export "memory") 2)
  (data (i32.const 1024) "Hello, world!\0a")
  (func $main (result i32)
    (local i32)
    (local i32)
    (local i32)
    i32.const 1024
    local.set 0
    i32.const 64
    local.set 1
    i32.const 80
    local.set 2
    local.get 1
    local.get 0
    i32.store
    i32.const 0
    drop
    local.get 1
    i32.const 4
    i32.add
    i32.const 14
    i32.store
    i32.const 0
    drop
    local.get 2
    i32.const 0
    i32.store
    i32.const 0
    drop
    i32.const 1
    local.get 1
    i32.const 1
    local.get 2
    call $fd_write
    drop
    i32.const 0
    return
    i32.const 0
    return
  )
  (export "main" (func $main))
  (func $_start
    call $main
    drop
  )
  (export "_start" (func $_start))
)
