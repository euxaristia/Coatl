(module
  (import "wasi_snapshot_preview1" "fd_write"
    (func $fd_write (param i32 i32 i32 i32) (result i32)))
  (memory (export "memory") 2)
  (data (i32.const 1024) "A")
  (func $main (result i32)
    (local i32)
    i32.const 1024
    local.set 0
    i32.const 1
    local.get 0
    i32.const 1
    i32.const 1
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
