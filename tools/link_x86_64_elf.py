#!/usr/bin/env python3
import argparse
import struct
from pathlib import Path
from typing import Dict, Tuple


class LinkError(Exception):
    pass


ELF_HDR_FMT = "<16sHHIQQQIHHHHHH"
SEC_HDR_FMT = "<IIQQQQIIQQ"
SYM_FMT = "<IBBHQQ"
RELA_FMT = "<QQq"

SHT_SYMTAB = 2
SHT_STRTAB = 3
SHT_RELA = 4

R_X86_64_PC32 = 2
R_X86_64_PLT32 = 4

SHN_UNDEF = 0
SHN_ABS = 0xFFF1


def read_struct(buf: bytes, off: int, fmt: str):
    size = struct.calcsize(fmt)
    return struct.unpack(fmt, buf[off:off + size]), off + size


def cstr(buf: bytes, off: int) -> str:
    end = buf.find(b"\x00", off)
    if end < 0:
        return ""
    return buf[off:end].decode("utf-8", errors="ignore")


def align_up(v: int, a: int) -> int:
    return (v + a - 1) & ~(a - 1)


def link_single_obj(obj_path: Path, out_path: Path, entry_name: str) -> None:
    data = obj_path.read_bytes()
    (eh, _) = read_struct(data, 0, ELF_HDR_FMT)
    e_ident = eh[0]
    if e_ident[:4] != b"\x7fELF" or e_ident[4] != 2 or e_ident[5] != 1:
        raise LinkError("unsupported ELF object format")
    e_shoff = eh[6]
    e_shentsize = eh[11]
    e_shnum = eh[12]
    e_shstrndx = eh[13]

    shdrs = []
    for i in range(e_shnum):
        off = e_shoff + i * e_shentsize
        sh, _ = read_struct(data, off, SEC_HDR_FMT)
        shdrs.append(sh)

    shstr = shdrs[e_shstrndx]
    shstr_data = data[shstr[4]:shstr[4] + shstr[5]]

    sec_by_name: Dict[str, Tuple[int, tuple]] = {}
    for idx, sh in enumerate(shdrs):
        nm = cstr(shstr_data, sh[0])
        sec_by_name[nm] = (idx, sh)

    if ".text" not in sec_by_name or ".symtab" not in sec_by_name or ".strtab" not in sec_by_name:
        raise LinkError("object missing required sections")

    text_idx, text_sh = sec_by_name[".text"]
    text = bytearray(data[text_sh[4]:text_sh[4] + text_sh[5]])
    bss_size = sec_by_name.get(".bss", (0, (0, 0, 0, 0, 0, 0, 0, 0, 0, 0)))[1][5]

    sym_idx, sym_sh = sec_by_name[".symtab"]
    str_idx, str_sh = sec_by_name[".strtab"]
    strtab = data[str_sh[4]:str_sh[4] + str_sh[5]]
    syms = []
    sym_count = sym_sh[5] // sym_sh[9]
    for i in range(sym_count):
        off = sym_sh[4] + i * sym_sh[9]
        s, _ = read_struct(data, off, SYM_FMT)
        syms.append(s)

    base = 0x400000
    text_off = 0x1000
    text_vaddr = base + text_off
    bss_vaddr = align_up(text_vaddr + len(text), 16)
    bss_end = bss_vaddr + bss_size

    def sym_addr(sym) -> int:
        st_name, _st_info, _st_other, st_shndx, st_value, _st_size = sym
        if st_shndx == SHN_UNDEF:
            raise LinkError(f"undefined symbol: {cstr(strtab, st_name)}")
        if st_shndx == SHN_ABS:
            return st_value
        if st_shndx == text_idx:
            return text_vaddr + st_value
        if ".bss" in sec_by_name and st_shndx == sec_by_name[".bss"][0]:
            return bss_vaddr + st_value
        raise LinkError(f"unsupported symbol section index: {st_shndx}")

    rela_name = ".rela.text"
    if rela_name in sec_by_name:
        _, rela_sh = sec_by_name[rela_name]
        rela_count = rela_sh[5] // rela_sh[9]
        for i in range(rela_count):
            off = rela_sh[4] + i * rela_sh[9]
            (r_offset, r_info, r_addend), _ = read_struct(data, off, RELA_FMT)
            r_type = r_info & 0xFFFFFFFF
            r_sym = r_info >> 32
            if r_type not in (R_X86_64_PC32, R_X86_64_PLT32):
                raise LinkError(f"unsupported relocation type: {r_type}")
            s_addr = sym_addr(syms[r_sym])
            p_addr = text_vaddr + r_offset
            val = s_addr + r_addend - p_addr
            if not (-0x80000000 <= val <= 0x7FFFFFFF):
                raise LinkError("relocation overflow")
            text[r_offset:r_offset + 4] = struct.pack("<i", val)

    entry_addr = None
    for sym in syms:
        nm = cstr(strtab, sym[0])
        if nm == entry_name:
            entry_addr = sym_addr(sym)
            break
    if entry_addr is None:
        raise LinkError(f"entry symbol not found: {entry_name}")

    elf_hdr_size = struct.calcsize(ELF_HDR_FMT)
    phdr_size = 56
    file_prefix = bytearray(text_off)
    memsz = bss_end - base
    filesz = text_off + len(text)

    e_ident_out = bytearray(16)
    e_ident_out[:4] = b"\x7fELF"
    e_ident_out[4] = 2
    e_ident_out[5] = 1
    e_ident_out[6] = 1

    ehdr = struct.pack(
        ELF_HDR_FMT,
        bytes(e_ident_out),
        2,
        62,
        1,
        entry_addr,
        elf_hdr_size,
        0,
        0,
        elf_hdr_size,
        phdr_size,
        1,
        0,
        0,
        0,
    )
    phdr = struct.pack(
        "<IIQQQQQQ",
        1,
        7,
        0,
        base,
        base,
        filesz,
        memsz,
        0x1000,
    )
    file_prefix[:len(ehdr)] = ehdr
    file_prefix[len(ehdr):len(ehdr) + len(phdr)] = phdr

    out = file_prefix + text
    out_path.write_bytes(out)
    out_path.chmod(0o755)


def main() -> int:
    ap = argparse.ArgumentParser(description="Minimal x86_64 ELF linker for single relocatable object")
    ap.add_argument("input", help="input .o file")
    ap.add_argument("-o", "--output", required=True, help="output ELF executable")
    ap.add_argument("--entry", default="coatl_start", help="entry symbol")
    args = ap.parse_args()
    link_single_obj(Path(args.input), Path(args.output), args.entry)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
