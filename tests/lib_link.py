import subprocess
import os
import platform

def have_tool(cmd):
    return subprocess.run(["command", "-v", cmd], shell=True, capture_output=True).returncode == 0

def link_x86_asm_binary(asm_path, bin_path):
    cc = os.environ.get("CC", "cc")
    # Simple linking, assuming intrinsics are in the right place
    root_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    intrinsics = os.path.join(root_dir, "tests/intrinsics.s")
    subprocess.run([cc, "-fPIE", "-pie", "-e", "coatl_start", asm_path, intrinsics, "-o", bin_path], check=True)

def link_aarch64_asm_binary(asm_path, bin_path):
    cc = os.environ.get("CC", "cc")
    if platform.machine() != "aarch64" and cc == "cc":
        if have_tool("aarch64-linux-gnu-gcc"):
            cc = "aarch64-linux-gnu-gcc"
    root_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    intrinsics = os.path.join(root_dir, "tests/intrinsics_aarch64.s")
    subprocess.run([cc, "-fPIE", "-pie", "-e", "coatl_start", asm_path, intrinsics, "-o", bin_path], check=True)
