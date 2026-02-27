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
  i32.const 80000000
  return
 )
 (func $f2 (result i32)
  i32.const 90000000
  return
 )
 (func $f3 (result i32)
  i32.const 95000000
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
  call $f0
  i32.const 8404
  i32.add
  return
 )
 (func $f9 (result i32)
  i32.const 172
  return
 )
 (func $f10 (result i32)
  (local $l0 i32)
  (local $l1 i32)
  (local $l2 i32)
  call $f7
  i32.load
  local.set $l0
  call $f1
  local.get $l0
  i32.add
  i32.load8_u
  local.set $l1
  local.get $l1
  call $f9
  i32.sub
  local.get $l0
  i32.sub
  local.set $l2
  block
  loop
  local.get $l2
  i32.const 0
  i32.lt_s
  i32.const 0
  i32.eq
  br_if 1
  local.get $l2
  i32.const 256
  i32.add
  local.set $l2
  br 0
  end
  end
  local.get $l2
  local.get $l2
  i32.const 256
  i32.div_s
  i32.const 256
  i32.mul
  i32.sub
  local.set $l2
  call $f7
  local.get $l0
  i32.const 1
  i32.add
  i32.store
  local.get $l2
  return
 )
 (func $f11 (result i32)
  (local $l0 i32)
  (local $l1 i32)
  (local $l2 i32)
  (local $l3 i32)
  call $f10
  local.set $l0
  call $f10
  local.set $l1
  call $f10
  local.set $l2
  call $f10
  local.set $l3
  local.get $l0
  local.get $l1
  i32.const 256
  i32.mul
  i32.add
  local.get $l2
  i32.const 65536
  i32.mul
  i32.add
  local.get $l3
  i32.const 16777216
  i32.mul
  i32.add
  return
 )
 (func $f12 (param $l0 i32) (result i32)
  (local $l1 i32)
  call $f8
  i32.load
  local.set $l1
  call $f2
  local.get $l1
  i32.const 4
  i32.mul
  i32.add
  local.get $l0
  i32.store
  call $f8
  local.get $l1
  i32.const 1
  i32.add
  i32.store
  i32.const 0
  return
 )
 (func $f13 (result i32)
  (local $l0 i32)
  call $f8
  i32.load
  i32.const 1
  i32.sub
  local.set $l0
  call $f8
  local.get $l0
  i32.store
  call $f2
  local.get $l0
  i32.const 4
  i32.mul
  i32.add
  i32.load
  return
 )
 (func $f14 (param $l0 i32) (param $l1 i32) (result i32)
  (local $l2 i32)
  (local $l3 i32)
  (local $l4 i32)
  (local $l5 i32)
  (local $l6 i32)
  (local $l7 i32)
  call $f6
  i32.const 0
  i32.store
  i32.const 3
  i32.const 0
  local.get $l0
  local.get $l1
  i32.const 0
  i32.const 1
  i64.extend_i32_u
  i32.const 0
  i64.extend_i32_u
  i32.const 0
  call $f6
  call $f1000007
  local.set $l2
  block
  local.get $l2
  i32.const 0
  i32.ne
  i32.const 0
  i32.eq
  br_if 0
  i32.const 0
  i32.const 1
  i32.sub
  return
  end
  call $f6
  i32.load
  local.set $l3
  i32.const 0
  local.set $l4
  i32.const 0
  local.set $l5
  block
  loop
  local.get $l5
  i32.const 0
  i32.eq
  i32.const 0
  i32.eq
  br_if 1
  call $f4
  call $f1
  local.get $l4
  i32.add
  i32.store
  call $f4
  i32.const 4
  i32.add
  i32.const 4096
  i32.store
  call $f5
  i32.const 0
  i32.store
  local.get $l3
  call $f4
  i32.const 1
  call $f5
  call $f1000006
  local.set $l6
  block
  local.get $l6
  i32.const 0
  i32.ne
  i32.const 0
  i32.eq
  br_if 0
  local.get $l3
  call $f1000008
  drop
  i32.const 0
  i32.const 2
  i32.sub
  return
  end
  call $f5
  i32.load
  local.set $l7
  block
  block
  local.get $l7
  i32.const 0
  i32.le_s
  i32.const 0
  i32.eq
  br_if 0
  i32.const 1
  local.set $l5
  br 1
  end
  local.get $l4
  local.get $l7
  i32.add
  local.set $l4
  end
  br 0
  end
  end
  local.get $l3
  call $f1000008
  drop
  local.get $l4
  return
 )
 (func $f15 (result i32)
  (local $l0 i32)
  (local $l1 i32)
  (local $l2 i32)
  (local $l3 i32)
  (local $l4 i32)
  (local $l5 i32)
  (local $l6 i32)
  (local $l7 i32)
  (local $l8 i32)
  (local $l9 i32)
  (local $l10 i32)
  (local $l11 i32)
  (local $l12 i32)
  (local $l13 i32)
  call $f0
  i32.const 5000
  i32.add
  local.set $l0
  local.get $l0
  i32.const 0
  i32.add
  i32.const 105
  i32.store8
  local.get $l0
  i32.const 1
  i32.add
  i32.const 110
  i32.store8
  local.get $l0
  i32.const 2
  i32.add
  i32.const 112
  i32.store8
  local.get $l0
  i32.const 3
  i32.add
  i32.const 117
  i32.store8
  local.get $l0
  i32.const 4
  i32.add
  i32.const 116
  i32.store8
  local.get $l0
  i32.const 5
  i32.add
  i32.const 46
  i32.store8
  local.get $l0
  i32.const 6
  i32.add
  i32.const 99
  i32.store8
  local.get $l0
  i32.const 7
  i32.add
  i32.const 98
  i32.store8
  local.get $l0
  i32.const 8
  i32.add
  i32.const 121
  i32.store8
  local.get $l0
  i32.const 9
  i32.add
  i32.const 116
  i32.store8
  local.get $l0
  i32.const 10
  i32.add
  i32.const 101
  i32.store8
  block
  local.get $l0
  i32.const 11
  call $f14
  i32.const 0
  i32.le_s
  i32.const 0
  i32.eq
  br_if 0
  i32.const 0
  i32.const 5
  i32.sub
  return
  end
  block
  call $f1
  i32.const 0
  i32.add
  i32.load8_u
  i32.const 67
  i32.ne
  i32.const 0
  i32.eq
  br_if 0
  i32.const 0
  i32.const 10
  i32.sub
  return
  end
  call $f7
  i32.const 5
  i32.store
  call $f11
  local.set $l1
  call $f7
  local.get $l1
  i32.store
  call $f8
  i32.const 0
  i32.store
  i32.const 1
  local.set $l2
  block
  loop
  local.get $l2
  i32.const 1
  i32.eq
  i32.const 0
  i32.eq
  br_if 1
  call $f10
  local.set $l3
  block
  block
  local.get $l3
  i32.const 18
  i32.eq
  i32.const 0
  i32.eq
  br_if 0
  call $f11
  call $f12
  drop
  br 1
  end
  block
  block
  local.get $l3
  i32.const 45
  i32.eq
  i32.const 0
  i32.eq
  br_if 0
  call $f13
  local.set $l4
  call $f13
  local.set $l5
  local.get $l5
  local.get $l4
  i32.add
  call $f12
  drop
  br 1
  end
  block
  block
  local.get $l3
  i32.const 56
  i32.eq
  i32.const 0
  i32.eq
  br_if 0
  call $f13
  local.set $l4
  call $f13
  local.set $l5
  local.get $l5
  local.get $l4
  i32.sub
  call $f12
  drop
  br 1
  end
  block
  block
  local.get $l3
  i32.const 133
  i32.eq
  i32.const 0
  i32.eq
  br_if 0
  call $f11
  local.set $l8
  call $f3
  local.get $l8
  i32.const 4
  i32.mul
  i32.add
  i32.load
  call $f12
  drop
  br 1
  end
  block
  block
  local.get $l3
  i32.const 144
  i32.eq
  i32.const 0
  i32.eq
  br_if 0
  call $f11
  local.set $l8
  call $f3
  local.get $l8
  i32.const 4
  i32.mul
  i32.add
  call $f13
  i32.store
  br 1
  end
  block
  block
  local.get $l3
  i32.const 111
  i32.eq
  i32.const 0
  i32.eq
  br_if 0
  call $f11
  local.set $l10
  call $f7
  call $f7
  i32.load
  local.get $l10
  i32.add
  i32.store
  br 1
  end
  block
  block
  local.get $l3
  i32.const 122
  i32.eq
  i32.const 0
  i32.eq
  br_if 0
  call $f11
  local.set $l10
  block
  call $f13
  i32.const 0
  i32.eq
  i32.const 0
  i32.eq
  br_if 0
  call $f7
  call $f7
  i32.load
  local.get $l10
  i32.add
  i32.store
  end
  br 1
  end
  block
  block
  local.get $l3
  i32.const 254
  i32.eq
  i32.const 0
  i32.eq
  br_if 0
  call $f11
  local.set $l12
  block
  local.get $l12
  i32.const 1
  i32.eq
  i32.const 0
  i32.eq
  br_if 0
  call $f13
  local.set $l13
  call $f0
  i32.const 1000
  i32.add
  local.get $l13
  i32.store8
  call $f4
  call $f0
  i32.const 1000
  i32.add
  i32.store
  call $f4
  i32.const 4
  i32.add
  i32.const 1
  i32.store
  call $f5
  i32.const 0
  i32.store
  i32.const 1
  call $f4
  i32.const 1
  call $f5
  call $f1000005
  drop
  end
  br 1
  end
  block
  block
  local.get $l3
  i32.const 239
  i32.eq
  i32.const 0
  i32.eq
  br_if 0
  i32.const 0
  local.set $l2
  br 1
  end
  i32.const 0
  local.set $l2
  end
  end
  end
  end
  end
  end
  end
  end
  end
  br 0
  end
  end
  i32.const 0
  return
 )
 (export "main" (func $f15))
 (func $_start
  call $f15
  drop
 )
 (export "_start" (func $_start))
)
