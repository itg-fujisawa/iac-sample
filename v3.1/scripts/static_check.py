#!/usr/bin/env python3
"""オフライン静的検査（terraform が無い環境でも実行可）
- 括弧・引用符の対応
- var.X が各 root の variables.tf に宣言されているか
- 旧 v2 の dr_enabled 参照が残っていないか
- 全 root が Terraform 1.5.7 / google 6.50.0 固定か
- tfvars のキーが variables に存在するか
"""
import os, re, sys, glob
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
STAGES = ["0-bootstrap", "1-org", "2-environments", "3-network", "4-data", "5-app-infra", "6-observability", "ci/terraform"]
errors = []

def strip(src):
    out, i, n = [], 0, len(src)
    while i < n:
        c = src[i]
        if c == '#' or src.startswith('//', i):
            while i < n and src[i] != '\n': i += 1
            continue
        if src.startswith('<<-EOT', i) or src.startswith('<<EOT', i):
            j = src.find('\n', i); k = re.search(r'\n\s*EOT\b', src[j:]); i = j + k.end(); out.append('""'); continue
        if c == '"':
            j = i + 1; depth = 0
            while j < n:
                if src[j] == '\\': j += 2; continue
                if src.startswith('${', j): depth += 1; j += 2; continue
                if src[j] == '}' and depth: depth -= 1; j += 1; continue
                if src[j] == '"' and not depth: break
                j += 1
            out.append('"' + src[i+1:j] + '"'); i = j + 1; continue
        out.append(c); i += 1
    return ''.join(out)

for st in STAGES:
    d = os.path.join(ROOT, st)
    tfs = sorted(glob.glob(os.path.join(d, "*.tf")))
    declared, body = set(), ""
    for f in tfs:
        s = open(f, encoding="utf-8").read()
        body += s
        declared |= set(re.findall(r'^variable\s+"([^"]+)"', s, re.M))
        st_ = strip(s)
        for o, c in ["{}", "[]", "()"]:
            if st_.count(o) != st_.count(c):
                errors.append(f"{f}: unbalanced {o}{c} ({st_.count(o)} vs {st_.count(c)})")
    used = set(re.findall(r'\bvar\.([a-zA-Z0-9_]+)', body))
    for u in sorted(used - declared):
        errors.append(f"{st}: var.{u} is not declared")
    if "dr_enabled" in body:
        errors.append(f"{st}: legacy dr_enabled reference remains")
    if '= 1.5.7' not in body or '= 6.50.0' not in body:
        errors.append(f"{st}: version pin missing")
    # tfvars keys
    stage_name = "ci" if st == "ci/terraform" else st
    for tv in glob.glob(os.path.join(ROOT, "environments", "*", f"{stage_name}.tfvars")):
        keys = set(re.findall(r'^([a-z_][a-z0-9_]*)\s*=', open(tv, encoding="utf-8").read(), re.M))
        for k in sorted(keys - declared):
            errors.append(f"{os.path.relpath(tv, ROOT)}: '{k}' is not a variable of {st}")

if errors:
    print("\n".join(errors)); sys.exit(1)
print(f"static check OK ({len(STAGES)} roots)")
