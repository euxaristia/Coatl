(module
 (import "wasi_snapshot_preview1" "fd_write" (func $f1000005 (param i32) (param i32) (param i32) (param i32) (result i32)))
 (import "wasi_snapshot_preview1" "fd_read" (func $f1000006 (param i32) (param i32) (param i32) (param i32) (result i32)))
 (import "wasi_snapshot_preview1" "path_open" (func $f1000007 (param i32) (param i32) (param i32) (param i32) (param i32) (param i64) (param i64) (param i32) (param i32) (result i32)))
 (import "wasi_snapshot_preview1" "fd_close" (func $f1000008 (param i32) (result i32)))
 (memory 2048)
 (export "memory" (memory 0))
 (data (i32.const 0) "          (binary or\0a")
 (data (i32.const 21) "          )\0a")
 (data (i32.const 33) "          (binary and\0a")
 (data (i32.const 55) "          )\0a")
 (data (i32.const 67) "          (binary ")
 (data (i32.const 85) "lt")
 (data (i32.const 87) "gt")
 (data (i32.const 89) "le")
 (data (i32.const 91) "ge")
 (data (i32.const 93) "eq")
 (data (i32.const 95) "ne")
 (data (i32.const 97) "\0a")
 (data (i32.const 98) "          )\0a")
 (data (i32.const 110) "          (binary add\0a")
 (data (i32.const 132) "          (binary sub\0a")
 (data (i32.const 154) "          )\0a")
 (data (i32.const 166) "          (binary mul\0a")
 (data (i32.const 188) "          (binary div\0a")
 (data (i32.const 210) "          )\0a")
 (data (i32.const 222) "          (binary eq\0a")
 (data (i32.const 243) "          (int 0)\0a")
 (data (i32.const 261) "          )\0a")
 (data (i32.const 273) "          (int_i64 ")
 (data (i32.const 292) ")\0a")
 (data (i32.const 294) "          (int ")
 (data (i32.const 309) ")\0a")
 (data (i32.const 311) "          (string_typed ")
 (data (i32.const 335) ")\0a")
 (data (i32.const 337) "          (bool 1)\0a")
 (data (i32.const 356) "          (bool 0)\0a")
 (data (i32.const 375) "          (struct_lit ")
 (data (i32.const 397) "          )\0a")
 (data (i32.const 409) "          (str_len\0a")
 (data (i32.const 428) "          )\0a")
 (data (i32.const 440) "          (str_ptr\0a")
 (data (i32.const 459) "          )\0a")
 (data (i32.const 471) "          (call ")
 (data (i32.const 487) "          )\0a")
 (data (i32.const 499) "          (field ")
 (data (i32.const 516) ")\0a")
 (data (i32.const 518) "          (ident ")
 (data (i32.const 535) ")\0a")
 (data (i32.const 537) "(coatl_ir v1\0a  (structs\0a")
 (data (i32.const 561) "  )\0a  (functions\0a")
 (data (i32.const 578) "  )\0a)\0a")
 (data (i32.const 584) "    (fn ")
 (data (i32.const 592) "      (params")
 (data (i32.const 605) "        (param ")
 (data (i32.const 620) "      )\0a")
 (data (i32.const 628) "      (ret ")
 (data (i32.const 639) ")\0a")
 (data (i32.const 641) "      (ret i32)\0a")
 (data (i32.const 657) "      (block\0a")
 (data (i32.const 670) "      )\0a    )\0a")
 (data (i32.const 684) "        (let ")
 (data (i32.const 697) "        )\0a")
 (data (i32.const 707) "        (return\0a")
 (data (i32.const 723) "        )\0a")
 (data (i32.const 733) "        (if\0a")
 (data (i32.const 745) "          (block\0a")
 (data (i32.const 762) "          )\0a")
 (data (i32.const 774) "          (else\0a")
 (data (i32.const 790) "            (block\0a")
 (data (i32.const 809) "            )\0a")
 (data (i32.const 823) "          )\0a")
 (data (i32.const 835) "        )\0a")
 (data (i32.const 845) "        (while\0a")
 (data (i32.const 860) "          (block\0a")
 (data (i32.const 877) "          )\0a        )\0a")
 (data (i32.const 899) "        (field_assign ")
 (data (i32.const 921) "        )\0a")
 (data (i32.const 931) "        (assign ")
 (data (i32.const 947) "        )\0a")
 (data (i32.const 957) "        (expr\0a")
 (data (i32.const 971) "        )\0a")
 (func $f0 (result i32)
  i32.const 1048576
  return
 )
 (func $f1 (result i32)
  i32.const 1048576
  return
 )
 (func $f2 (result i32)
  i32.const 2097152
  return
 )
 (func $f3 (result i32)
  i32.const 4194304
  return
 )
 (func $f4 (result i32)
  i32.const 16777216
  return
 )
 (func $f5 (result i32)
  i32.const 1048576
  return
 )
 (func $f6 (result i32)
  i32.const 33554432
  return
 )
 (func $f7 (result i32)
  call $f6
  return
 )
 (func $f8 (result i32)
  call $f6
  i32.const 8192
  i32.add
  return
 )
 (func $f9 (result i32)
  call $f6
  i32.const 8200
  i32.add
  return
 )
 (func $f10 (result i32)
  call $f6
  i32.const 8208
  i32.add
  return
 )
 (func $f11 (result i32)
  call $f6
  i32.const 8216
  i32.add
  return
 )
 (func $f12 (result i32)
  call $f6
  i32.const 8220
  i32.add
  return
 )
 (func $f13 (result i32)
  call $f6
  i32.const 8400
  i32.add
  return
 )
 (func $f14 (result i32)
  call $f6
  i32.const 8408
  i32.add
  return
 )
 (func $f15 (result i32)
  call $f6
  i32.const 8412
  i32.add
  return
 )
 (func $f16 (result i32)
  call $f6
  i32.const 8416
  i32.add
  return
 )
 (func $f17 (result i32)
  call $f6
  i32.const 8420
  i32.add
  return
 )
 (func $f18 (result i32)
  call $f6
  i32.const 10000
  i32.add
  return
 )
 (func $f19 (result i32)
  i32.const 1024
  return
 )
 (func $f20 (result i32)
  call $f6
  i32.const 8424
  i32.add
  return
 )
 (func $f21 (result i32)
  call $f6
  i32.const 8432
  i32.add
  return
 )
 (func $f22 (result i32)
  call $f6
  i32.const 30000
  i32.add
  return
 )
 (func $f23 (result i32)
  i32.const 40
  return
 )
 (func $f24 (param $l0 i32) (result i32)
  block
  local.get $l0
  i32.const 0
  i32.lt_s
  i32.const 0
  i32.ne
  local.get $l0
  call $f16
  i32.load
  i32.ge_s
  i32.const 0
  i32.ne
  i32.add
  i32.const 0
  i32.ne
  i32.const 0
  i32.eq
  br_if 0
  call $f32
  return
  end
  call $f4
  local.get $l0
  i32.const 16
  i32.mul
  i32.add
  i32.load
  return
 )
 (func $f25 (param $l0 i32) (result i32)
  block
  local.get $l0
  i32.const 0
  i32.lt_s
  i32.const 0
  i32.ne
  local.get $l0
  call $f16
  i32.load
  i32.ge_s
  i32.const 0
  i32.ne
  i32.add
  i32.const 0
  i32.ne
  i32.const 0
  i32.eq
  br_if 0
  i32.const 0
  return
  end
  call $f4
  local.get $l0
  i32.const 16
  i32.mul
  i32.add
  i32.const 4
  i32.add
  i32.load
  return
 )
 (func $f26 (param $l0 i32) (result i32)
  block
  local.get $l0
  i32.const 0
  i32.lt_s
  i32.const 0
  i32.ne
  local.get $l0
  call $f16
  i32.load
  i32.ge_s
  i32.const 0
  i32.ne
  i32.add
  i32.const 0
  i32.ne
  i32.const 0
  i32.eq
  br_if 0
  i32.const 0
  return
  end
  call $f4
  local.get $l0
  i32.const 16
  i32.mul
  i32.add
  i32.const 8
  i32.add
  i32.load
  return
 )
 (func $f27 (param $l0 i32) (param $l1 i32) (param $l2 i32) (result i32)
  (local $l3 i32)
  (local $l4 i32)
  call $f16
  i32.load
  local.set $l3
  block
  local.get $l3
  i32.const 10000
  i32.ge_s
  i32.const 0
  i32.eq
  br_if 0
  i32.const 0
  i32.const 1
  i32.sub
  return
  end
  call $f4
  local.get $l3
  i32.const 16
  i32.mul
  i32.add
  local.set $l4
  local.get $l4
  local.get $l0
  i32.store
  local.get $l4
  i32.const 4
  i32.add
  local.get $l1
  i32.store
  local.get $l4
  i32.const 8
  i32.add
  local.get $l2
  i32.store
  call $f16
  local.get $l3
  i32.const 1
  i32.add
  i32.store
  i32.const 0
  return
 )
 (func $f28 (result i32)
  i32.const 1
  return
 )
 (func $f29 (result i32)
  i32.const 2
  return
 )
 (func $f30 (result i32)
  i32.const 3
  return
 )
 (func $f31 (result i32)
  i32.const 4
  return
 )
 (func $f32 (result i32)
  i32.const 5
  return
 )
 (func $f33 (param $l0 i32) (result i32)
  block
  local.get $l0
  i32.const 65
  i32.ge_s
  i32.const 0
  i32.ne
  local.get $l0
  i32.const 90
  i32.le_s
  i32.const 0
  i32.ne
  i32.mul
  i32.const 0
  i32.eq
  br_if 0
  i32.const 1
  return
  end
  block
  local.get $l0
  i32.const 97
  i32.ge_s
  i32.const 0
  i32.ne
  local.get $l0
  i32.const 122
  i32.le_s
  i32.const 0
  i32.ne
  i32.mul
  i32.const 0
  i32.eq
  br_if 0
  i32.const 1
  return
  end
  block
  local.get $l0
  i32.const 95
  i32.eq
  i32.const 0
  i32.eq
  br_if 0
  i32.const 1
  return
  end
  i32.const 0
  return
 )
 (func $f34 (param $l0 i32) (result i32)
  block
  local.get $l0
  i32.const 48
  i32.ge_s
  i32.const 0
  i32.ne
  local.get $l0
  i32.const 57
  i32.le_s
  i32.const 0
  i32.ne
  i32.mul
  i32.const 0
  i32.eq
  br_if 0
  i32.const 1
  return
  end
  i32.const 0
  return
 )
 (func $f35 (param $l0 i32) (result i32)
  block
  local.get $l0
  call $f33
  i32.const 1
  i32.eq
  i32.const 0
  i32.ne
  local.get $l0
  call $f34
  i32.const 1
  i32.eq
  i32.const 0
  i32.ne
  i32.add
  i32.const 0
  i32.ne
  i32.const 0
  i32.eq
  br_if 0
  i32.const 1
  return
  end
  i32.const 0
  return
 )
 (func $f36 (param $l0 i32) (result i32)
  block
  local.get $l0
  i32.const 41
  i32.eq
  i32.const 0
  i32.ne
  local.get $l0
  i32.const 40
  i32.eq
  i32.const 0
  i32.ne
  i32.add
  i32.const 0
  i32.ne
  i32.const 0
  i32.eq
  br_if 0
  i32.const 1
  return
  end
  block
  local.get $l0
  i32.const 123
  i32.eq
  i32.const 0
  i32.ne
  local.get $l0
  i32.const 125
  i32.eq
  i32.const 0
  i32.ne
  i32.add
  i32.const 0
  i32.ne
  i32.const 0
  i32.eq
  br_if 0
  i32.const 1
  return
  end
  block
  local.get $l0
  i32.const 91
  i32.eq
  i32.const 0
  i32.ne
  local.get $l0
  i32.const 93
  i32.eq
  i32.const 0
  i32.ne
  i32.add
  i32.const 0
  i32.ne
  i32.const 0
  i32.eq
  br_if 0
  i32.const 1
  return
  end
  block
  local.get $l0
  i32.const 58
  i32.eq
  i32.const 0
  i32.ne
  local.get $l0
  i32.const 44
  i32.eq
  i32.const 0
  i32.ne
  i32.add
  i32.const 0
  i32.ne
  i32.const 0
  i32.eq
  br_if 0
  i32.const 1
  return
  end
  block
  local.get $l0
  i32.const 59
  i32.eq
  i32.const 0
  i32.ne
  local.get $l0
  i32.const 43
  i32.eq
  i32.const 0
  i32.ne
  i32.add
  i32.const 0
  i32.ne
  i32.const 0
  i32.eq
  br_if 0
  i32.const 1
  return
  end
  block
  local.get $l0
  i32.const 42
  i32.eq
  i32.const 0
  i32.ne
  local.get $l0
  i32.const 46
  i32.eq
  i32.const 0
  i32.ne
  i32.add
  i32.const 0
  i32.ne
  i32.const 0
  i32.eq
  br_if 0
  i32.const 1
  return
  end
  i32.const 0
  return
 )
 (func $f37 (result i32)
  (local $l0 i32)
  (local $l1 i32)
  (local $l2 i32)
  (local $l3 i32)
  (local $l4 i32)
  (local $l5 i32)
  call $f16
  i32.const 0
  i32.store
  i32.const 0
  local.set $l0
  call $f15
  i32.load
  local.set $l1
  block
  loop
  local.get $l0
  local.get $l1
  i32.lt_s
  i32.const 0
  i32.eq
  br_if 1
  call $f0
  local.get $l0
  i32.add
  i32.load8_u
  local.set $l2
  block
  block
  local.get $l2
  i32.const 32
  i32.le_s
  i32.const 0
  i32.eq
  br_if 0
  local.get $l0
  i32.const 1
  i32.add
  local.set $l0
  br 1
  end
  block
  block
  local.get $l2
  i32.const 47
  i32.eq
  i32.const 0
  i32.ne
  local.get $l0
  i32.const 1
  i32.add
  local.get $l1
  i32.lt_s
  i32.const 0
  i32.ne
  i32.mul
  i32.const 0
  i32.ne
  call $f0
  local.get $l0
  i32.add
  i32.const 1
  i32.add
  i32.load8_u
  i32.const 47
  i32.eq
  i32.const 0
  i32.ne
  i32.mul
  i32.const 0
  i32.eq
  br_if 0
  local.get $l0
  i32.const 2
  i32.add
  local.set $l0
  block
  loop
  local.get $l0
  local.get $l1
  i32.lt_s
  i32.const 0
  i32.ne
  call $f0
  local.get $l0
  i32.add
  i32.load8_u
  i32.const 10
  i32.ne
  i32.const 0
  i32.ne
  i32.mul
  i32.const 0
  i32.eq
  br_if 1
  local.get $l0
  i32.const 1
  i32.add
  local.set $l0
  br 0
  end
  end
  br 1
  end
  block
  block
  local.get $l2
  call $f36
  i32.const 1
  i32.eq
  i32.const 0
  i32.eq
  br_if 0
  block
  call $f31
  local.get $l0
  i32.const 1
  call $f27
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
  local.get $l0
  i32.const 1
  i32.add
  local.set $l0
  br 1
  end
  block
  block
  local.get $l2
  i32.const 33
  i32.eq
  i32.const 0
  i32.eq
  br_if 0
  block
  block
  local.get $l0
  i32.const 1
  i32.add
  local.get $l1
  i32.lt_s
  i32.const 0
  i32.ne
  call $f0
  local.get $l0
  i32.add
  i32.const 1
  i32.add
  i32.load8_u
  i32.const 61
  i32.eq
  i32.const 0
  i32.ne
  i32.mul
  i32.const 0
  i32.eq
  br_if 0
  block
  call $f31
  local.get $l0
  i32.const 2
  call $f27
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
  local.get $l0
  i32.const 2
  i32.add
  local.set $l0
  br 1
  end
  block
  call $f31
  local.get $l0
  i32.const 1
  call $f27
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
  local.get $l0
  i32.const 1
  i32.add
  local.set $l0
  end
  br 1
  end
  block
  block
  local.get $l2
  i32.const 45
  i32.eq
  i32.const 0
  i32.eq
  br_if 0
  block
  block
  local.get $l0
  i32.const 1
  i32.add
  local.get $l1
  i32.lt_s
  i32.const 0
  i32.ne
  call $f0
  local.get $l0
  i32.add
  i32.const 1
  i32.add
  i32.load8_u
  i32.const 62
  i32.eq
  i32.const 0
  i32.ne
  i32.mul
  i32.const 0
  i32.eq
  br_if 0
  block
  call $f31
  local.get $l0
  i32.const 2
  call $f27
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
  local.get $l0
  i32.const 2
  i32.add
  local.set $l0
  br 1
  end
  block
  call $f31
  local.get $l0
  i32.const 1
  call $f27
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
  local.get $l0
  i32.const 1
  i32.add
  local.set $l0
  end
  br 1
  end
  block
  block
  local.get $l2
  i32.const 61
  i32.eq
  i32.const 0
  i32.eq
  br_if 0
  block
  block
  local.get $l0
  i32.const 1
  i32.add
  local.get $l1
  i32.lt_s
  i32.const 0
  i32.ne
  call $f0
  local.get $l0
  i32.add
  i32.const 1
  i32.add
  i32.load8_u
  i32.const 61
  i32.eq
  i32.const 0
  i32.ne
  i32.mul
  i32.const 0
  i32.eq
  br_if 0
  block
  call $f31
  local.get $l0
  i32.const 2
  call $f27
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
  local.get $l0
  i32.const 2
  i32.add
  local.set $l0
  br 1
  end
  block
  call $f31
  local.get $l0
  i32.const 1
  call $f27
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
  local.get $l0
  i32.const 1
  i32.add
  local.set $l0
  end
  br 1
  end
  block
  block
  local.get $l2
  i32.const 60
  i32.eq
  i32.const 0
  i32.eq
  br_if 0
  block
  block
  local.get $l0
  i32.const 1
  i32.add
  local.get $l1
  i32.lt_s
  i32.const 0
  i32.ne
  call $f0
  local.get $l0
  i32.add
  i32.const 1
  i32.add
  i32.load8_u
  i32.const 61
  i32.eq
  i32.const 0
  i32.ne
  i32.mul
  i32.const 0
  i32.eq
  br_if 0
  block
  call $f31
  local.get $l0
  i32.const 2
  call $f27
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
  local.get $l0
  i32.const 2
  i32.add
  local.set $l0
  br 1
  end
  block
  call $f31
  local.get $l0
  i32.const 1
  call $f27
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
  local.get $l0
  i32.const 1
  i32.add
  local.set $l0
  end
  br 1
  end
  block
  block
  local.get $l2
  i32.const 62
  i32.eq
  i32.const 0
  i32.eq
  br_if 0
  block
  block
  local.get $l0
  i32.const 1
  i32.add
  local.get $l1
  i32.lt_s
  i32.const 0
  i32.ne
  call $f0
  local.get $l0
  i32.add
  i32.const 1
  i32.add
  i32.load8_u
  i32.const 61
  i32.eq
  i32.const 0
  i32.ne
  i32.mul
  i32.const 0
  i32.eq
  br_if 0
  block
  call $f31
  local.get $l0
  i32.const 2
  call $f27
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
  local.get $l0
  i32.const 2
  i32.add
  local.set $l0
  br 1
  end
  block
  call $f31
  local.get $l0
  i32.const 1
  call $f27
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
  local.get $l0
  i32.const 1
  i32.add
  local.set $l0
  end
  br 1
  end
  block
  block
  local.get $l2
  i32.const 38
  i32.eq
  i32.const 0
  i32.ne
  local.get $l0
  i32.const 1
  i32.add
  local.get $l1
  i32.lt_s
  i32.const 0
  i32.ne
  i32.mul
  i32.const 0
  i32.ne
  call $f0
  local.get $l0
  i32.add
  i32.const 1
  i32.add
  i32.load8_u
  i32.const 38
  i32.eq
  i32.const 0
  i32.ne
  i32.mul
  i32.const 0
  i32.eq
  br_if 0
  block
  call $f31
  local.get $l0
  i32.const 2
  call $f27
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
  local.get $l0
  i32.const 2
  i32.add
  local.set $l0
  br 1
  end
  block
  block
  local.get $l2
  i32.const 124
  i32.eq
  i32.const 0
  i32.ne
  local.get $l0
  i32.const 1
  i32.add
  local.get $l1
  i32.lt_s
  i32.const 0
  i32.ne
  i32.mul
  i32.const 0
  i32.ne
  call $f0
  local.get $l0
  i32.add
  i32.const 1
  i32.add
  i32.load8_u
  i32.const 124
  i32.eq
  i32.const 0
  i32.ne
  i32.mul
  i32.const 0
  i32.eq
  br_if 0
  block
  call $f31
  local.get $l0
  i32.const 2
  call $f27
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
  local.get $l0
  i32.const 2
  i32.add
  local.set $l0
  br 1
  end
  block
  block
  local.get $l2
  i32.const 47
  i32.eq
  i32.const 0
  i32.eq
  br_if 0
  block
  call $f31
  local.get $l0
  i32.const 1
  call $f27
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
  local.get $l0
  i32.const 1
  i32.add
  local.set $l0
  br 1
  end
  block
  block
  local.get $l2
  i32.const 34
  i32.eq
  i32.const 0
  i32.eq
  br_if 0
  local.get $l0
  local.set $l3
  local.get $l0
  i32.const 1
  i32.add
  local.set $l0
  block
  loop
  local.get $l0
  local.get $l1
  i32.lt_s
  i32.const 0
  i32.ne
  call $f0
  local.get $l0
  i32.add
  i32.load8_u
  i32.const 34
  i32.ne
  i32.const 0
  i32.ne
  i32.mul
  i32.const 0
  i32.eq
  br_if 1
  block
  block
  call $f0
  local.get $l0
  i32.add
  i32.load8_u
  i32.const 92
  i32.eq
  i32.const 0
  i32.eq
  br_if 0
  local.get $l0
  i32.const 2
  i32.add
  local.set $l0
  br 1
  end
  local.get $l0
  i32.const 1
  i32.add
  local.set $l0
  end
  br 0
  end
  end
  block
  local.get $l0
  local.get $l1
  i32.lt_s
  i32.const 0
  i32.eq
  br_if 0
  local.get $l0
  i32.const 1
  i32.add
  local.set $l0
  end
  block
  call $f30
  local.get $l3
  local.get $l0
  local.get $l3
  i32.sub
  call $f27
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
  br 1
  end
  block
  block
  local.get $l2
  call $f34
  i32.const 1
  i32.eq
  i32.const 0
  i32.eq
  br_if 0
  local.get $l0
  local.set $l3
  block
  loop
  local.get $l0
  local.get $l1
  i32.lt_s
  i32.const 0
  i32.ne
  call $f0
  local.get $l0
  i32.add
  i32.load8_u
  call $f34
  i32.const 1
  i32.eq
  i32.const 0
  i32.ne
  call $f0
  local.get $l0
  i32.add
  i32.load8_u
  i32.const 46
  i32.eq
  i32.const 0
  i32.ne
  i32.add
  i32.const 0
  i32.ne
  i32.const 0
  i32.ne
  i32.mul
  i32.const 0
  i32.eq
  br_if 1
  local.get $l0
  i32.const 1
  i32.add
  local.set $l0
  br 0
  end
  end
  block
  local.get $l0
  i32.const 2
  i32.add
  local.get $l1
  i32.lt_s
  i32.const 0
  i32.ne
  call $f0
  local.get $l0
  i32.add
  i32.load8_u
  i32.const 105
  i32.eq
  i32.const 0
  i32.ne
  i32.mul
  i32.const 0
  i32.ne
  call $f0
  local.get $l0
  i32.add
  i32.const 1
  i32.add
  i32.load8_u
  i32.const 54
  i32.eq
  i32.const 0
  i32.ne
  i32.mul
  i32.const 0
  i32.ne
  call $f0
  local.get $l0
  i32.add
  i32.const 2
  i32.add
  i32.load8_u
  i32.const 52
  i32.eq
  i32.const 0
  i32.ne
  i32.mul
  i32.const 0
  i32.eq
  br_if 0
  local.get $l0
  i32.const 3
  i32.add
  local.set $l0
  end
  block
  call $f29
  local.get $l3
  local.get $l0
  local.get $l3
  i32.sub
  call $f27
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
  br 1
  end
  block
  block
  local.get $l2
  call $f33
  i32.const 1
  i32.eq
  i32.const 0
  i32.eq
  br_if 0
  local.get $l0
  local.set $l3
  block
  loop
  local.get $l0
  local.get $l1
  i32.lt_s
  i32.const 0
  i32.ne
  call $f0
  local.get $l0
  i32.add
  i32.load8_u
  call $f35
  i32.const 1
  i32.eq
  i32.const 0
  i32.ne
  i32.mul
  i32.const 0
  i32.eq
  br_if 1
  local.get $l0
  i32.const 1
  i32.add
  local.set $l0
  br 0
  end
  end
  block
  call $f28
  local.get $l3
  local.get $l0
  local.get $l3
  i32.sub
  call $f27
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
  br 1
  end
  local.get $l0
  i32.const 1
  i32.add
  local.set $l0
  end
  end
  end
  end
  end
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
  call $f32
  local.get $l1
  i32.const 0
  call $f27
  drop
  i32.const 0
  return
 )
 (func $f38 (param $l0 i32) (result i32)
  (local $l1 i32)
  call $f13
  i32.load
  local.set $l1
  block
  local.get $l1
  i32.const 0
  i32.lt_s
  i32.const 0
  i32.ne
  local.get $l1
  call $f3
  i32.ge_s
  i32.const 0
  i32.ne
  i32.add
  i32.const 0
  i32.ne
  i32.const 0
  i32.eq
  br_if 0
  i32.const 0
  return
  end
  call $f2
  local.get $l1
  i32.add
  local.get $l0
  i32.store8
  call $f13
  local.get $l1
  i32.const 1
  i32.add
  i32.store
  i32.const 0
  return
 )
 (func $f39 (param $l0 i32) (param $l1 i32) (result i32)
  (local $l2 i32)
  block
  local.get $l0
  i32.const 0
  i32.eq
  i32.const 0
  i32.eq
  br_if 0
  i32.const 0
  return
  end
  i32.const 0
  local.set $l2
  block
  loop
  local.get $l2
  local.get $l1
  i32.lt_s
  i32.const 0
  i32.eq
  br_if 1
  local.get $l0
  local.get $l2
  i32.add
  i32.load8_u
  call $f38
  drop
  local.get $l2
  i32.const 1
  i32.add
  local.set $l2
  br 0
  end
  end
  i32.const 0
  return
 )
 (func $f40 (result i32)
  call $f13
  i32.load
  return
 )
 (func $f41 (param $l0 i32) (param $l1 i32) (result i32)
  (local $l2 i32)
  (local $l3 i32)
  call $f13
  i32.load
  local.set $l2
  block
  local.get $l2
  local.get $l1
  i32.add
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
  local.get $l2
  i32.const 1
  i32.sub
  local.set $l3
  block
  loop
  local.get $l3
  local.get $l0
  i32.ge_s
  i32.const 0
  i32.eq
  br_if 1
  call $f2
  local.get $l3
  i32.add
  local.get $l1
  i32.add
  call $f2
  local.get $l3
  i32.add
  i32.load8_u
  i32.store8
  local.get $l3
  i32.const 1
  i32.sub
  local.set $l3
  br 0
  end
  end
  call $f13
  local.get $l2
  local.get $l1
  i32.add
  i32.store
  i32.const 0
  return
 )
 (func $f42 (param $l0 i32) (param $l1 i32) (param $l2 i32) (result i32)
  (local $l3 i32)
  i32.const 0
  local.set $l3
  block
  loop
  local.get $l3
  local.get $l2
  i32.lt_s
  i32.const 0
  i32.eq
  br_if 1
  call $f2
  local.get $l0
  i32.add
  local.get $l3
  i32.add
  local.get $l1
  local.get $l3
  i32.add
  i32.load8_u
  i32.store8
  local.get $l3
  i32.const 1
  i32.add
  local.set $l3
  br 0
  end
  end
  i32.const 0
  return
 )
 (func $f43 (param $l0 i32) (result i32)
  (local $l1 i32)
  block
  local.get $l0
  i32.const 0
  i32.eq
  i32.const 0
  i32.eq
  br_if 0
  i32.const 48
  call $f38
  return
  end
  block
  local.get $l0
  i32.const 0
  i32.lt_s
  i32.const 0
  i32.eq
  br_if 0
  i32.const 45
  call $f38
  drop
  i32.const 0
  local.get $l0
  i32.sub
  call $f43
  return
  end
  i32.const 1000000000
  local.set $l1
  block
  loop
  local.get $l1
  local.get $l0
  i32.gt_s
  i32.const 0
  i32.eq
  br_if 1
  local.get $l1
  i32.const 10
  i32.div_s
  local.set $l1
  br 0
  end
  end
  block
  loop
  local.get $l1
  i32.const 0
  i32.gt_s
  i32.const 0
  i32.eq
  br_if 1
  i32.const 48
  local.get $l0
  local.get $l1
  i32.div_s
  i32.add
  call $f38
  drop
  local.get $l0
  local.get $l0
  local.get $l1
  i32.div_s
  local.get $l1
  i32.mul
  i32.sub
  local.set $l0
  local.get $l1
  i32.const 10
  i32.div_s
  local.set $l1
  br 0
  end
  end
  i32.const 0
  return
 )
 (func $f44 (result i32)
  i32.const 32
  call $f38
  return
 )
 (func $f45 (result i32)
  i32.const 10
  call $f38
  return
 )
 (func $f46 (result i32)
  call $f17
  i32.load
  call $f24
  return
 )
 (func $f47 (result i32)
  call $f17
  i32.load
  return
 )
 (func $f48 (param $l0 i32) (result i32)
  (local $l1 i32)
  call $f17
  i32.load
  local.get $l0
  i32.add
  local.set $l1
  block
  local.get $l1
  call $f16
  i32.load
  i32.ge_s
  i32.const 0
  i32.eq
  br_if 0
  call $f32
  return
  end
  local.get $l1
  call $f24
  return
 )
 (func $f49 (param $l0 i32) (result i32)
  call $f17
  i32.load
  local.get $l0
  i32.add
  return
 )
 (func $f50 (result i32)
  (local $l0 i32)
  call $f17
  i32.load
  local.set $l0
  call $f17
  local.get $l0
  i32.const 1
  i32.add
  i32.store
  local.get $l0
  return
 )
 (func $f51 (param $l0 i32) (param $l1 i32) (param $l2 i32) (result i32)
  (local $l3 i32)
  block
  local.get $l0
  i32.const 0
  i32.lt_s
  i32.const 0
  i32.ne
  local.get $l0
  call $f16
  i32.load
  i32.ge_s
  i32.const 0
  i32.ne
  i32.add
  i32.const 0
  i32.ne
  i32.const 0
  i32.eq
  br_if 0
  i32.const 0
  return
  end
  block
  local.get $l1
  i32.const 0
  i32.eq
  i32.const 0
  i32.eq
  br_if 0
  i32.const 0
  return
  end
  block
  local.get $l0
  call $f26
  local.get $l2
  i32.ne
  i32.const 0
  i32.eq
  br_if 0
  i32.const 0
  return
  end
  i32.const 0
  local.set $l3
  block
  loop
  local.get $l3
  local.get $l2
  i32.lt_s
  i32.const 0
  i32.eq
  br_if 1
  block
  call $f0
  local.get $l0
  call $f25
  i32.add
  local.get $l3
  i32.add
  i32.load8_u
  local.get $l1
  local.get $l3
  i32.add
  i32.load8_u
  i32.ne
  i32.const 0
  i32.eq
  br_if 0
  i32.const 0
  return
  end
  local.get $l3
  i32.const 1
  i32.add
  local.set $l3
  br 0
  end
  end
  i32.const 1
  return
 )
 (func $f52 (result i32)
  call $f6
  i32.const 16384
  i32.add
  return
 )
 (func $f53 (result i32)
  call $f52
  return
 )
 (func $f54 (result i32)
  call $f52
  i32.const 4
  i32.add
  return
 )
 (func $f55 (result i32)
  call $f52
  i32.const 8
  i32.add
  return
 )
 (func $f56 (result i32)
  call $f52
  i32.const 16
  i32.add
  return
 )
 (func $f57 (result i32)
  call $f52
  i32.const 100
  i32.add
  return
 )
 (func $f58 (result i32)
  call $f52
  i32.const 20
  i32.add
  return
 )
 (func $f59 (result i32)
  call $f52
  i32.const 28
  i32.add
  return
 )
 (func $f60 (result i32)
  call $f52
  i32.const 32
  i32.add
  return
 )
 (func $f61 (result i32)
  call $f52
  i32.const 36
  i32.add
  return
 )
 (func $f62 (result i32)
  call $f52
  i32.const 44
  i32.add
  return
 )
 (func $f63 (result i32)
  call $f52
  i32.const 52
  i32.add
  return
 )
 (func $f64 (result i32)
  call $f52
  i32.const 60
  i32.add
  return
 )
 (func $f65 (result i32)
  call $f52
  i32.const 68
  i32.add
  return
 )
 (func $f66 (result i32)
  call $f52
  i32.const 80
  i32.add
  return
 )
 (func $f67 (result i32)
  (local $l0 i32)
  call $f52
  local.set $l0
  local.get $l0
  i32.const 102
  i32.store8
  local.get $l0
  i32.const 1
  i32.add
  i32.const 110
  i32.store8
  local.get $l0
  i32.const 4
  i32.add
  i32.const 108
  i32.store8
  local.get $l0
  i32.const 5
  i32.add
  i32.const 101
  i32.store8
  local.get $l0
  i32.const 6
  i32.add
  i32.const 116
  i32.store8
  local.get $l0
  i32.const 8
  i32.add
  i32.const 114
  i32.store8
  local.get $l0
  i32.const 9
  i32.add
  i32.const 101
  i32.store8
  local.get $l0
  i32.const 10
  i32.add
  i32.const 116
  i32.store8
  local.get $l0
  i32.const 11
  i32.add
  i32.const 117
  i32.store8
  local.get $l0
  i32.const 12
  i32.add
  i32.const 114
  i32.store8
  local.get $l0
  i32.const 13
  i32.add
  i32.const 110
  i32.store8
  local.get $l0
  i32.const 16
  i32.add
  i32.const 105
  i32.store8
  local.get $l0
  i32.const 17
  i32.add
  i32.const 102
  i32.store8
  local.get $l0
  i32.const 100
  i32.add
  i32.const 101
  i32.store8
  local.get $l0
  i32.const 101
  i32.add
  i32.const 108
  i32.store8
  local.get $l0
  i32.const 102
  i32.add
  i32.const 115
  i32.store8
  local.get $l0
  i32.const 103
  i32.add
  i32.const 101
  i32.store8
  local.get $l0
  i32.const 20
  i32.add
  i32.const 119
  i32.store8
  local.get $l0
  i32.const 21
  i32.add
  i32.const 104
  i32.store8
  local.get $l0
  i32.const 22
  i32.add
  i32.const 105
  i32.store8
  local.get $l0
  i32.const 23
  i32.add
  i32.const 108
  i32.store8
  local.get $l0
  i32.const 24
  i32.add
  i32.const 101
  i32.store8
  local.get $l0
  i32.const 28
  i32.add
  i32.const 105
  i32.store8
  local.get $l0
  i32.const 29
  i32.add
  i32.const 51
  i32.store8
  local.get $l0
  i32.const 30
  i32.add
  i32.const 50
  i32.store8
  local.get $l0
  i32.const 32
  i32.add
  i32.const 105
  i32.store8
  local.get $l0
  i32.const 33
  i32.add
  i32.const 54
  i32.store8
  local.get $l0
  i32.const 34
  i32.add
  i32.const 52
  i32.store8
  local.get $l0
  i32.const 36
  i32.add
  i32.const 98
  i32.store8
  local.get $l0
  i32.const 37
  i32.add
  i32.const 111
  i32.store8
  local.get $l0
  i32.const 38
  i32.add
  i32.const 111
  i32.store8
  local.get $l0
  i32.const 39
  i32.add
  i32.const 108
  i32.store8
  local.get $l0
  i32.const 44
  i32.add
  i32.const 116
  i32.store8
  local.get $l0
  i32.const 45
  i32.add
  i32.const 114
  i32.store8
  local.get $l0
  i32.const 46
  i32.add
  i32.const 117
  i32.store8
  local.get $l0
  i32.const 47
  i32.add
  i32.const 101
  i32.store8
  local.get $l0
  i32.const 52
  i32.add
  i32.const 102
  i32.store8
  local.get $l0
  i32.const 53
  i32.add
  i32.const 97
  i32.store8
  local.get $l0
  i32.const 54
  i32.add
  i32.const 108
  i32.store8
  local.get $l0
  i32.const 55
  i32.add
  i32.const 115
  i32.store8
  local.get $l0
  i32.const 56
  i32.add
  i32.const 101
  i32.store8
  local.get $l0
  i32.const 60
  i32.add
  i32.const 115
  i32.store8
  local.get $l0
  i32.const 61
  i32.add
  i32.const 116
  i32.store8
  local.get $l0
  i32.const 62
  i32.add
  i32.const 114
  i32.store8
  local.get $l0
  i32.const 63
  i32.add
  i32.const 95
  i32.store8
  local.get $l0
  i32.const 64
  i32.add
  i32.const 108
  i32.store8
  local.get $l0
  i32.const 65
  i32.add
  i32.const 101
  i32.store8
  local.get $l0
  i32.const 66
  i32.add
  i32.const 110
  i32.store8
  local.get $l0
  i32.const 68
  i32.add
  i32.const 115
  i32.store8
  local.get $l0
  i32.const 69
  i32.add
  i32.const 116
  i32.store8
  local.get $l0
  i32.const 70
  i32.add
  i32.const 114
  i32.store8
  local.get $l0
  i32.const 71
  i32.add
  i32.const 95
  i32.store8
  local.get $l0
  i32.const 72
  i32.add
  i32.const 112
  i32.store8
  local.get $l0
  i32.const 73
  i32.add
  i32.const 116
  i32.store8
  local.get $l0
  i32.const 74
  i32.add
  i32.const 114
  i32.store8
  local.get $l0
  i32.const 80
  i32.add
  i32.const 115
  i32.store8
  local.get $l0
  i32.const 81
  i32.add
  i32.const 116
  i32.store8
  local.get $l0
  i32.const 82
  i32.add
  i32.const 114
  i32.store8
  local.get $l0
  i32.const 83
  i32.add
  i32.const 117
  i32.store8
  local.get $l0
  i32.const 84
  i32.add
  i32.const 99
  i32.store8
  local.get $l0
  i32.const 85
  i32.add
  i32.const 116
  i32.store8
  i32.const 0
  return
 )
 (func $f68 (param $l0 i32) (param $l1 i32) (result i32)
  (local $l2 i32)
  (local $l3 i32)
  call $f20
  i32.load
  local.set $l2
  block
  local.get $l2
  call $f19
  i32.ge_s
  i32.const 0
  i32.eq
  br_if 0
  i32.const 0
  i32.const 1
  i32.sub
  return
  end
  call $f18
  local.get $l2
  i32.const 8
  i32.mul
  i32.add
  local.set $l3
  local.get $l3
  local.get $l0
  i32.store
  local.get $l3
  i32.const 4
  i32.add
  local.get $l1
  i32.store
  call $f20
  local.get $l2
  i32.const 1
  i32.add
  i32.store
  i32.const 0
  return
 )
 (func $f69 (param $l0 i32) (result i32)
  (local $l1 i32)
  (local $l2 i32)
  (local $l3 i32)
  (local $l4 i32)
  block
  local.get $l0
  i32.const 0
  i32.eq
  i32.const 0
  i32.eq
  br_if 0
  i32.const 0
  return
  end
  call $f20
  i32.load
  local.set $l1
  local.get $l1
  i32.const 1
  i32.sub
  local.set $l2
  block
  loop
  local.get $l2
  i32.const 0
  i32.ge_s
  i32.const 0
  i32.eq
  br_if 1
  call $f18
  local.get $l2
  i32.const 8
  i32.mul
  i32.add
  local.set $l3
  local.get $l3
  i32.load
  local.set $l4
  block
  local.get $l4
  call $f26
  local.get $l0
  call $f26
  i32.eq
  i32.const 0
  i32.eq
  br_if 0
  block
  local.get $l4
  call $f0
  local.get $l0
  call $f25
  i32.add
  local.get $l0
  call $f26
  call $f51
  i32.const 1
  i32.eq
  i32.const 0
  i32.eq
  br_if 0
  local.get $l3
  i32.const 4
  i32.add
  i32.load
  return
  end
  end
  local.get $l2
  i32.const 1
  i32.sub
  local.set $l2
  br 0
  end
  end
  i32.const 0
  return
 )
 (func $f70 (param $l0 i32) (result i32)
  (local $l1 i32)
  (local $l2 i32)
  (local $l3 i32)
  (local $l4 i32)
  block
  local.get $l0
  i32.const 0
  i32.eq
  i32.const 0
  i32.eq
  br_if 0
  i32.const 0
  i32.const 1
  i32.sub
  return
  end
  call $f21
  i32.load
  local.set $l1
  i32.const 0
  local.set $l2
  block
  loop
  local.get $l2
  local.get $l1
  i32.lt_s
  i32.const 0
  i32.eq
  br_if 1
  call $f22
  local.get $l2
  call $f23
  i32.mul
  i32.add
  local.set $l3
  local.get $l3
  i32.load
  local.set $l4
  block
  local.get $l4
  i32.const 0
  i32.ne
  i32.const 0
  i32.eq
  br_if 0
  block
  local.get $l4
  call $f26
  local.get $l0
  call $f26
  i32.eq
  i32.const 0
  i32.eq
  br_if 0
  block
  local.get $l4
  call $f0
  local.get $l0
  call $f25
  i32.add
  local.get $l0
  call $f26
  call $f51
  i32.const 1
  i32.eq
  i32.const 0
  i32.eq
  br_if 0
  local.get $l2
  return
  end
  end
  end
  local.get $l2
  i32.const 1
  i32.add
  local.set $l2
  br 0
  end
  end
  i32.const 0
  i32.const 1
  i32.sub
  return
 )
 (func $f71 (result i32)
  (local $l0 i32)
  (local $l1 i32)
  (local $l2 i32)
  (local $l3 i32)
  (local $l4 i32)
  (local $l5 i32)
  (local $l6 i32)
  (local $l7 i32)
  call $f50
  drop
  call $f45
  drop
  i32.const 32
  call $f38
  drop
  i32.const 32
  call $f38
  drop
  i32.const 32
  call $f38
  drop
  i32.const 32
  call $f38
  drop
  i32.const 40
  call $f38
  drop
  i32.const 115
  call $f38
  drop
  i32.const 116
  call $f38
  drop
  i32.const 114
  call $f38
  drop
  i32.const 117
  call $f38
  drop
  i32.const 99
  call $f38
  drop
  i32.const 116
  call $f38
  drop
  i32.const 32
  call $f38
  drop
  call $f50
  local.set $l0
  call $f0
  local.get $l0
  call $f25
  i32.add
  local.get $l0
  call $f26
  call $f39
  drop
  call $f21
  i32.load
  local.set $l1
  block
  local.get $l1
  i32.const 32
  i32.ge_s
  i32.const 0
  i32.eq
  br_if 0
  i32.const 0
  i32.const 1
  i32.sub
  return
  end
  call $f22
  local.get $l1
  call $f23
  i32.mul
  i32.add
  local.set $l2
  local.get $l2
  local.get $l0
  i32.store
  block
  call $f46
  call $f31
  i32.eq
  i32.const 0
  i32.ne
  call $f0
  call $f47
  call $f25
  i32.add
  i32.load8_u
  i32.const 123
  i32.eq
  i32.const 0
  i32.ne
  i32.mul
  i32.const 0
  i32.eq
  br_if 0
  call $f50
  drop
  end
  i32.const 0
  local.set $l3
  block
  loop
  call $f46
  call $f32
  i32.ne
  i32.const 0
  i32.ne
  call $f46
  call $f31
  i32.ne
  i32.const 0
  i32.ne
  call $f0
  call $f47
  call $f25
  i32.add
  i32.load8_u
  i32.const 125
  i32.ne
  i32.const 0
  i32.ne
  i32.add
  i32.const 0
  i32.ne
  i32.const 0
  i32.ne
  i32.mul
  i32.const 0
  i32.eq
  br_if 1
  call $f17
  i32.load
  local.set $l4
  call $f50
  local.set $l5
  block
  call $f46
  call $f31
  i32.eq
  i32.const 0
  i32.ne
  call $f0
  call $f47
  call $f25
  i32.add
  i32.load8_u
  i32.const 58
  i32.eq
  i32.const 0
  i32.ne
  i32.mul
  i32.const 0
  i32.eq
  br_if 0
  call $f50
  drop
  end
  call $f50
  local.set $l6
  call $f45
  drop
  i32.const 32
  call $f38
  drop
  i32.const 32
  call $f38
  drop
  i32.const 32
  call $f38
  drop
  i32.const 32
  call $f38
  drop
  i32.const 32
  call $f38
  drop
  i32.const 32
  call $f38
  drop
  i32.const 40
  call $f38
  drop
  i32.const 102
  call $f38
  drop
  i32.const 105
  call $f38
  drop
  i32.const 101
  call $f38
  drop
  i32.const 108
  call $f38
  drop
  i32.const 100
  call $f38
  drop
  i32.const 32
  call $f38
  drop
  call $f0
  local.get $l5
  call $f25
  i32.add
  local.get $l5
  call $f26
  call $f39
  drop
  i32.const 32
  call $f38
  drop
  call $f0
  local.get $l6
  call $f25
  i32.add
  local.get $l6
  call $f26
  call $f39
  drop
  i32.const 41
  call $f38
  drop
  block
  local.get $l3
  i32.const 8
  i32.lt_s
  i32.const 0
  i32.eq
  br_if 0
  local.get $l2
  i32.const 8
  i32.add
  local.get $l3
  i32.const 4
  i32.mul
  i32.add
  local.get $l5
  i32.store
  local.get $l3
  i32.const 1
  i32.add
  local.set $l3
  end
  block
  call $f46
  call $f31
  i32.eq
  i32.const 0
  i32.ne
  call $f0
  call $f47
  call $f25
  i32.add
  i32.load8_u
  i32.const 44
  i32.eq
  i32.const 0
  i32.ne
  i32.mul
  i32.const 0
  i32.eq
  br_if 0
  call $f50
  drop
  end
  call $f17
  i32.load
  local.set $l7
  block
  local.get $l4
  local.get $l7
  i32.eq
  i32.const 0
  i32.eq
  br_if 0
  call $f50
  drop
  end
  br 0
  end
  end
  call $f45
  drop
  i32.const 32
  call $f38
  drop
  i32.const 32
  call $f38
  drop
  i32.const 32
  call $f38
  drop
  i32.const 32
  call $f38
  drop
  i32.const 41
  call $f38
  drop
  local.get $l2
  i32.const 4
  i32.add
  local.get $l3
  i32.store
  call $f21
  local.get $l1
  i32.const 1
  i32.add
  i32.store
  block
  call $f46
  call $f31
  i32.eq
  i32.const 0
  i32.ne
  call $f0
  call $f47
  call $f25
  i32.add
  i32.load8_u
  i32.const 125
  i32.eq
  i32.const 0
  i32.ne
  i32.mul
  i32.const 0
  i32.eq
  br_if 0
  call $f50
  drop
  end
  i32.const 0
  return
 )
 (func $f72 (result i32)
  i32.const 1
  return
 )
 (func $f73 (result i32)
  i32.const 2
  return
 )
 (func $f74 (result i32)
  i32.const 3
  return
 )
 (func $f75 (param $l0 i32) (result i32)
  block
  local.get $l0
  i32.const 0
  i32.eq
  i32.const 0
  i32.eq
  br_if 0
  call $f72
  return
  end
  block
  local.get $l0
  call $f60
  i32.const 3
  call $f51
  i32.const 1
  i32.eq
  i32.const 0
  i32.eq
  br_if 0
  call $f73
  return
  end
  block
  local.get $l0
  call $f61
  i32.const 4
  call $f51
  i32.const 1
  i32.eq
  i32.const 0
  i32.eq
  br_if 0
  call $f74
  return
  end
  block
  local.get $l0
  call $f70
  i32.const 0
  i32.ge_s
  i32.const 0
  i32.eq
  br_if 0
  i32.const 100
  local.get $l0
  call $f70
  i32.add
  return
  end
  call $f72
  return
 )
 (func $f76 (param $l0 i32) (result i32)
  (local $l1 i32)
  (local $l2 i32)
  (local $l3 i32)
  block
  local.get $l0
  call $f73
  i32.eq
  i32.const 0
  i32.eq
  br_if 0
  i32.const 32
  call $f38
  drop
  call $f60
  i32.const 3
  call $f39
  drop
  end
  block
  local.get $l0
  i32.const 100
  i32.ge_s
  i32.const 0
  i32.eq
  br_if 0
  local.get $l0
  i32.const 100
  i32.sub
  local.set $l1
  call $f22
  local.get $l1
  call $f23
  i32.mul
  i32.add
  local.set $l2
  local.get $l2
  i32.load
  local.set $l3
  i32.const 32
  call $f38
  drop
  call $f0
  local.get $l3
  call $f25
  i32.add
  local.get $l3
  call $f26
  call $f39
  drop
  end
  i32.const 0
  return
 )
 (func $f77 (result i32)
  call $f78
  return
 )
 (func $f78 (result i32)
  (local $l0 i32)
  (local $l1 i32)
  (local $l2 i32)
  (local $l3 i32)
  call $f40
  local.set $l0
  call $f79
  local.set $l1
  block
  loop
  call $f46
  call $f31
  i32.eq
  i32.const 0
  i32.ne
  call $f47
  call $f26
  i32.const 2
  i32.eq
  i32.const 0
  i32.ne
  i32.mul
  i32.const 0
  i32.ne
  call $f0
  call $f47
  call $f25
  i32.add
  i32.load8_u
  i32.const 124
  i32.eq
  i32.const 0
  i32.ne
  i32.mul
  i32.const 0
  i32.eq
  br_if 1
  call $f17
  i32.load
  local.set $l2
  call $f50
  drop
  local.get $l0
  i32.const 21
  call $f41
  drop
  local.get $l0
  i32.const 0
  i32.const 21
  call $f42
  drop
  call $f79
  drop
  i32.const 21
  i32.const 12
  call $f39
  drop
  call $f74
  local.set $l1
  call $f40
  local.set $l0
  call $f17
  i32.load
  local.set $l3
  block
  local.get $l2
  local.get $l3
  i32.eq
  i32.const 0
  i32.eq
  br_if 0
  call $f50
  drop
  end
  br 0
  end
  end
  local.get $l1
  return
 )
 (func $f79 (result i32)
  (local $l0 i32)
  (local $l1 i32)
  (local $l2 i32)
  (local $l3 i32)
  call $f40
  local.set $l0
  call $f80
  local.set $l1
  block
  loop
  call $f46
  call $f31
  i32.eq
  i32.const 0
  i32.ne
  call $f47
  call $f26
  i32.const 2
  i32.eq
  i32.const 0
  i32.ne
  i32.mul
  i32.const 0
  i32.ne
  call $f0
  call $f47
  call $f25
  i32.add
  i32.load8_u
  i32.const 38
  i32.eq
  i32.const 0
  i32.ne
  i32.mul
  i32.const 0
  i32.eq
  br_if 1
  call $f17
  i32.load
  local.set $l2
  call $f50
  drop
  local.get $l0
  i32.const 22
  call $f41
  drop
  local.get $l0
  i32.const 33
  i32.const 22
  call $f42
  drop
  call $f80
  drop
  i32.const 55
  i32.const 12
  call $f39
  drop
  call $f74
  local.set $l1
  call $f40
  local.set $l0
  call $f17
  i32.load
  local.set $l3
  block
  local.get $l2
  local.get $l3
  i32.eq
  i32.const 0
  i32.eq
  br_if 0
  call $f50
  drop
  end
  br 0
  end
  end
  local.get $l1
  return
 )
 (func $f80 (result i32)
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
  call $f40
  local.set $l0
  call $f81
  local.set $l1
  call $f46
  local.set $l2
  block
  local.get $l2
  call $f31
  i32.eq
  i32.const 0
  i32.eq
  br_if 0
  call $f47
  local.set $l3
  call $f0
  local.get $l3
  call $f25
  i32.add
  i32.load8_u
  local.set $l4
  local.get $l3
  call $f26
  local.set $l5
  block
  local.get $l5
  i32.const 1
  i32.eq
  i32.const 0
  i32.ne
  local.get $l4
  i32.const 60
  i32.eq
  i32.const 0
  i32.ne
  local.get $l4
  i32.const 62
  i32.eq
  i32.const 0
  i32.ne
  i32.add
  i32.const 0
  i32.ne
  i32.const 0
  i32.ne
  i32.mul
  i32.const 0
  i32.ne
  local.get $l5
  i32.const 2
  i32.eq
  i32.const 0
  i32.ne
  local.get $l4
  i32.const 60
  i32.eq
  i32.const 0
  i32.ne
  local.get $l4
  i32.const 62
  i32.eq
  i32.const 0
  i32.ne
  i32.add
  i32.const 0
  i32.ne
  i32.const 0
  i32.ne
  local.get $l4
  i32.const 61
  i32.eq
  i32.const 0
  i32.ne
  i32.add
  i32.const 0
  i32.ne
  i32.const 0
  i32.ne
  local.get $l4
  i32.const 33
  i32.eq
  i32.const 0
  i32.ne
  i32.add
  i32.const 0
  i32.ne
  i32.const 0
  i32.ne
  i32.mul
  i32.const 0
  i32.ne
  i32.add
  i32.const 0
  i32.ne
  i32.const 0
  i32.eq
  br_if 0
  call $f50
  drop
  i32.const 21
  local.set $l6
  block
  local.get $l0
  local.get $l6
  call $f41
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
  local.get $l0
  i32.const 67
  i32.const 18
  call $f42
  drop
  local.get $l0
  i32.const 18
  i32.add
  local.set $l7
  block
  block
  local.get $l5
  i32.const 1
  i32.eq
  i32.const 0
  i32.eq
  br_if 0
  block
  block
  local.get $l4
  i32.const 60
  i32.eq
  i32.const 0
  i32.eq
  br_if 0
  local.get $l7
  i32.const 85
  i32.const 2
  call $f42
  drop
  br 1
  end
  local.get $l7
  i32.const 87
  i32.const 2
  call $f42
  drop
  end
  br 1
  end
  block
  block
  local.get $l4
  i32.const 60
  i32.eq
  i32.const 0
  i32.eq
  br_if 0
  local.get $l7
  i32.const 89
  i32.const 2
  call $f42
  drop
  br 1
  end
  block
  block
  local.get $l4
  i32.const 62
  i32.eq
  i32.const 0
  i32.eq
  br_if 0
  local.get $l7
  i32.const 91
  i32.const 2
  call $f42
  drop
  br 1
  end
  block
  block
  local.get $l4
  i32.const 61
  i32.eq
  i32.const 0
  i32.eq
  br_if 0
  local.get $l7
  i32.const 93
  i32.const 2
  call $f42
  drop
  br 1
  end
  local.get $l7
  i32.const 95
  i32.const 2
  call $f42
  drop
  end
  end
  end
  end
  local.get $l0
  i32.const 20
  i32.add
  i32.const 97
  i32.const 1
  call $f42
  drop
  call $f81
  local.set $l8
  local.get $l1
  local.set $l9
  block
  local.get $l8
  local.get $l1
  i32.gt_s
  i32.const 0
  i32.eq
  br_if 0
  local.get $l8
  local.set $l9
  end
  local.get $l9
  call $f76
  drop
  call $f45
  drop
  i32.const 98
  i32.const 12
  call $f39
  drop
  call $f74
  return
  end
  end
  local.get $l1
  return
 )
 (func $f81 (result i32)
  (local $l0 i32)
  (local $l1 i32)
  (local $l2 i32)
  (local $l3 i32)
  (local $l4 i32)
  (local $l5 i32)
  (local $l6 i32)
  call $f40
  local.set $l0
  call $f82
  local.set $l1
  block
  loop
  call $f46
  call $f31
  i32.eq
  i32.const 0
  i32.ne
  call $f47
  call $f26
  i32.const 1
  i32.eq
  i32.const 0
  i32.ne
  i32.mul
  i32.const 0
  i32.ne
  call $f0
  call $f47
  call $f25
  i32.add
  i32.load8_u
  i32.const 43
  i32.eq
  i32.const 0
  i32.ne
  call $f0
  call $f47
  call $f25
  i32.add
  i32.load8_u
  i32.const 45
  i32.eq
  i32.const 0
  i32.ne
  i32.add
  i32.const 0
  i32.ne
  i32.const 0
  i32.ne
  i32.mul
  i32.const 0
  i32.eq
  br_if 1
  call $f17
  i32.load
  local.set $l2
  call $f0
  call $f50
  call $f25
  i32.add
  i32.load8_u
  local.set $l3
  block
  block
  local.get $l3
  i32.const 43
  i32.eq
  i32.const 0
  i32.eq
  br_if 0
  local.get $l0
  i32.const 22
  call $f41
  drop
  local.get $l0
  i32.const 110
  i32.const 22
  call $f42
  drop
  br 1
  end
  local.get $l0
  i32.const 22
  call $f41
  drop
  local.get $l0
  i32.const 132
  i32.const 22
  call $f42
  drop
  end
  call $f82
  local.set $l4
  local.get $l1
  local.set $l5
  block
  local.get $l4
  local.get $l1
  i32.gt_s
  i32.const 0
  i32.eq
  br_if 0
  local.get $l4
  local.set $l5
  end
  local.get $l5
  call $f76
  drop
  call $f45
  drop
  i32.const 154
  i32.const 12
  call $f39
  drop
  local.get $l5
  local.set $l1
  call $f40
  local.set $l0
  call $f17
  i32.load
  local.set $l6
  block
  local.get $l2
  local.get $l6
  i32.eq
  i32.const 0
  i32.eq
  br_if 0
  call $f50
  drop
  end
  br 0
  end
  end
  local.get $l1
  return
 )
 (func $f82 (result i32)
  (local $l0 i32)
  (local $l1 i32)
  (local $l2 i32)
  (local $l3 i32)
  (local $l4 i32)
  (local $l5 i32)
  (local $l6 i32)
  call $f40
  local.set $l0
  call $f83
  local.set $l1
  block
  loop
  call $f46
  call $f31
  i32.eq
  i32.const 0
  i32.ne
  call $f47
  call $f26
  i32.const 1
  i32.eq
  i32.const 0
  i32.ne
  i32.mul
  i32.const 0
  i32.ne
  call $f0
  call $f47
  call $f25
  i32.add
  i32.load8_u
  i32.const 42
  i32.eq
  i32.const 0
  i32.ne
  call $f0
  call $f47
  call $f25
  i32.add
  i32.load8_u
  i32.const 47
  i32.eq
  i32.const 0
  i32.ne
  i32.add
  i32.const 0
  i32.ne
  i32.const 0
  i32.ne
  i32.mul
  i32.const 0
  i32.eq
  br_if 1
  call $f17
  i32.load
  local.set $l2
  call $f0
  call $f50
  call $f25
  i32.add
  i32.load8_u
  local.set $l3
  block
  block
  local.get $l3
  i32.const 42
  i32.eq
  i32.const 0
  i32.eq
  br_if 0
  local.get $l0
  i32.const 22
  call $f41
  drop
  local.get $l0
  i32.const 166
  i32.const 22
  call $f42
  drop
  br 1
  end
  local.get $l0
  i32.const 22
  call $f41
  drop
  local.get $l0
  i32.const 188
  i32.const 22
  call $f42
  drop
  end
  call $f83
  local.set $l4
  local.get $l1
  local.set $l5
  block
  local.get $l4
  local.get $l1
  i32.gt_s
  i32.const 0
  i32.eq
  br_if 0
  local.get $l4
  local.set $l5
  end
  local.get $l5
  call $f76
  drop
  call $f45
  drop
  i32.const 210
  i32.const 12
  call $f39
  drop
  local.get $l5
  local.set $l1
  call $f40
  local.set $l0
  call $f17
  i32.load
  local.set $l6
  block
  local.get $l2
  local.get $l6
  i32.eq
  i32.const 0
  i32.eq
  br_if 0
  call $f50
  drop
  end
  br 0
  end
  end
  local.get $l1
  return
 )
 (func $f83 (result i32)
  (local $l0 i32)
  (local $l1 i32)
  (local $l2 i32)
  (local $l3 i32)
  (local $l4 i32)
  (local $l5 i32)
  (local $l6 i32)
  call $f47
  local.set $l0
  block
  call $f46
  call $f31
  i32.eq
  i32.const 0
  i32.ne
  call $f0
  local.get $l0
  call $f25
  i32.add
  i32.load8_u
  i32.const 33
  i32.eq
  i32.const 0
  i32.ne
  i32.mul
  i32.const 0
  i32.eq
  br_if 0
  call $f50
  drop
  i32.const 222
  i32.const 21
  call $f39
  drop
  call $f83
  local.set $l1
  i32.const 243
  i32.const 18
  call $f39
  drop
  i32.const 261
  i32.const 12
  call $f39
  drop
  call $f74
  return
  end
  block
  call $f46
  call $f31
  i32.eq
  i32.const 0
  i32.ne
  call $f0
  local.get $l0
  call $f25
  i32.add
  i32.load8_u
  i32.const 40
  i32.eq
  i32.const 0
  i32.ne
  i32.mul
  i32.const 0
  i32.eq
  br_if 0
  call $f50
  drop
  call $f77
  local.set $l1
  call $f50
  drop
  local.get $l1
  return
  end
  call $f50
  drop
  block
  local.get $l0
  call $f24
  call $f29
  i32.eq
  i32.const 0
  i32.eq
  br_if 0
  local.get $l0
  call $f26
  local.set $l3
  local.get $l0
  call $f25
  local.set $l4
  block
  local.get $l3
  i32.const 3
  i32.gt_s
  i32.const 0
  i32.ne
  call $f0
  local.get $l4
  i32.add
  local.get $l3
  i32.add
  i32.const 3
  i32.sub
  i32.load8_u
  i32.const 105
  i32.eq
  i32.const 0
  i32.ne
  i32.mul
  i32.const 0
  i32.ne
  call $f0
  local.get $l4
  i32.add
  local.get $l3
  i32.add
  i32.const 2
  i32.sub
  i32.load8_u
  i32.const 54
  i32.eq
  i32.const 0
  i32.ne
  i32.mul
  i32.const 0
  i32.ne
  call $f0
  local.get $l4
  i32.add
  local.get $l3
  i32.add
  i32.const 1
  i32.sub
  i32.load8_u
  i32.const 52
  i32.eq
  i32.const 0
  i32.ne
  i32.mul
  i32.const 0
  i32.eq
  br_if 0
  i32.const 273
  i32.const 19
  call $f39
  drop
  call $f0
  local.get $l4
  i32.add
  local.get $l3
  i32.const 3
  i32.sub
  call $f39
  drop
  i32.const 292
  i32.const 2
  call $f39
  drop
  call $f73
  return
  end
  i32.const 294
  i32.const 15
  call $f39
  drop
  call $f0
  local.get $l4
  i32.add
  local.get $l3
  call $f39
  drop
  i32.const 309
  i32.const 2
  call $f39
  drop
  call $f72
  return
  end
  block
  local.get $l0
  call $f24
  call $f30
  i32.eq
  i32.const 0
  i32.eq
  br_if 0
  i32.const 311
  i32.const 24
  call $f39
  drop
  call $f0
  local.get $l0
  call $f25
  i32.add
  local.get $l0
  call $f26
  call $f39
  drop
  i32.const 335
  i32.const 2
  call $f39
  drop
  call $f72
  return
  end
  block
  local.get $l0
  call $f24
  call $f28
  i32.eq
  i32.const 0
  i32.eq
  br_if 0
  block
  local.get $l0
  call $f62
  i32.const 4
  call $f51
  i32.const 1
  i32.eq
  i32.const 0
  i32.eq
  br_if 0
  i32.const 337
  i32.const 19
  call $f39
  drop
  call $f74
  return
  end
  block
  local.get $l0
  call $f63
  i32.const 5
  call $f51
  i32.const 1
  i32.eq
  i32.const 0
  i32.eq
  br_if 0
  i32.const 356
  i32.const 19
  call $f39
  drop
  call $f74
  return
  end
  local.get $l0
  call $f70
  local.set $l5
  block
  local.get $l5
  i32.const 0
  i32.ge_s
  i32.const 0
  i32.ne
  call $f46
  call $f31
  i32.eq
  i32.const 0
  i32.ne
  i32.mul
  i32.const 0
  i32.ne
  call $f0
  call $f47
  call $f25
  i32.add
  i32.load8_u
  i32.const 123
  i32.eq
  i32.const 0
  i32.ne
  i32.mul
  i32.const 0
  i32.eq
  br_if 0
  call $f50
  drop
  i32.const 375
  i32.const 22
  call $f39
  drop
  call $f0
  local.get $l0
  call $f25
  i32.add
  local.get $l0
  call $f26
  call $f39
  drop
  call $f45
  drop
  block
  loop
  call $f46
  call $f31
  i32.ne
  i32.const 0
  i32.ne
  call $f0
  call $f47
  call $f25
  i32.add
  i32.load8_u
  i32.const 125
  i32.ne
  i32.const 0
  i32.ne
  i32.add
  i32.const 0
  i32.ne
  i32.const 0
  i32.eq
  br_if 1
  call $f50
  drop
  call $f50
  drop
  call $f77
  drop
  block
  call $f46
  call $f31
  i32.eq
  i32.const 0
  i32.ne
  call $f0
  call $f47
  call $f25
  i32.add
  i32.load8_u
  i32.const 44
  i32.eq
  i32.const 0
  i32.ne
  i32.mul
  i32.const 0
  i32.eq
  br_if 0
  call $f50
  drop
  end
  br 0
  end
  end
  call $f50
  drop
  i32.const 397
  i32.const 12
  call $f39
  drop
  i32.const 100
  local.get $l5
  i32.add
  return
  end
  block
  call $f46
  call $f31
  i32.eq
  i32.const 0
  i32.ne
  call $f0
  call $f47
  call $f25
  i32.add
  i32.load8_u
  i32.const 40
  i32.eq
  i32.const 0
  i32.ne
  i32.mul
  i32.const 0
  i32.eq
  br_if 0
  call $f50
  drop
  block
  local.get $l0
  call $f64
  i32.const 7
  call $f51
  i32.const 1
  i32.eq
  i32.const 0
  i32.eq
  br_if 0
  i32.const 409
  i32.const 19
  call $f39
  drop
  call $f77
  drop
  call $f50
  drop
  i32.const 428
  i32.const 12
  call $f39
  drop
  call $f72
  return
  end
  block
  local.get $l0
  call $f65
  i32.const 7
  call $f51
  i32.const 1
  i32.eq
  i32.const 0
  i32.eq
  br_if 0
  i32.const 440
  i32.const 19
  call $f39
  drop
  call $f77
  drop
  call $f50
  drop
  i32.const 459
  i32.const 12
  call $f39
  drop
  call $f72
  return
  end
  i32.const 471
  i32.const 16
  call $f39
  drop
  call $f0
  local.get $l0
  call $f25
  i32.add
  local.get $l0
  call $f26
  call $f39
  drop
  call $f45
  drop
  block
  loop
  call $f46
  call $f31
  i32.ne
  i32.const 0
  i32.ne
  call $f0
  call $f47
  call $f25
  i32.add
  i32.load8_u
  i32.const 41
  i32.ne
  i32.const 0
  i32.ne
  i32.add
  i32.const 0
  i32.ne
  i32.const 0
  i32.eq
  br_if 1
  call $f77
  drop
  block
  call $f46
  call $f31
  i32.eq
  i32.const 0
  i32.ne
  call $f0
  call $f47
  call $f25
  i32.add
  i32.load8_u
  i32.const 44
  i32.eq
  i32.const 0
  i32.ne
  i32.mul
  i32.const 0
  i32.eq
  br_if 0
  call $f50
  drop
  end
  br 0
  end
  end
  call $f50
  drop
  i32.const 487
  i32.const 12
  call $f39
  drop
  call $f72
  return
  end
  block
  call $f46
  call $f31
  i32.eq
  i32.const 0
  i32.ne
  call $f0
  call $f47
  call $f25
  i32.add
  i32.load8_u
  i32.const 46
  i32.eq
  i32.const 0
  i32.ne
  i32.mul
  i32.const 0
  i32.eq
  br_if 0
  call $f50
  drop
  call $f50
  local.set $l6
  i32.const 499
  i32.const 17
  call $f39
  drop
  call $f0
  local.get $l0
  call $f25
  i32.add
  local.get $l0
  call $f26
  call $f39
  drop
  call $f44
  drop
  call $f0
  local.get $l6
  call $f25
  i32.add
  local.get $l6
  call $f26
  call $f39
  drop
  i32.const 516
  i32.const 2
  call $f39
  drop
  call $f72
  return
  end
  i32.const 518
  i32.const 17
  call $f39
  drop
  call $f0
  local.get $l0
  call $f25
  i32.add
  local.get $l0
  call $f26
  call $f39
  drop
  i32.const 535
  i32.const 2
  call $f39
  drop
  local.get $l0
  call $f69
  call $f75
  return
  end
  call $f72
  return
 )
 (func $f84 (result i32)
  (local $l0 i32)
  call $f21
  i32.const 0
  i32.store
  i32.const 537
  i32.const 24
  call $f39
  drop
  call $f17
  i32.load
  local.set $l0
  block
  loop
  call $f46
  call $f32
  i32.ne
  i32.const 0
  i32.eq
  br_if 1
  block
  block
  call $f47
  call $f66
  i32.const 6
  call $f51
  i32.const 1
  i32.eq
  i32.const 0
  i32.eq
  br_if 0
  call $f71
  drop
  br 1
  end
  call $f50
  drop
  end
  br 0
  end
  end
  i32.const 561
  i32.const 17
  call $f39
  drop
  call $f17
  local.get $l0
  i32.store
  block
  loop
  call $f46
  call $f32
  i32.ne
  i32.const 0
  i32.eq
  br_if 1
  block
  block
  call $f47
  call $f53
  i32.const 2
  call $f51
  i32.const 1
  i32.eq
  i32.const 0
  i32.eq
  br_if 0
  call $f86
  drop
  br 1
  end
  call $f50
  drop
  end
  br 0
  end
  end
  i32.const 578
  i32.const 6
  call $f39
  drop
  i32.const 0
  return
 )
 (func $f85 (result i32)
  block
  call $f46
  call $f32
  i32.eq
  i32.const 0
  i32.eq
  br_if 0
  i32.const 1
  return
  end
  block
  call $f46
  call $f31
  i32.ne
  i32.const 0
  i32.eq
  br_if 0
  i32.const 0
  return
  end
  block
  call $f0
  call $f47
  call $f25
  i32.add
  i32.load8_u
  i32.const 41
  i32.eq
  i32.const 0
  i32.eq
  br_if 0
  i32.const 1
  return
  end
  i32.const 0
  return
 )
 (func $f86 (result i32)
  (local $l0 i32)
  (local $l1 i32)
  (local $l2 i32)
  (local $l3 i32)
  (local $l4 i32)
  (local $l5 i32)
  call $f50
  drop
  call $f50
  local.set $l0
  call $f20
  i32.const 0
  i32.store
  i32.const 584
  i32.const 8
  call $f39
  drop
  call $f0
  local.get $l0
  call $f25
  i32.add
  local.get $l0
  call $f26
  call $f39
  drop
  call $f45
  drop
  call $f50
  drop
  i32.const 592
  i32.const 13
  call $f39
  drop
  block
  loop
  call $f85
  i32.const 0
  i32.eq
  i32.const 0
  i32.eq
  br_if 1
  call $f17
  i32.load
  local.set $l1
  call $f50
  local.set $l2
  block
  call $f46
  call $f31
  i32.eq
  i32.const 0
  i32.ne
  call $f0
  call $f47
  call $f25
  i32.add
  i32.load8_u
  i32.const 58
  i32.eq
  i32.const 0
  i32.ne
  i32.mul
  i32.const 0
  i32.eq
  br_if 0
  call $f50
  drop
  end
  call $f50
  local.set $l3
  local.get $l2
  local.get $l3
  call $f68
  drop
  call $f45
  drop
  i32.const 605
  i32.const 15
  call $f39
  drop
  call $f0
  local.get $l2
  call $f25
  i32.add
  local.get $l2
  call $f26
  call $f39
  drop
  call $f44
  drop
  call $f0
  local.get $l3
  call $f25
  i32.add
  local.get $l3
  call $f26
  call $f39
  drop
  i32.const 41
  call $f38
  drop
  block
  call $f46
  call $f31
  i32.eq
  i32.const 0
  i32.ne
  call $f0
  call $f47
  call $f25
  i32.add
  i32.load8_u
  i32.const 44
  i32.eq
  i32.const 0
  i32.ne
  i32.mul
  i32.const 0
  i32.eq
  br_if 0
  call $f50
  drop
  end
  call $f17
  i32.load
  local.set $l4
  block
  local.get $l1
  local.get $l4
  i32.eq
  i32.const 0
  i32.eq
  br_if 0
  call $f50
  drop
  end
  br 0
  end
  end
  block
  call $f46
  call $f31
  i32.eq
  i32.const 0
  i32.ne
  call $f0
  call $f47
  call $f25
  i32.add
  i32.load8_u
  i32.const 41
  i32.eq
  i32.const 0
  i32.ne
  i32.mul
  i32.const 0
  i32.eq
  br_if 0
  call $f50
  drop
  end
  call $f45
  drop
  i32.const 620
  i32.const 8
  call $f39
  drop
  block
  block
  call $f46
  call $f31
  i32.eq
  i32.const 0
  i32.ne
  call $f0
  call $f47
  call $f25
  i32.add
  i32.load8_u
  i32.const 45
  i32.eq
  i32.const 0
  i32.ne
  i32.mul
  i32.const 0
  i32.eq
  br_if 0
  call $f50
  drop
  call $f50
  local.set $l5
  i32.const 628
  i32.const 11
  call $f39
  drop
  call $f0
  local.get $l5
  call $f25
  i32.add
  local.get $l5
  call $f26
  call $f39
  drop
  i32.const 639
  i32.const 2
  call $f39
  drop
  br 1
  end
  i32.const 641
  i32.const 16
  call $f39
  drop
  end
  block
  call $f46
  call $f31
  i32.eq
  i32.const 0
  i32.ne
  call $f0
  call $f47
  call $f25
  i32.add
  i32.load8_u
  i32.const 123
  i32.eq
  i32.const 0
  i32.ne
  i32.mul
  i32.const 0
  i32.eq
  br_if 0
  call $f50
  drop
  end
  i32.const 657
  i32.const 13
  call $f39
  drop
  call $f87
  drop
  block
  call $f46
  call $f31
  i32.eq
  i32.const 0
  i32.ne
  call $f0
  call $f47
  call $f25
  i32.add
  i32.load8_u
  i32.const 125
  i32.eq
  i32.const 0
  i32.ne
  i32.mul
  i32.const 0
  i32.eq
  br_if 0
  call $f50
  drop
  end
  i32.const 670
  i32.const 14
  call $f39
  drop
  i32.const 0
  return
 )
 (func $f87 (result i32)
  block
  loop
  call $f46
  call $f32
  i32.ne
  i32.const 0
  i32.ne
  call $f46
  call $f31
  i32.ne
  i32.const 0
  i32.ne
  call $f0
  call $f47
  call $f25
  i32.add
  i32.load8_u
  i32.const 125
  i32.ne
  i32.const 0
  i32.ne
  i32.add
  i32.const 0
  i32.ne
  i32.const 0
  i32.ne
  i32.mul
  i32.const 0
  i32.eq
  br_if 1
  call $f89
  drop
  br 0
  end
  end
  i32.const 0
  return
 )
 (func $f88 (param $l0 i32) (param $l1 i32) (result i32)
  (local $l2 i32)
  (local $l3 i32)
  (local $l4 i32)
  (local $l5 i32)
  call $f22
  local.get $l0
  call $f23
  i32.mul
  i32.add
  local.set $l2
  local.get $l2
  i32.const 4
  i32.add
  i32.load
  local.set $l3
  i32.const 0
  local.set $l4
  block
  loop
  local.get $l4
  local.get $l3
  i32.lt_s
  i32.const 0
  i32.eq
  br_if 1
  local.get $l2
  i32.const 8
  i32.add
  local.get $l4
  i32.const 4
  i32.mul
  i32.add
  i32.load
  local.set $l5
  block
  local.get $l5
  call $f26
  local.get $l1
  call $f26
  i32.eq
  i32.const 0
  i32.eq
  br_if 0
  block
  local.get $l5
  call $f0
  local.get $l1
  call $f25
  i32.add
  local.get $l1
  call $f26
  call $f51
  i32.const 1
  i32.eq
  i32.const 0
  i32.eq
  br_if 0
  local.get $l4
  return
  end
  end
  local.get $l4
  i32.const 1
  i32.add
  local.set $l4
  br 0
  end
  end
  i32.const 0
  i32.const 1
  i32.sub
  return
 )
 (func $f89 (result i32)
  (local $l0 i32)
  (local $l1 i32)
  (local $l2 i32)
  (local $l3 i32)
  (local $l4 i32)
  (local $l5 i32)
  (local $l6 i32)
  call $f47
  local.set $l0
  block
  block
  local.get $l0
  call $f54
  i32.const 3
  call $f51
  i32.const 1
  i32.eq
  i32.const 0
  i32.eq
  br_if 0
  call $f50
  drop
  call $f50
  local.set $l1
  call $f50
  drop
  call $f50
  local.set $l2
  call $f50
  drop
  local.get $l1
  local.get $l2
  call $f68
  drop
  i32.const 684
  i32.const 13
  call $f39
  drop
  call $f0
  local.get $l1
  call $f25
  i32.add
  local.get $l1
  call $f26
  call $f39
  drop
  call $f44
  drop
  call $f0
  local.get $l2
  call $f25
  i32.add
  local.get $l2
  call $f26
  call $f39
  drop
  call $f45
  drop
  call $f77
  drop
  i32.const 697
  i32.const 10
  call $f39
  drop
  block
  call $f46
  call $f31
  i32.eq
  i32.const 0
  i32.ne
  call $f0
  call $f47
  call $f25
  i32.add
  i32.load8_u
  i32.const 59
  i32.eq
  i32.const 0
  i32.ne
  i32.mul
  i32.const 0
  i32.eq
  br_if 0
  call $f50
  drop
  end
  br 1
  end
  block
  block
  local.get $l0
  call $f55
  i32.const 6
  call $f51
  i32.const 1
  i32.eq
  i32.const 0
  i32.eq
  br_if 0
  call $f50
  drop
  i32.const 707
  i32.const 16
  call $f39
  drop
  call $f77
  drop
  i32.const 723
  i32.const 10
  call $f39
  drop
  block
  call $f46
  call $f31
  i32.eq
  i32.const 0
  i32.ne
  call $f0
  call $f47
  call $f25
  i32.add
  i32.load8_u
  i32.const 59
  i32.eq
  i32.const 0
  i32.ne
  i32.mul
  i32.const 0
  i32.eq
  br_if 0
  call $f50
  drop
  end
  br 1
  end
  block
  block
  local.get $l0
  call $f56
  i32.const 2
  call $f51
  i32.const 1
  i32.eq
  i32.const 0
  i32.eq
  br_if 0
  call $f50
  drop
  call $f50
  drop
  i32.const 733
  i32.const 12
  call $f39
  drop
  call $f77
  drop
  call $f50
  drop
  call $f50
  drop
  i32.const 745
  i32.const 17
  call $f39
  drop
  call $f87
  drop
  call $f50
  drop
  i32.const 762
  i32.const 12
  call $f39
  drop
  block
  call $f47
  call $f57
  i32.const 4
  call $f51
  i32.const 1
  i32.eq
  i32.const 0
  i32.eq
  br_if 0
  call $f50
  drop
  call $f50
  drop
  i32.const 774
  i32.const 16
  call $f39
  drop
  i32.const 790
  i32.const 19
  call $f39
  drop
  call $f87
  drop
  call $f50
  drop
  i32.const 809
  i32.const 14
  call $f39
  drop
  i32.const 823
  i32.const 12
  call $f39
  drop
  end
  i32.const 835
  i32.const 10
  call $f39
  drop
  br 1
  end
  block
  block
  local.get $l0
  call $f58
  i32.const 5
  call $f51
  i32.const 1
  i32.eq
  i32.const 0
  i32.eq
  br_if 0
  call $f50
  drop
  call $f50
  drop
  i32.const 845
  i32.const 15
  call $f39
  drop
  call $f77
  drop
  call $f50
  drop
  call $f50
  drop
  i32.const 860
  i32.const 17
  call $f39
  drop
  call $f87
  drop
  call $f50
  drop
  i32.const 877
  i32.const 22
  call $f39
  drop
  br 1
  end
  block
  block
  local.get $l0
  call $f24
  call $f28
  i32.eq
  i32.const 0
  i32.ne
  i32.const 1
  call $f48
  call $f31
  i32.eq
  i32.const 0
  i32.ne
  i32.mul
  i32.const 0
  i32.ne
  call $f0
  i32.const 1
  call $f49
  call $f25
  i32.add
  i32.load8_u
  i32.const 46
  i32.eq
  i32.const 0
  i32.ne
  i32.mul
  i32.const 0
  i32.eq
  br_if 0
  call $f50
  local.set $l3
  call $f50
  drop
  call $f50
  local.set $l4
  call $f50
  drop
  i32.const 899
  i32.const 22
  call $f39
  drop
  call $f0
  local.get $l3
  call $f25
  i32.add
  local.get $l3
  call $f26
  call $f39
  drop
  call $f44
  drop
  call $f0
  local.get $l4
  call $f25
  i32.add
  local.get $l4
  call $f26
  call $f39
  drop
  call $f45
  drop
  call $f77
  drop
  i32.const 921
  i32.const 10
  call $f39
  drop
  block
  call $f46
  call $f31
  i32.eq
  i32.const 0
  i32.ne
  call $f0
  call $f47
  call $f25
  i32.add
  i32.load8_u
  i32.const 59
  i32.eq
  i32.const 0
  i32.ne
  i32.mul
  i32.const 0
  i32.eq
  br_if 0
  call $f50
  drop
  end
  br 1
  end
  block
  block
  local.get $l0
  call $f24
  call $f28
  i32.eq
  i32.const 0
  i32.ne
  i32.const 1
  call $f48
  call $f31
  i32.eq
  i32.const 0
  i32.ne
  i32.mul
  i32.const 0
  i32.ne
  call $f0
  i32.const 1
  call $f49
  call $f25
  i32.add
  i32.load8_u
  i32.const 61
  i32.eq
  i32.const 0
  i32.ne
  i32.mul
  i32.const 0
  i32.eq
  br_if 0
  call $f50
  drop
  call $f50
  drop
  i32.const 931
  i32.const 16
  call $f39
  drop
  call $f0
  local.get $l0
  call $f25
  i32.add
  local.get $l0
  call $f26
  call $f39
  drop
  call $f45
  drop
  call $f77
  drop
  i32.const 947
  i32.const 10
  call $f39
  drop
  block
  call $f46
  call $f31
  i32.eq
  i32.const 0
  i32.ne
  call $f0
  call $f47
  call $f25
  i32.add
  i32.load8_u
  i32.const 59
  i32.eq
  i32.const 0
  i32.ne
  i32.mul
  i32.const 0
  i32.eq
  br_if 0
  call $f50
  drop
  end
  br 1
  end
  call $f17
  i32.load
  local.set $l5
  i32.const 957
  i32.const 14
  call $f39
  drop
  call $f77
  drop
  i32.const 971
  i32.const 10
  call $f39
  drop
  block
  call $f46
  call $f31
  i32.eq
  i32.const 0
  i32.ne
  call $f0
  call $f47
  call $f25
  i32.add
  i32.load8_u
  i32.const 59
  i32.eq
  i32.const 0
  i32.ne
  i32.mul
  i32.const 0
  i32.eq
  br_if 0
  call $f50
  drop
  end
  call $f17
  i32.load
  local.set $l6
  block
  local.get $l5
  local.get $l6
  i32.eq
  i32.const 0
  i32.eq
  br_if 0
  call $f50
  drop
  end
  end
  end
  end
  end
  end
  end
  i32.const 0
  return
 )
 (func $f90 (result i32)
  (local $l0 i32)
  (local $l1 i32)
  (local $l2 i32)
  (local $l3 i32)
  (local $l4 i32)
  (local $l5 i32)
  (local $l6 i32)
  i32.const 0
  local.set $l0
  i32.const 0
  local.set $l1
  block
  loop
  local.get $l1
  i32.const 0
  i32.eq
  i32.const 0
  i32.eq
  br_if 1
  block
  block
  local.get $l0
  i32.const 4095
  i32.ge_s
  i32.const 0
  i32.eq
  br_if 0
  i32.const 1
  local.set $l1
  br 1
  end
  call $f9
  call $f7
  local.get $l0
  i32.add
  i32.store
  call $f9
  i32.const 4
  i32.add
  i32.const 4095
  local.get $l0
  i32.sub
  i32.store
  call $f10
  i32.const 0
  i32.store
  block
  i32.const 0
  call $f9
  i32.const 1
  call $f10
  call $f1000006
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
  call $f10
  i32.load
  local.set $l2
  block
  block
  local.get $l2
  i32.const 0
  i32.le_s
  i32.const 0
  i32.eq
  br_if 0
  i32.const 1
  local.set $l1
  br 1
  end
  local.get $l0
  local.get $l2
  i32.add
  local.set $l0
  end
  end
  br 0
  end
  end
  call $f7
  local.get $l0
  i32.add
  i32.const 0
  i32.store8
  call $f7
  local.set $l3
  call $f7
  local.get $l0
  i32.add
  local.set $l4
  block
  loop
  local.get $l3
  local.get $l4
  i32.lt_s
  i32.const 0
  i32.ne
  local.get $l3
  i32.load8_u
  i32.const 32
  i32.le_s
  i32.const 0
  i32.ne
  i32.mul
  i32.const 0
  i32.eq
  br_if 1
  local.get $l3
  i32.const 1
  i32.add
  local.set $l3
  br 0
  end
  end
  block
  local.get $l3
  local.get $l4
  i32.ge_s
  i32.const 0
  i32.eq
  br_if 0
  i32.const 0
  i32.const 11
  i32.sub
  return
  end
  local.get $l3
  local.set $l5
  block
  loop
  local.get $l3
  local.get $l4
  i32.lt_s
  i32.const 0
  i32.ne
  local.get $l3
  i32.load8_u
  i32.const 32
  i32.gt_s
  i32.const 0
  i32.ne
  i32.mul
  i32.const 0
  i32.eq
  br_if 1
  local.get $l3
  i32.const 1
  i32.add
  local.set $l3
  br 0
  end
  end
  block
  local.get $l3
  local.get $l4
  i32.lt_s
  i32.const 0
  i32.eq
  br_if 0
  local.get $l3
  i32.const 0
  i32.store8
  local.get $l3
  i32.const 1
  i32.add
  local.set $l3
  end
  block
  loop
  local.get $l3
  local.get $l4
  i32.lt_s
  i32.const 0
  i32.ne
  local.get $l3
  i32.load8_u
  i32.const 32
  i32.le_s
  i32.const 0
  i32.ne
  i32.mul
  i32.const 0
  i32.eq
  br_if 1
  local.get $l3
  i32.const 1
  i32.add
  local.set $l3
  br 0
  end
  end
  block
  local.get $l3
  local.get $l4
  i32.ge_s
  i32.const 0
  i32.eq
  br_if 0
  i32.const 0
  i32.const 12
  i32.sub
  return
  end
  block
  local.get $l3
  i32.load8_u
  i32.const 45
  i32.ne
  i32.const 0
  i32.ne
  local.get $l3
  i32.const 1
  i32.add
  i32.load8_u
  i32.const 111
  i32.ne
  i32.const 0
  i32.ne
  i32.add
  i32.const 0
  i32.ne
  i32.const 0
  i32.eq
  br_if 0
  i32.const 0
  i32.const 13
  i32.sub
  return
  end
  local.get $l3
  i32.const 2
  i32.add
  local.set $l3
  block
  loop
  local.get $l3
  local.get $l4
  i32.lt_s
  i32.const 0
  i32.ne
  local.get $l3
  i32.load8_u
  i32.const 32
  i32.le_s
  i32.const 0
  i32.ne
  i32.mul
  i32.const 0
  i32.eq
  br_if 1
  local.get $l3
  i32.const 1
  i32.add
  local.set $l3
  br 0
  end
  end
  block
  local.get $l3
  local.get $l4
  i32.ge_s
  i32.const 0
  i32.eq
  br_if 0
  i32.const 0
  i32.const 14
  i32.sub
  return
  end
  local.get $l3
  local.set $l6
  block
  loop
  local.get $l3
  local.get $l4
  i32.lt_s
  i32.const 0
  i32.ne
  local.get $l3
  i32.load8_u
  i32.const 32
  i32.gt_s
  i32.const 0
  i32.ne
  i32.mul
  i32.const 0
  i32.eq
  br_if 1
  local.get $l3
  i32.const 1
  i32.add
  local.set $l3
  br 0
  end
  end
  block
  local.get $l3
  local.get $l4
  i32.lt_s
  i32.const 0
  i32.eq
  br_if 0
  local.get $l3
  i32.const 0
  i32.store8
  end
  call $f11
  local.get $l5
  i32.store
  call $f12
  local.get $l6
  i32.store
  i32.const 0
  return
 )
 (func $f91 (param $l0 i32) (result i32)
  (local $l1 i32)
  (local $l2 i32)
  (local $l3 i32)
  (local $l4 i32)
  (local $l5 i32)
  (local $l6 i32)
  (local $l7 i32)
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
  local.get $l0
  local.set $l2
  local.get $l1
  local.set $l3
  block
  local.get $l3
  i32.const 0
  i32.gt_s
  i32.const 0
  i32.ne
  local.get $l2
  i32.load8_u
  i32.const 47
  i32.eq
  i32.const 0
  i32.ne
  i32.mul
  i32.const 0
  i32.eq
  br_if 0
  local.get $l2
  i32.const 1
  i32.add
  local.set $l2
  local.get $l3
  i32.const 1
  i32.sub
  local.set $l3
  end
  call $f8
  i32.const 0
  i32.store
  block
  i32.const 3
  i32.const 0
  local.get $l2
  local.get $l3
  i32.const 0
  i32.const 1
  i64.extend_i32_u
  i32.const 0
  i64.extend_i32_u
  i32.const 0
  call $f8
  call $f1000007
  i32.const 0
  i32.ne
  i32.const 0
  i32.eq
  br_if 0
  i32.const 0
  i32.const 20
  i32.sub
  return
  end
  call $f8
  i32.load
  local.set $l4
  i32.const 0
  local.set $l5
  i32.const 0
  local.set $l6
  block
  loop
  local.get $l6
  i32.const 0
  i32.eq
  i32.const 0
  i32.eq
  br_if 1
  block
  local.get $l5
  call $f1
  i32.ge_s
  i32.const 0
  i32.eq
  br_if 0
  local.get $l4
  call $f1000008
  drop
  i32.const 0
  i32.const 21
  i32.sub
  return
  end
  call $f9
  call $f0
  local.get $l5
  i32.add
  i32.store
  call $f9
  i32.const 4
  i32.add
  call $f1
  local.get $l5
  i32.sub
  i32.store
  call $f10
  i32.const 0
  i32.store
  block
  local.get $l4
  call $f9
  i32.const 1
  call $f10
  call $f1000006
  i32.const 0
  i32.ne
  i32.const 0
  i32.eq
  br_if 0
  local.get $l4
  call $f1000008
  drop
  i32.const 0
  i32.const 22
  i32.sub
  return
  end
  call $f10
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
  local.set $l6
  br 1
  end
  local.get $l5
  local.get $l7
  i32.add
  local.set $l5
  end
  br 0
  end
  end
  local.get $l4
  call $f1000008
  drop
  local.get $l5
  return
 )
 (func $f92 (param $l0 i32) (param $l1 i32) (result i32)
  (local $l2 i32)
  (local $l3 i32)
  (local $l4 i32)
  (local $l5 i32)
  (local $l6 i32)
  (local $l7 i32)
  (local $l8 i32)
  i32.const 0
  local.set $l2
  block
  loop
  local.get $l0
  local.get $l2
  i32.add
  i32.load8_u
  i32.const 0
  i32.ne
  i32.const 0
  i32.eq
  br_if 1
  local.get $l2
  i32.const 1
  i32.add
  local.set $l2
  br 0
  end
  end
  local.get $l0
  local.set $l3
  local.get $l2
  local.set $l4
  block
  local.get $l4
  i32.const 0
  i32.gt_s
  i32.const 0
  i32.ne
  local.get $l3
  i32.load8_u
  i32.const 47
  i32.eq
  i32.const 0
  i32.ne
  i32.mul
  i32.const 0
  i32.eq
  br_if 0
  local.get $l3
  i32.const 1
  i32.add
  local.set $l3
  local.get $l4
  i32.const 1
  i32.sub
  local.set $l4
  end
  call $f8
  i32.const 0
  i32.store
  block
  i32.const 3
  i32.const 0
  local.get $l3
  local.get $l4
  i32.const 9
  i32.const 64
  i64.extend_i32_u
  i32.const 0
  i64.extend_i32_u
  i32.const 0
  call $f8
  call $f1000007
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
  call $f8
  i32.load
  local.set $l5
  i32.const 0
  local.set $l6
  block
  loop
  local.get $l6
  local.get $l1
  i32.lt_s
  i32.const 0
  i32.eq
  br_if 1
  local.get $l1
  local.get $l6
  i32.sub
  local.set $l7
  block
  local.get $l7
  i32.const 4096
  i32.gt_s
  i32.const 0
  i32.eq
  br_if 0
  i32.const 4096
  local.set $l7
  end
  call $f9
  call $f2
  local.get $l6
  i32.add
  i32.store
  call $f9
  i32.const 4
  i32.add
  local.get $l7
  i32.store
  call $f10
  i32.const 0
  i32.store
  block
  local.get $l5
  call $f9
  i32.const 1
  call $f10
  call $f1000005
  i32.const 0
  i32.ne
  i32.const 0
  i32.eq
  br_if 0
  local.get $l5
  call $f1000008
  drop
  i32.const 0
  i32.const 31
  i32.sub
  return
  end
  call $f10
  i32.load
  local.set $l8
  block
  local.get $l8
  i32.const 0
  i32.le_s
  i32.const 0
  i32.eq
  br_if 0
  local.get $l5
  call $f1000008
  drop
  i32.const 0
  i32.const 32
  i32.sub
  return
  end
  local.get $l6
  local.get $l8
  i32.add
  local.set $l6
  br 0
  end
  end
  local.get $l5
  call $f1000008
  drop
  i32.const 0
  return
 )
 (func $f93 (result i32)
  (local $l0 i32)
  (local $l1 i32)
  (local $l2 i32)
  block
  call $f90
  i32.const 0
  i32.ne
  i32.const 0
  i32.eq
  br_if 0
  i32.const 1
  return
  end
  call $f11
  i32.load
  call $f91
  local.set $l0
  block
  local.get $l0
  i32.const 0
  i32.lt_s
  i32.const 0
  i32.eq
  br_if 0
  i32.const 2
  return
  end
  block
  local.get $l0
  i32.const 0
  i32.eq
  i32.const 0
  i32.eq
  br_if 0
  i32.const 3
  return
  end
  call $f15
  local.get $l0
  i32.store
  call $f67
  drop
  call $f37
  drop
  call $f16
  i32.load
  local.set $l1
  block
  local.get $l1
  i32.const 0
  i32.eq
  i32.const 0
  i32.eq
  br_if 0
  i32.const 5
  return
  end
  call $f17
  i32.const 0
  i32.store
  call $f13
  i32.const 0
  i32.store
  call $f84
  drop
  call $f13
  i32.load
  local.set $l2
  block
  call $f12
  i32.load
  local.get $l2
  call $f92
  i32.const 0
  i32.ne
  i32.const 0
  i32.eq
  br_if 0
  i32.const 4
  return
  end
  i32.const 0
  return
 )
 (export "main" (func $f93))
 (func $_start
  call $f93
  drop
 )
 (export "_start" (func $_start))
)
