#!/usr/bin/env python3
"""Run the self-checking RTL regression with Icarus Verilog, without vendor IP."""
import argparse
import shutil
import subprocess
from pathlib import Path

CASES = [
    ("tone", "tb_buzzer_tone", "TONE TEST PASSED"),
    ("display", "tb_display_selftest", "SELFTEST PASSED"),
    ("ranging", "tb_step_ultrasonic", "ALL TESTS PASSED"),
]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--iverilog", default="iverilog")
    parser.add_argument("--vvp", default="vvp")
    args = parser.parse_args()
    compiler = shutil.which(args.iverilog)
    runtime = shutil.which(args.vvp)
    if not compiler or not runtime:
        parser.error("Install Icarus Verilog and place iverilog/vvp on PATH.")
    root = Path(__file__).resolve().parents[1]
    build = root / "build"
    build.mkdir(exist_ok=True)
    rtl = sorted((root / "rtl").glob("*.v"))
    for name, top, marker in CASES:
        output = build / (name + ".vvp")
        command = [compiler, "-g2012", "-s", top, "-o", str(output)]
        command += [str(p) for p in rtl]
        command += [str(root / "sim" / (top + ".sv"))]
        subprocess.run(command, cwd=root, check=True, timeout=60)
        result = subprocess.run(
            [runtime, str(output)], cwd=root, text=True,
            stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=600,
        )
        (build / (name + ".log")).write_text(result.stdout, encoding="utf-8")
        print(result.stdout, end="", flush=True)
        if result.returncode or marker not in result.stdout:
            raise SystemExit("FAIL: " + name)
        print("PASS: " + name, flush=True)
    print("All RTL regressions passed.")


if __name__ == "__main__":
    main()
