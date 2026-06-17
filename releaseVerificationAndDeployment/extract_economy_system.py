#!/usr/bin/env python3
"""
extract_economy_system.py  (one-off maintenance / build tool)

Decodes the third-party "Grand Resource System" scripted composition (a single
Land_HelipadEmpty_F object whose init field carries the entire ~1MB runtime),
splits the 449 embedded functions out of the runtime block, rebrands every
identifier and user-facing string into the WaldosMissionPack "Waldos Economy
Systems" namespace, and writes:

  * MissionScripts/EconomySystems/<System>/<Name>.sqf   (one file per function)
  * MissionScripts/EconomySystems/economyInit.sqf        (the bootstrap)
  * A generated CfgFunctions block (printed) for WaldosFunctions.sqf

This tool is NOT shipped with the pack (it lives under releaseVerificationAndDeployment,
which is in config.json -> notlist). It is kept for reproducibility.

Usage:
    python3 releaseVerificationAndDeployment/extract_economy_system.py <composition.sqe>
"""

import os
import re
import sys

# --- system code -> (directory, readable segment used in the Waldo_fnc_ name) ---
SYSTEMS = {
    "US": ("Core",     "EcoCore"),
    "RS": ("Resource", "EcoResource"),
    "RC": ("Research", "EcoResearch"),
    "BS": ("Build",    "EcoBuild"),
    "BU": ("Buy",      "EcoBuy"),
    "GC": ("Command",  "EcoCommand"),
}

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_ROOT = os.path.join(REPO_ROOT, "MissionScripts", "EconomySystems")


def decode_init(raw_line):
    """Recover readable SQF from the .sqe init="..." encoding."""
    s = raw_line.strip()
    assert s.startswith('init="'), "line does not start with init=\""
    s = s[len('init="'):]
    # strip trailing '";'  (closes the init string, then ends the statement)
    assert s.endswith('";'), "line does not end with \";"
    s = s[:-2]
    # Order matters: the line separator token uses single quotes, escaped
    # in-string quotes use doubled quotes. Replace the separator first.
    s = s.replace('" \\n "', "\n")
    s = s.replace('""', '"')
    # normalise: no tabs (validator forbids them), no trailing whitespace
    s = s.replace("\t", "    ")
    return s


def strip_runtime_wrapper(code):
    """Remove the 'private _GRS_UnifiedRuntime = { ... };' wrapper and the
    trailing setVariable / spawn statements; return the inner body."""
    marker = "private _GRS_UnifiedRuntime = {"
    i = code.index(marker)
    body_start = i + len(marker)
    # find the matching closing brace for the runtime block
    depth = 1
    j = body_start
    in_str = False
    while j < len(code):
        c = code[j]
        if c == '"':
            in_str = not in_str
        elif not in_str:
            if c == "{":
                depth += 1
            elif c == "}":
                depth -= 1
                if depth == 0:
                    break
        j += 1
    inner = code[body_start:j]
    trailing = code[j + 1:]  # after the closing brace: '; setVariable...; spawn...;'
    return inner, trailing


def split_statements(body):
    """Walk the runtime body at top level, separating
    'XX_fnc_Name = { ... };' function definitions from everything else."""
    funcs = []        # (system, name, block_text)
    other = []        # raw statement text kept for the bootstrap
    i = 0
    n = len(body)
    fn_re = re.compile(r'([A-Za-z]{2,4})_fnc_([A-Za-z0-9]+)\s*=\s*\{')
    last_nonspace = ""   # last non-whitespace char already committed to 'other'
    while i < n:
        m = fn_re.search(body, i)
        if not m:
            other.append(body[i:])
            break
        # copy the gap before the candidate into 'other'
        gap = body[i:m.start()]
        if gap:
            other.append(gap)
            stripped = gap.rstrip()
            if stripped:
                last_nonspace = stripped[-1]
        sysm, name = m.group(1), m.group(2)
        # only treat as a function def when at a statement boundary
        is_def = sysm in SYSTEMS and last_nonspace in ("", ";", "{", "}")
        if not is_def:
            # not a top-level definition: keep the identifier text and move on
            tok = body[m.start():m.end()]
            other.append(tok)
            last_nonspace = tok.rstrip()[-1]
            i = m.end()
            continue
        brace_open = m.end() - 1
        depth = 1
        j = brace_open + 1
        in_str = False
        while j < n:
            c = body[j]
            if c == '"':
                in_str = not in_str
            elif not in_str:
                if c == "{":
                    depth += 1
                elif c == "}":
                    depth -= 1
                    if depth == 0:
                        break
            j += 1
        # consume trailing ';'
        k = j + 1
        while k < n and body[k] in " \t\r\n":
            k += 1
        if k < n and body[k] == ";":
            k += 1
        block = body[brace_open:j + 1]  # the { ... } block
        funcs.append((sysm, name, block))
        last_nonspace = ";"
        i = k
    return funcs, "".join(other)


