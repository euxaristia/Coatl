use std::env;
use std::fs;
use std::process::Command;
use std::path::PathBuf;

fn get_coatl_bin() -> PathBuf {
    let mut path = env::current_dir().unwrap();
    path.push("target");
    path.push("debug"); // or release if tests are run in release
    path.push("coatl");
    if !path.exists() {
        // Fallback for `cargo test` usually building in `target/debug`
        path = env::current_dir().unwrap().join("target/release/coatl");
    }
    path
}

fn build_bin(src: &str, bin_name: &str, arch: &str) -> Option<PathBuf> {
    let coatl_bin = get_coatl_bin();
    let tmp_dir = env::temp_dir().join(format!("coatl-test-{}", bin_name));
    let _ = fs::create_dir_all(&tmp_dir);
    let bin_path = tmp_dir.join(bin_name);

    let mut cmd = Command::new(&coatl_bin);
    cmd.arg(src)
       .arg(format!("--arch={}", arch))
       .arg("-o")
       .arg(&bin_path);

    let status = cmd.status().expect("Failed to execute coatl compiler");
    if status.success() && bin_path.exists() {
        Some(bin_path)
    } else {
        None
    }
}

fn assert_rc(expected: i32, got: i32, label: &str) {
    assert_eq!(expected, got, "[FAIL] {} expected rc={} got rc={}", label, expected, got);
}

#[test]
fn test_ir_smoke() {
    let root_dir = env::current_dir().unwrap();
    let tmp_dir = env::temp_dir().join("coatl-ir-smoke");
    let _ = fs::create_dir_all(&tmp_dir);
    let coatl_bin = get_coatl_bin();

    // 1. Hello IR
    let hello_ir = tmp_dir.join("hello.ir");
    let status = Command::new(&coatl_bin)
        .arg(root_dir.join("examples/hello.coatl").to_str().unwrap())
        .arg("-o")
        .arg(&hello_ir)
        .status().unwrap();
    assert!(status.success());
    let content = fs::read_to_string(&hello_ir).unwrap();
    assert!(content.contains("(coatl_ir v1"));
    assert!(content.contains("(fn main"));
    assert!(content.contains("(call __print"));

    // 2. Struct Chain IR
    let struct_ir = tmp_dir.join("struct_chain.ir");
    let status = Command::new(&coatl_bin)
        .arg(root_dir.join("tests/struct_chain_calls.coatl").to_str().unwrap())
        .arg("-o")
        .arg(&struct_ir)
        .status().unwrap();
    assert!(status.success());
    let content = fs::read_to_string(&struct_ir).unwrap();
    assert!(content.contains("(fn make_point"));
    assert!(content.contains("(call sum_point"));

    // 3. Module Smoke IR
    let mod_ir = tmp_dir.join("module_smoke.ir");
    let status = Command::new(&coatl_bin)
        .arg(root_dir.join("tests/module_smoke.coatl").to_str().unwrap())
        .arg("-o")
        .arg(&mod_ir)
        .status().unwrap();
    assert!(status.success());
    let content = fs::read_to_string(&mod_ir).unwrap();
    assert!(content.contains("(imports"));
    assert!(content.contains("(fn main"));
    assert!(content.contains("(fn print"));
}

#[test]
#[ignore]
fn test_x86_subset_asm_smoke() {
    if env::consts::OS != "linux" || env::consts::ARCH != "x86_64" {
        println!("Skipping x86_64 execution tests (not linux/x86_64)");
        return;
    }

    let root_dir = env::current_dir().unwrap();
    let tests = vec![
        ("examples/hello.coatl", "hello", 0),
        ("tests/mem_test.coatl", "mem", 142),
        ("tests/byte_test.coatl", "byte", 133),
        ("tests/array_sim.coatl", "array", 100),
        ("tests/ir_subset_control_flow.coatl", "control", 77),
        ("tests/nested_let_scope_subset.coatl", "nested-let", 7),
        ("tests/struct_chain_calls.coatl", "struct", 6),
        ("tests/struct_return_basic.coatl", "struct-return-basic", 15),
        ("tests/struct_param_pass.coatl", "struct-param", 9),
        ("tests/struct_field_mutation_subset.coatl", "struct-mutate", 33),
        ("tests/struct_nested_arg_subset.coatl", "struct-nested", 6),
        ("tests/struct_return_if_subset.coatl", "struct-if", 36),
        ("tests/struct_return_while_subset.coatl", "struct-while", 9),
    ];

    for (src_rel, bin_name, expected_rc) in tests {
        let src_path = root_dir.join(src_rel);
        let bin_path = build_bin(src_path.to_str().unwrap(), bin_name, "x86_64").expect("Build failed");
        
        let output = Command::new(&bin_path).output().unwrap();
        let rc = output.status.code().unwrap_or(-1);
        assert_rc(expected_rc, rc, bin_name);

        if bin_name == "hello" {
            let stdout = String::from_utf8_lossy(&output.stdout);
            assert!(stdout.contains("Hello, world!"));
        }
    }

    // fd_read
    let read_bin = build_bin(root_dir.join("tests/x86_fd_read_test.coatl").to_str().unwrap(), "read", "x86_64").unwrap();
    use std::io::Write;
    let mut child = Command::new(&read_bin)
        .stdin(std::process::Stdio::piped())
        .stdout(std::process::Stdio::piped())
        .spawn().unwrap();
    child.stdin.as_mut().unwrap().write_all(b"abcd").unwrap();
    let output = child.wait_with_output().unwrap();
    assert_rc(4, output.status.code().unwrap_or(-1), "fd_read");

    // path_open_write
    let write_bin = build_bin(root_dir.join("tests/x86_path_open_write_test.coatl").to_str().unwrap(), "write", "x86_64").unwrap();
    let test_file = "/tmp/coatl_x86_io_test.txt";
    let _ = fs::remove_file(test_file);
    let status = Command::new(&write_bin).status().unwrap();
    assert_rc(3, status.code().unwrap_or(-1), "path_open_write");
    assert!(PathBuf::from(test_file).exists(), "[FAIL] missing output file");
    let content = fs::read_to_string(test_file).unwrap();
    assert_eq!(content, "OK\n", "[FAIL] file content mismatch");
    let _ = fs::remove_file(test_file);
}

#[test]
fn test_snake_smoke() {
    let root_dir = env::current_dir().unwrap();
    let src_path = root_dir.join("examples/TermSnake/snake.coatl");

    // Test x86_64
    let bin_path_x86 = build_bin(src_path.to_str().unwrap(), "snake_x86", "x86_64").expect("Build snake x86_64 failed");
    if env::consts::ARCH == "x86_64" && env::consts::OS == "linux" {
        use std::io::Write;
        let mut child = Command::new(&bin_path_x86)
            .stdin(std::process::Stdio::piped())
            .stdout(std::process::Stdio::null())
            .stderr(std::process::Stdio::null())
            .spawn().unwrap();
        if let Some(mut stdin) = child.stdin.take() {
            let _ = stdin.write_all(b"q\n");
        }
        // Just let it exit immediately
        let _ = child.wait();
    }

    // Test aarch64 (build only)
    if Command::new("command").args(&["-v", "aarch64-linux-gnu-gcc"]).status().map(|s| s.success()).unwrap_or(false) || env::consts::ARCH == "aarch64" {
        let _bin_path_aarch64 = build_bin(src_path.to_str().unwrap(), "snake_aarch64", "aarch64").expect("Build snake aarch64 failed");
    }
}
