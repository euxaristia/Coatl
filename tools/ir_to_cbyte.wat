(module
 (import "wasi_snapshot_preview1" "fd_write" (func $f1000005 (param i32) (param i32) (param i32) (param i32) (result i32)))
 (import "wasi_snapshot_preview1" "fd_read" (func $f1000006 (param i32) (param i32) (param i32) (param i32) (result i32)))
 (import "wasi_snapshot_preview1" "path_open" (func $f1000007 (param i32) (param i32) (param i32) (param i32) (param i32) (param i64) (param i64) (param i32) (param i32) (result i32)))
 (import "wasi_snapshot_preview1" "fd_close" (func $f1000008 (param i32) (result i32)))
 (memory 2048)
 (export "memory" (memory 0))
 (func $f0 (result i32)
  i32.const 70000000
  return
 )
 (func $f1 (result i32)
  i32.const 72000000
  return
 )
 (func $f2 (result i32)
  i32.const 74000000
  return
 )
 (func $f3 (result i32)
  i32.const 1000000
  return
 )
 (func $f4 (result i32)
  call $f0
  i32.const 8200
  i32.add
  return
 )
 (func $f5 (result i32)
  call $f0
  i32.const 8208
  i32.add
  return
 )
 (func $f6 (result i32)
  call $f0
  i32.const 8216
  i32.add
  return
 )
 (func $f7 (result i32)
  call $f0
  i32.const 8400
  i32.add
  return
 )
 (func $f8 (result i32)
  i32.const 172
  return
 )
 (func $f9 (result i32)
  call $f7
  i32.load
  return
 )
 (func $f10 (param $l0 i32) (result i32)
  (local $l1 i32)
  (local $l2 i32)
  call $f9
  local.set $l1
  block
  local.get $l1
  call $f3
  i32.ge_s
  i32.const 0
  i32.eq
  br_if 0
  i32.const 0
  i32.const 1
  i32.sub
  return
  end
  local.get $l0
  call $f8
  i32.add
  local.get $l1
  i32.add
  local.set $l2
  call $f2
  local.get $l1
  i32.add
  local.get $l2
  i32.store8
  call $f7
  local.get $l1
  i32.const 1
  i32.add
  i32.store
  i32.const 0
  return
 )
 (func $f11 (param $l0 i32) (result i32)
  (local $l1 i32)
  (local $l2 i32)
  (local $l3 i32)
  (local $l4 i32)
  (local $l5 i32)
  local.get $l0
  local.set $l1
  local.get $l1
  local.get $l1
  i32.const 256
  i32.div_s
  i32.const 256
  i32.mul
  i32.sub
  local.set $l2
  local.get $l1
  i32.const 256
  i32.div_s
  local.set $l1
  local.get $l1
  local.get $l1
  i32.const 256
  i32.div_s
  i32.const 256
  i32.mul
  i32.sub
  local.set $l3
  local.get $l1
  i32.const 256
  i32.div_s
  local.set $l1
  local.get $l1
  local.get $l1
  i32.const 256
  i32.div_s
  i32.const 256
  i32.mul
  i32.sub
  local.set $l4
  local.get $l1
  i32.const 256
  i32.div_s
  local.set $l1
  local.get $l1
  local.get $l1
  i32.const 256
  i32.div_s
  i32.const 256
  i32.mul
  i32.sub
  local.set $l5
  local.get $l2
  call $f10
  drop
  local.get $l3
  call $f10
  drop
  local.get $l4
  call $f10
  drop
  local.get $l5
  call $f10
  drop
  i32.const 0
  return
 )
 (func $f12 (result i32)
  i32.const 18
  return
 )
 (func $f13 (result i32)
  i32.const 45
  return
 )
 (func $f14 (result i32)
  i32.const 56
  return
 )
 (func $f15 (result i32)
  i32.const 133
  return
 )
 (func $f16 (result i32)
  i32.const 144
  return
 )
 (func $f17 (result i32)
  i32.const 254
  return
 )
 (func $f18 (result i32)
  i32.const 239
  return
 )
 (func $f19 (param $l0 i32) (param $l1 i32) (param $l2 i32) (result i32)
  (local $l3 i32)
  (local $l4 i32)
  (local $l5 i32)
  (local $l6 i32)
  (local $l7 i32)
  (local $l8 i32)
  call $f6
  i32.const 0
  i32.store
  i32.const 3
  i32.const 0
  local.get $l0
  local.get $l1
  i32.const 9
  i32.const 64
  i64.extend_i32_u
  i32.const 0
  i64.extend_i32_u
  i32.const 0
  call $f6
  call $f1000007
  local.set $l3
  block
  local.get $l3
  i32.const 0
  i32.ne
  i32.const 0
  i32.eq
  br_if 0
  i32.const 0
  i32.const 30
  i32.sub
  return
  end
  call $f6
  i32.load
  local.set $l4
  i32.const 0
  local.set $l5
  block
  loop
  local.get $l5
  local.get $l2
  i32.lt_s
  i32.const 0
  i32.eq
  br_if 1
  local.get $l2
  local.get $l5
  i32.sub
  local.set $l6
  block
  local.get $l6
  i32.const 4096
  i32.gt_s
  i32.const 0
  i32.eq
  br_if 0
  i32.const 4096
  local.set $l6
  end
  call $f4
  call $f2
  local.get $l5
  i32.add
  i32.store
  call $f4
  i32.const 4
  i32.add
  local.get $l6
  i32.store
  call $f5
  i32.const 0
  i32.store
  local.get $l4
  call $f4
  i32.const 1
  call $f5
  call $f1000005
  local.set $l7
  block
  local.get $l7
  i32.const 0
  i32.ne
  i32.const 0
  i32.eq
  br_if 0
  local.get $l4
  call $f1000008
  drop
  i32.const 0
  i32.const 31
  i32.sub
  return
  end
  call $f5
  i32.load
  local.set $l8
  block
  local.get $l8
  i32.const 0
  i32.le_s
  i32.const 0
  i32.eq
  br_if 0
  local.get $l4
  call $f1000008
  drop
  i32.const 0
  i32.const 32
  i32.sub
  return
  end
  local.get $l5
  local.get $l8
  i32.add
  local.set $l5
  br 0
  end
  end
  local.get $l4
  call $f1000008
  drop
  i32.const 0
  return
 )
 (func $f20 (result i32)
  (local $l0 i32)
  call $f0
  i32.const 5000
  i32.add
  local.set $l0
  local.get $l0
  i32.const 0
  i32.add
  i32.const 111
  i32.store8
  local.get $l0
  i32.const 1
  i32.add
  i32.const 117
  i32.store8
  local.get $l0
  i32.const 2
  i32.add
  i32.const 116
  i32.store8
  local.get $l0
  i32.const 3
  i32.add
  i32.const 112
  i32.store8
  local.get $l0
  i32.const 4
  i32.add
  i32.const 117
  i32.store8
  local.get $l0
  i32.const 5
  i32.add
  i32.const 116
  i32.store8
  local.get $l0
  i32.const 6
  i32.add
  i32.const 46
  i32.store8
  local.get $l0
  i32.const 7
  i32.add
  i32.const 99
  i32.store8
  local.get $l0
  i32.const 8
  i32.add
  i32.const 98
  i32.store8
  local.get $l0
  i32.const 9
  i32.add
  i32.const 121
  i32.store8
  local.get $l0
  i32.const 10
  i32.add
  i32.const 116
  i32.store8
  local.get $l0
  i32.const 11
  i32.add
  i32.const 101
  i32.store8
  call $f2
  i32.const 0
  i32.add
  i32.const 67
  i32.store8
  call $f2
  i32.const 1
  i32.add
  i32.const 66
  i32.store8
  call $f2
  i32.const 2
  i32.add
  i32.const 89
  i32.store8
  call $f2
  i32.const 3
  i32.add
  i32.const 84
  i32.store8
  call $f7
  i32.const 4
  i32.store
  i32.const 1
  call $f10
  drop
  i32.const 9
  call $f11
  drop
  call $f12
  call $f10
  drop
  i32.const 72
  call $f11
  drop
  call $f16
  call $f10
  drop
  i32.const 0
  call $f11
  drop
  call $f15
  call $f10
  drop
  i32.const 0
  call $f11
  drop
  call $f12
  call $f10
  drop
  i32.const 1
  call $f11
  drop
  call $f13
  call $f10
  drop
  call $f17
  call $f10
  drop
  i32.const 1
  call $f11
  drop
  call $f12
  call $f10
  drop
  i32.const 10
  call $f11
  drop
  call $f17
  call $f10
  drop
  i32.const 1
  call $f11
  drop
  call $f18
  call $f10
  drop
  local.get $l0
  i32.const 12
  call $f9
  call $f19
  return
 )
 (export "main" (func $f20))
 (func $_start
  call $f20
  drop
 )
 (export "_start" (func $_start))
)
