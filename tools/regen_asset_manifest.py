#!/usr/bin/env python3
"""Linux equivalent of tools/generate_asset_inventory.ps1 + generate_asset_triage.ps1.

Regenerates docs/assets/asset_manifest.csv, asset_manifest.json, INVENTORY.md,
asset_actions.csv and REPLACEMENT_PLAN.md from the files on disk plus the
curated provenance_overrides.csv / asset_action_overrides.csv.
"""
import csv
import datetime
import hashlib
import os
import sys

PROJECT = sys.argv[1] if len(sys.argv) > 1 else os.path.expanduser("~/workspace/game2d")
DOCS = os.path.join(PROJECT, "docs", "assets")
EXCLUDED_TOP = {".godot", "node_modules", "dist", "build", "docs"}
SOURCE_EXTS = {".png": "texture", ".wav": "sfx", ".ogg": "music"}


def sha256_of(path):
    h = hashlib.sha256()
    with open(path, "rb") as fh:
        for chunk in iter(lambda: fh.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


def read_overrides(path):
    lookup = {}
    if os.path.isfile(path):
        with open(path, encoding="utf-8-sig", newline="") as fh:
            for row in csv.DictReader(fh):
                if row.get("path"):
                    lookup[row["path"].replace("\\", "/")] = row
    return lookup


def iter_source_assets():
    for root, dirs, files in os.walk(PROJECT):
        rel_root = os.path.relpath(root, PROJECT)
        top = rel_root.split(os.sep)[0]
        if top in EXCLUDED_TOP:
            dirs[:] = []
            continue
        for f in sorted(files):
            ext = os.path.splitext(f)[1].lower()
            if ext in SOURCE_EXTS:
                yield os.path.join(root, f), ext


def main():
    provenance = read_overrides(os.path.join(DOCS, "provenance_overrides.csv"))
    # reference text for the `referenced` flag
    ref_text = []
    for sub in ("scripts", "systems", "ui"):
        d = os.path.join(PROJECT, sub)
        if os.path.isdir(d):
            for root, _, files in os.walk(d):
                for f in files:
                    if f.endswith(".gd"):
                        with open(os.path.join(root, f), encoding="utf-8", errors="replace") as fh:
                            ref_text.append(fh.read())
    for sub in ("scenes",):
        d = os.path.join(PROJECT, sub)
        if os.path.isdir(d):
            for root, _, files in os.walk(d):
                for f in files:
                    if f.endswith(".tscn"):
                        with open(os.path.join(root, f), encoding="utf-8", errors="replace") as fh:
                            ref_text.append(fh.read())
    with open(os.path.join(PROJECT, "project.godot"), encoding="utf-8", errors="replace") as fh:
        ref_text.append(fh.read())
    reference_text = "\n".join(ref_text)

    records = []
    for abs_path, ext in iter_source_assets():
        rel = os.path.relpath(abs_path, PROJECT).replace(os.sep, "/")
        parts = rel.split("/")
        category = parts[1] if len(parts) > 2 and parts[0] == "assets" else "_root"
        prov = provenance.get(rel)
        resource_path = "res://" + rel
        is_ref = resource_path in reference_text
        records.append({
            "path": rel,
            "kind": SOURCE_EXTS[ext],
            "category": category,
            "bytes": os.path.getsize(abs_path),
            "sha256": sha256_of(abs_path),
            "referenced": is_ref,
            "provenance_status": prov["provenance_status"] if prov and prov.get("provenance_status") else "QUARANTINE",
            "license_spdx": prov["license_spdx"] if prov and prov.get("license_spdx") else "UNKNOWN",
            "author": prov.get("author", "") if prov else "",
            "source_page": prov.get("source_page", "") if prov else "",
            "intended_use": (prov.get("intended_use") if prov and prov.get("intended_use")
                             else ("current-runtime" if is_ref else "unassigned")),
            "notes": (prov.get("notes") if prov and prov.get("notes")
                      else "Existing file; origin and redistribution rights not yet verified."),
        })
    records.sort(key=lambda r: r["path"])

    # duplicate groups
    by_hash = {}
    for r in records:
        by_hash.setdefault(r["sha256"], []).append(r["path"])
    dup_lookup = {}
    for h, paths in by_hash.items():
        if len(paths) > 1:
            gid = "dup-" + h[:12]
            for p in paths:
                dup_lookup[p] = gid

    manifest_fields = ["path", "kind", "category", "bytes", "sha256", "duplicate_group",
                       "referenced", "provenance_status", "license_spdx", "author",
                       "source_page", "intended_use", "notes"]
    manifest = []
    for r in records:
        m = dict(r)
        m["duplicate_group"] = dup_lookup.get(r["path"], "")
        manifest.append({k: m[k] for k in manifest_fields})

    import json as _json
    with open(os.path.join(DOCS, "asset_manifest.csv"), "w", encoding="utf-8-sig", newline="") as fh:
        w = csv.DictWriter(fh, fieldnames=manifest_fields, quoting=csv.QUOTE_ALL,
                           lineterminator="\n")
        w.writeheader()
        w.writerows(manifest)
    with open(os.path.join(DOCS, "asset_manifest.json"), "w", encoding="utf-8-sig") as fh:
        _json.dump(manifest, fh, indent=1)

    # INVENTORY.md
    today = datetime.date.today().isoformat()
    ref_count = sum(1 for r in manifest if r["referenced"])
    ver_count = sum(1 for r in manifest if r["provenance_status"] == "VERIFIED")
    dup_groups = [(h, ps) for h, ps in by_hash.items() if len(ps) > 1]
    lines = ["# Asset inventory", "",
             "> Generated by `tools/regen_asset_manifest.py` (Linux port of `tools/generate_asset_inventory.ps1`).",
             "", "Generated: " + today, "", "## Gate status", "",
             "- Source assets: %d" % len(manifest),
             "- Referenced by current scripts/scenes: %d" % ref_count,
             "- Unreferenced: %d" % (len(manifest) - ref_count),
             "- Duplicate hash groups: %d (%d files)" % (len(dup_groups), sum(len(ps) for _, ps in dup_groups)),
             "- Verified provenance: %d" % ver_count,
             "- Quarantined/unknown: %d" % (len(manifest) - ver_count), ""]
    if ver_count:
        lines += ["`VERIFIED` assets are original project-generated content (CC0-1.0) or have a provenance receipt; they are cleared for distributable builds.",
                  "`QUARANTINE` files support local development only.", ""]
    else:
        lines += ["All current assets remain in place so the playable baseline is preserved. `QUARANTINE` means the file can support local development but must not be included in a distributable build until its source and license are verified or it is replaced.", ""]
    lines += ["## By category", "", "| Category | Files | Referenced | Bytes |", "|---|---:|---:|---:|"]
    cats = {}
    for r in manifest:
        cats.setdefault(r["category"], []).append(r)
    for cat in sorted(cats):
        rs = cats[cat]
        lines.append("| %s | %d | %d | %d |" % (cat, len(rs),
                                                sum(1 for r in rs if r["referenced"]),
                                                sum(r["bytes"] for r in rs)))
    lines += ["", "## Exact duplicate groups", ""]
    if not dup_groups:
        lines.append("No byte-identical source assets were found.")
    else:
        for h, ps in sorted(dup_groups):
            lines += ["### dup-" + h[:12], ""]
            lines += ["- `%s`" % p for p in sorted(ps)] + [""]
    lines += ["## Files and ownership", "",
              "- `asset_manifest.csv`: review-friendly source inventory.",
              "- `asset_manifest.json`: machine-readable copy for later validators and build gates.",
              "- `provenance_overrides.csv`: curated source/license data preserved across regeneration.",
              "- `docs/ASSET_PLAN.md`: admission policy and candidate packages."]
    with open(os.path.join(DOCS, "INVENTORY.md"), "w", encoding="utf-8") as fh:
        fh.write("\n".join(lines) + "\n")

    # triage -> asset_actions.csv + REPLACEMENT_PLAN.md
    action_overrides = read_overrides(os.path.join(DOCS, "asset_action_overrides.csv"))
    owners = {"music": "audio", "sfx": "audio", "hunter": "character-art",
              "monsters": "character-art", "tilesets": "environment-art",
              "items": "gameplay-art", "buildings": "gameplay-art", "fx": "vfx"}
    import re as _re
    actions = []
    for r in sorted(manifest, key=lambda x: x["path"]):
        ov = action_overrides.get(r["path"])
        leaf = os.path.splitext(os.path.basename(r["path"]))[0]
        is_scratch = bool(_re.match(r"^(test_|preview_|row_\d+$)|(_check$)", leaf))
        if r["referenced"]:
            d_action, d_prio = "VERIFY_OR_REPLACE", "P0"
            d_rat = "Runtime dependency with unknown provenance; verify source/license or replace before distribution."
        elif is_scratch:
            d_action, d_prio = "REMOVE_AFTER_REFERENCE_AUDIT", "P3"
            d_rat = "Unreferenced preview/test/intermediate file; remove only after snapshot and visual/reference audit."
        elif r["duplicate_group"]:
            d_action, d_prio = "DEDUP_AFTER_REFERENCE_AUDIT", "P2"
            d_rat = "Unreferenced byte-identical duplicate; retain until canonical path and external references are reviewed."
        else:
            d_action, d_prio = "HOLD_FOR_REVIEW", "P2"
            d_rat = "Unreferenced content with unknown provenance; decide future use before removal or replacement."
        if r["provenance_status"] == "VERIFIED":
            d_action, d_prio = "VERIFY_OR_REPLACE", "P0" if r["referenced"] else "P3"
            d_rat = ("Replaced with original project-generated CC0-1.0 asset (U4.2); "
                     "distributable. See docs/assets/receipts/.")
        actions.append({
            "path": r["path"], "referenced": r["referenced"],
            "provenance_status": r["provenance_status"],
            "action": ov["action"] if ov and ov.get("action") else d_action,
            "priority": ov["priority"] if ov and ov.get("priority") else d_prio,
            "owner": ov["owner"] if ov and ov.get("owner") else owners.get(r["category"], "art-tech-debt"),
            "replacement_target": (ov["replacement_target"] if ov and ov.get("replacement_target")
                                   else ("assets/game/%s/" % r["category"] if r["referenced"] else "")),
            "rationale": ov["rationale"] if ov and ov.get("rationale") else d_rat,
        })
    with open(os.path.join(DOCS, "asset_actions.csv"), "w", encoding="utf-8-sig", newline="") as fh:
        w = csv.DictWriter(fh, fieldnames=["path", "referenced", "provenance_status", "action",
                                           "priority", "owner", "replacement_target", "rationale"],
                           quoting=csv.QUOTE_ALL, lineterminator="\n")
        w.writeheader()
        w.writerows(actions)

    p0 = sum(1 for a in actions if a["priority"] == "P0")
    by_action, by_prio = {}, {}
    for a in actions:
        by_action[a["action"]] = by_action.get(a["action"], 0) + 1
        by_prio[a["priority"]] = by_prio.get(a["priority"], 0) + 1
    meanings = {"VERIFY_OR_REPLACE": "Verify author/source/license; otherwise create or admit a replacement.",
                "HOLD_FOR_REVIEW": "Potential future content; decide use before removal.",
                "DEDUP_AFTER_REFERENCE_AUDIT": "Choose canonical copy only after reference audit.",
                "REMOVE_AFTER_REFERENCE_AUDIT": "Scratch/preview candidate; remove in a separate reversible package."}
    rl = ["# Asset quarantine and replacement plan", "",
          "> Generated by `tools/regen_asset_manifest.py` (Linux port of `tools/generate_asset_triage.ps1`).",
          "", "Generated: " + today, "", "## Gate status", "",
          "- Assets classified: %d/%d" % (len(actions), len(manifest)),
          "- Runtime P0 assets: %d" % p0,
          "- Verified (distributable): %d" % ver_count, "",
          "## By action", "", "| Action | Files | Meaning |", "|---|---:|---|"]
    for name in sorted(by_action):
        rl.append("| %s | %d | %s |" % (name, by_action[name], meanings[name]))
    rl += ["", "## By priority", "", "| Priority | Files |", "|---|---:|"]
    for name in sorted(by_prio):
        rl.append("| %s | %d |" % (name, by_prio[name]))
    with open(os.path.join(DOCS, "REPLACEMENT_PLAN.md"), "w", encoding="utf-8") as fh:
        fh.write("\n".join(rl) + "\n")
    print("Regenerated: %d assets, %d referenced, %d verified." % (len(manifest), ref_count, ver_count))


if __name__ == "__main__":
    main()
