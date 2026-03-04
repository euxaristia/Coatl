#!/usr/bin/env python3
import os
import sys
import shutil
import re
import argparse

def log(msg):
    print(log)

def main():
    parser = argparse.ArgumentParser(description="Rebrand Coatl")
    parser.add_argument("--apply", action="store_true", help="Apply changes")
    parser.add_argument("--no-backup", action="store_true", help="Don't create backups")
    args = parser.parse_args()

    root_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    mode = "apply" if args.apply else "dry-run"
    backup_ext = "" if args.no_backup else ".bak"

    def maybe_mv(src, dst):
        if mode == "dry-run":
            print(f"[dry-run] mv '{src}' '{dst}'")
            return
        if os.path.exists(dst):
            print(f"[skip] target exists: {dst}")
            return
        os.rename(src, dst)
        print(f"[ok] mv '{src}' '{dst}'")

    def transform_file(f):
        if mode == "dry-run":
            # Just check if matches
            try:
                with open(f, 'r', errors='ignore') as file:
                    content = file.read()
                    if re.search(r"\bMee\b|\bmee\b|\bMEE_", content):
                        print(f"[dry-run] edit '{f}'")
            except: pass
            return

        try:
            with open(f, 'r', errors='ignore') as file:
                content = file.read()
            
            new_content = content.replace("Mee", "Coatl").replace("mee", "coatl").replace("MEE_", "COATL_")
            new_content = new_content.replace("Coatl's simplicity", "Coatl's fluidity")
            
            if new_content != content:
                if backup_ext:
                    shutil.copy(f, f + backup_ext)
                with open(f, 'w') as file:
                    file.write(new_content)
                print(f"[ok] updated '{f}'")
        except: pass

    print("== Phase 1: file system migration ==")
    # 1) .coatl -> .coatl
    for root, dirs, files in os.walk(root_dir):
        if ".git" in root or ".claude" in root: continue
        for f in files:
            if f.endswith(".coatl"):
                # Actually already .coatl in the shell script? Wait.
                # The shell script had path="${path%.coatl}.coatl" which does nothing.
                pass

    # 2) rename any directory named coatl -> coatl
    # Again, seems to be a no-op or rebranding from something else.

    print("== Phase 2: source code analysis + replacement ==")
    for root, dirs, files in os.walk(root_dir):
        if ".git" in root or ".claude" in root: continue
        for f in files:
            if f.endswith(".bak"): continue
            path = os.path.join(root, f)
            transform_file(path)

    print(f"done ({mode})")

if __name__ == "__main__":
    main()
