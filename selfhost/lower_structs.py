#!/usr/bin/env python3
from __future__ import annotations

import re
import sys
from dataclasses import dataclass
from pathlib import Path


@dataclass
class StructDef:
    name: str
    fields: list[str]


STRUCT_RE = re.compile(r"struct\s+([A-Za-z_][A-Za-z0-9_]*)\s*\{", re.MULTILINE)


def parse_structs(src: str) -> list[StructDef]:
    out = []
    i = 0
    while i < len(src):
        m = STRUCT_RE.search(src, i)
        if not m:
            break
        name = m.group(1)
        j = m.end()
        depth = 1
        while j < len(src) and depth > 0:
            c = src[j]
            if c == "{":
                depth += 1
            elif c == "}":
                depth -= 1
            j += 1
        body = src[m.end() : j - 1]
        fields = []
        for line in body.splitlines():
            s = line.strip().rstrip(",")
            if not s:
                continue
            if ":" not in s:
                continue
            fname, fty = [x.strip() for x in s.split(":", 1)]
            if fty != "i32":
                raise SystemExit(f"unsupported struct field type in {name}: {s}")
            fields.append(fname)
        if not fields:
            raise SystemExit(f"struct {name} has no fields")
        out.append(StructDef(name=name, fields=fields))
        i = j
    return out


def protect_struct_defs(src: str) -> tuple[str, list[str]]:
    chunks: list[str] = []
    out: list[str] = []
    i = 0
    while i < len(src):
        m = STRUCT_RE.search(src, i)
        if not m:
            out.append(src[i:])
            break
        out.append(src[i : m.start()])
        j = m.end()
        depth = 1
        while j < len(src) and depth > 0:
            c = src[j]
            if c == "{":
                depth += 1
            elif c == "}":
                depth -= 1
            j += 1
        chunk = src[m.start() : j]
        idx = len(chunks)
        chunks.append(chunk)
        out.append(f"__MEE_STRUCT_DEF_{idx}__")
        i = j
    return "".join(out), chunks


def restore_struct_defs(src: str, chunks: list[str]) -> str:
    out = src
    for idx, chunk in enumerate(chunks):
        out = out.replace(f"__MEE_STRUCT_DEF_{idx}__", chunk)
    return out


def gen_helpers(sdefs: list[StructDef]) -> str:
    if not sdefs:
        return ""
    lines = []
    lines.append("fn __struct_heap_init() -> i32 {")
    lines.append("  let p: i32 = __mem_load(4096);")
    lines.append("  if (p == 0) {")
    lines.append("    __mem_store(4096, 8192);")
    lines.append("  }")
    lines.append("  return 0;")
    lines.append("}")
    lines.append("")
    for sd in sdefs:
        size = 4 * len(sd.fields)
        lines.append(f"fn __alloc_{sd.name}() -> i32 {{")
        lines.append("  __struct_heap_init();")
        lines.append("  let p: i32 = __mem_load(4096);")
        lines.append(f"  __mem_store(4096, p + {size});")
        lines.append("  return p;")
        lines.append("}")
        lines.append("")
        params = ", ".join([f"{f}: i32" for f in sd.fields])
        lines.append(f"fn __mk_{sd.name}({params}) -> i32 {{")
        lines.append(f"  let p: i32 = __alloc_{sd.name}();")
        for idx, f in enumerate(sd.fields):
            lines.append(f"  __mem_store(p + {idx * 4}, {f});")
        lines.append("  return p;")
        lines.append("}")
        lines.append("")
        for idx, f in enumerate(sd.fields):
            lines.append(f"fn __get_{sd.name}_{f}(p: i32) -> i32 {{")
            lines.append(f"  return __mem_load(p + {idx * 4});")
            lines.append("}")
            lines.append("")
    return "\n".join(lines)


def lower(src: str) -> str:
    sdefs = parse_structs(src)
    if not sdefs:
        return src
    masked, defs = protect_struct_defs(src)
    src2 = restore_struct_defs(masked, defs)
    helpers = gen_helpers(sdefs)
    return helpers + "\n" + src2.lstrip()


def main() -> int:
    if len(sys.argv) != 3:
        print("usage: lower_structs.py <input.mee> <output.mee>", file=sys.stderr)
        return 2
    inp = Path(sys.argv[1]).read_text()
    out = lower(inp)
    Path(sys.argv[2]).write_text(out)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