ALIAS_RE = re.compile(
    r'\b([A-Za-z]{2,4})_fnc_([A-Za-z0-9]+)\s*=\s*([A-Za-z]{2,4})_fnc_([A-Za-z0-9]+)\s*;')


def build_rename_map(funcs, body):
    """Map old fully-qualified function identifiers to new Waldo_fnc_ names.

    Includes the source's per-system aliases (e.g.
    'RS_fnc_canRunAuthority = US_fnc_canRunAuthority;'), resolved so callers of
    the alias point straight at the renamed canonical function."""
    fmap = {}
    for sysm, name, _ in funcs:
        _, seg = SYSTEMS[sysm]
        fmap[f"{sysm}_fnc_{name}"] = f"Waldo_fnc_{seg}_{name}"
    # resolve aliases (targets are all brace-defined canonicals -> already in fmap)
    for m in ALIAS_RE.finditer(body):
        alias = f"{m.group(1)}_fnc_{m.group(2)}"
        target = f"{m.group(3)}_fnc_{m.group(4)}"
        if alias not in fmap and target in fmap:
            fmap[alias] = fmap[target]
    return fmap


def strip_alias_statements(text):
    """Remove redundant 'A_fnc_X = B_fnc_Y;' alias lines (callers now resolve
    directly to the canonical via the rename map)."""
    return ALIAS_RE.sub("", text)


def rebrand(text, fmap):
    """Apply all renames to a chunk of SQF (identifiers AND string-literal keys)."""
    # 1) function identifiers (longest first to avoid partial overlaps)
    for old in sorted(fmap, key=len, reverse=True):
        text = re.sub(r'\b' + re.escape(old) + r'\b', fmap[old], text)
    # 2) GRS_ runtime token / local var
    text = text.replace("_GRS_UnifiedRuntime", "_WaldoEco_UnifiedRuntime")
    text = re.sub(r'\bGRS_', 'WaldoEco_', text)
    # 3) other system-prefixed globals + string keys (e.g. RS_IsResourceCrate,
    #    US_ModulePurgedForJIP, BS_MenuInjected). These appear both bare and in
    #    "double quotes"; a token replace covers both since they share the token.
    for sysm, (_, seg) in SYSTEMS.items():
        # avoid re-touching the already-renamed *_fnc_ (now Waldo_fnc_...) tokens
        text = re.sub(r'\b' + sysm + r'_(?!fnc_)([A-Za-z0-9]+)',
                      lambda mm, seg=seg: f"WaldoEco{seg[3:]}_{mm.group(1)}", text)
    # 4) user-facing brand strings
    text = text.replace("Grand Resource System", "Waldos Economy Systems")
    text = text.replace("GRS Testing Notice Hook", "Waldos Economy Systems Testing Notice Hook")
    return text


