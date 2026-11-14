#!/usr/bin/env python3
# Runs the ESP block of ../Source.luau against a mock of the Roblox API (mock.lua) and a scenario (scenario.lua).
# Needs a Lua 5.3+ interpreter: texlua, lua5.4, lua5.3 or lua on the PATH.
# The mock checks logic, the projection maths and the number of property writes per frame. It does not render.
import pathlib, re, shutil, subprocess, sys, tempfile

here = pathlib.Path(__file__).resolve().parent
source = here.parent / "Source.luau"
interp = next((shutil.which(name) for name in ("texlua", "lua5.4", "lua5.3", "lua") if shutil.which(name)), None)
if interp is None:
    print("no Lua 5.3+ interpreter found (texlua, lua5.4, lua5.3 or lua)")
    sys.exit(2)

def to_lua(block):
    out = []
    for line in block.split("\n"):
        if not line.lstrip().startswith("--"):
            m = re.match(r"^(\s*)(.+?)\s*([+\-*])=\s*(.+)$", line)
            if m and "==" not in line:
                indent, lhs, op, rhs = m.groups()
                line = f"{indent}{lhs} = {lhs} {op} ({rhs})"
            m = re.match(r"^(\s*)for (.+?) in (.+) do\s*$", line)
            if m and "pairs(" not in m.group(3):
                indent, names, expr = m.groups()
                line = f"{indent}for {names} in pairs({expr}) do"
        out.append(line)
    return "\n".join(out)

text = source.read_text(encoding="utf-8")
block = text[text.index("-- // ESP // --"):text.index("\nreturn Library\nend)()")]
is_new = "function ESP.Basis" in block
code = ((here / "mock.lua").read_text(encoding="utf-8") + "\n" + to_lua(block)
        + f"\nIS_NEW_FLAG = {'true' if is_new else 'false'}\n" + (here / "scenario.lua").read_text(encoding="utf-8"))
with tempfile.TemporaryDirectory() as folder:
    script = pathlib.Path(folder) / "esp_run.lua"
    script.write_text(code, encoding="utf-8")
    proc = subprocess.run([interp, str(script)], capture_output=True, text=True, timeout=900)
print(proc.stdout)
if proc.stderr.strip():
    print(proc.stderr)
passed = proc.returncode == 0 and "fails=0 warnings=0" in proc.stdout
print("PASS" if passed else "FAIL")
sys.exit(0 if passed else 1)
