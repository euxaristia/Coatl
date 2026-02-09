# Fix: String Literals Missing Closing Quote in aarch64 Binary Output

## Issue

When building Coatl programs for aarch64 (e.g., Raspberry Pi 4), string literals in the binary output were missing the closing quote character. For example:

```coatl
let msg: i32 = "Hello, world!\n";
```

Would output `"Hello, world!` instead of `Hello, world!` (without quotes).

The WAT output via the self-host compiler worked correctly, but the IR pipeline (used for aarch64) was broken.

## Root Cause

In `tools/ir_to_aarch64_asm.coatl`, the `emit_program` function was including the quote characters when emitting string data to the assembly output.

The code was using:
- `sl = node_atom_len(an)` - length including quotes (e.g., 16 for `"Hello, world!\n"`)
- `so = node_atom_off(an)` - offset pointing to the opening quote
- Emitting all characters from `so` to `so + sl` including both quotes

## Fix

Modified the string emission loop in `emit_program` to:
1. Calculate `content_off = so + 1` - start after the opening quote
2. Calculate `content_len = sl - 2` - exclude both quotes
3. Emit only the string content bytes

Changed:
```coatl
let sl: i32 = node_atom_len(an); let so: i32 = node_atom_off(an); let sj: i32 = 0;
while (sj < sl) { 
  out_int(__mem_load8(ir_buf_base()+so+sj)); 
  sj = sj + 1; 
}
strb [x2, #sl], #0
```

To:
```coatl
let sl: i32 = node_atom_len(an); let so: i32 = node_atom_off(an); 
let content_off: i32 = so + 1; let content_len: i32 = sl - 2; let sj: i32 = 0;
while (sj < content_len) { 
  out_int(__mem_load8(ir_buf_base()+content_off+sj)); 
  sj = sj + 1; 
}
strb [x2, #content_len], #0
```

## Files Changed

- `tools/ir_to_aarch64_asm.coatl` - Fixed string emission logic

## Verification

Build and run the hello example:
```bash
./coatl build ./examples/hello.coatl -o hello.bin
./hello.bin
```

Expected output:
```
Hello, world!
```

Note: The x86_64 backend (`ir_to_x86_64_asm.coatl`) was not affected by this issue and required no changes.