HEADER = """/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * {system} system - {fn}
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as {callable} via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */
"""


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)
    src = sys.argv[1]
    with open(src, "r", encoding="utf-8", errors="replace") as fh:
        lines = fh.readlines()
    init_line = next(l for l in lines if l.strip().startswith('init="'))
    code = decode_init(init_line)

    assert code.count("{") == code.count("}"), \
        f"brace imbalance after decode: {{={code.count('{')} }}={code.count('}')}"

    inner, trailing = strip_runtime_wrapper(code)
    funcs, bootstrap_body = split_statements(inner)
    print(f"Extracted {len(funcs)} functions")
    counts = {}
    for sysm, _, _ in funcs:
        counts[sysm] = counts.get(sysm, 0) + 1
    print("Per system:", counts)

    fmap = build_rename_map(funcs, inner)
    bootstrap_body = strip_alias_statements(bootstrap_body)

    # write per-function files
    for sysm, name, block in funcs:
        directory, seg = SYSTEMS[sysm]
        callable_name = fmap[f"{sysm}_fnc_{name}"]
        out_dir = os.path.join(OUT_ROOT, directory)
        os.makedirs(out_dir, exist_ok=True)
        body = rebrand(block, fmap).rstrip()
        # a registered CfgFunctions file is `_this call (compile preprocess file)`
        # of its CONTENTS, so the file body must be the function statements, not
        # a `{ }` literal. Strip the outermost braces.
        b = body.strip()
        if b.startswith("{") and b.endswith("}"):
            b = b[1:-1].strip("\n")
        header = HEADER.format(system=seg, fn=name, callable=callable_name)
        text = header + "\n" + b + "\n"
        text = "\n".join(line.rstrip() for line in text.split("\n"))
        with open(os.path.join(out_dir, f"{name}.sqf"), "w", encoding="utf-8") as fh:
            fh.write(text)

    # write economyInit.sqf  (guards + bootstrap + trailing setVariable, minus the
    # now-redundant function definitions which CfgFunctions preloads)
    boot = rebrand(bootstrap_body, fmap)
    trail = rebrand(trailing, fmap)
    # the trailing chunk was: '; setVariable[...]; [] spawn _WaldoEco_UnifiedRuntime;'
    # we no longer wrap in a spawnable local; the registered Waldo_fnc_EcoInit runs
    # the bootstrap directly (callers use: [] spawn Waldo_fnc_EcoInit).
    trail = trail.replace("[] spawn _WaldoEco_UnifiedRuntime;", "")
    trail = re.sub(r'^\s*;\s*', '', trail)
    init_header = """/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * Bootstrap for Waldos Economy Systems (Resource / Research / Build / Buy + Ground Command).
 *
 * Runs on all machines; self-branches on isServer / hasInterface for the server
 * authority loops vs. the client Zeus-menu injection and local action loops.
 * Opt-in: gated by Waldo_Economy_Enable in init.sqf. Safe to call once per machine.
 *
 * Example:
 * [] spawn Waldo_fnc_EcoInit;
 */
"""
    out = init_header + "\n" + trail.strip() + "\n\n" + boot.strip() + "\n"
    out = "\n".join(line.rstrip() for line in out.split("\n"))
    # collapse runs of 3+ blank lines (left behind by stripped function defs) to 1
    out = re.sub(r'\n[ \t]*\n([ \t]*\n)+', "\n\n", out)
    with open(os.path.join(OUT_ROOT, "economyInit.sqf"), "w", encoding="utf-8") as fh:
        fh.write(out)

    # emit CfgFunctions block
    print("\n--- CfgFunctions block (insert into WaldosFunctions.sqf) ---\n")
    by_sys = {}
    for sysm, name, _ in funcs:
        by_sys.setdefault(sysm, []).append(name)
    lines_out = []
    for sysm in ["US", "RS", "RC", "BS", "BU", "GC"]:
        directory, seg = SYSTEMS[sysm]
        lines_out.append(f"        class {seg}")
        lines_out.append("        {")
        if sysm == "US":
            lines_out.append("            class EcoInit {")
            lines_out.append('                file = "MissionScripts\\EconomySystems\\economyInit.sqf";')
            lines_out.append("            };")
        for name in by_sys.get(sysm, []):
            lines_out.append(f"            class {seg}_{name} {{")
            lines_out.append(f'                file = "MissionScripts\\EconomySystems\\{directory}\\{name}.sqf";')
            lines_out.append("            };")
        lines_out.append("        };")
    cfg = "\n".join(lines_out)
    with open(os.path.join(OUT_ROOT, "_cfgfunctions_block.txt"), "w", encoding="utf-8") as fh:
        fh.write(cfg + "\n")
    print(f"(written to {os.path.join(OUT_ROOT, '_cfgfunctions_block.txt')})")


if __name__ == "__main__":
    main()
