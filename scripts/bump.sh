#!/usr/bin/env bash
# Bump a pinned binary package to its latest upstream release
# (version + per-platform hashes in packages/<pkg>.nix).
# Usage: scripts/bump.sh [muse-code|muse-acp|photocraft|pdfcraft|beads-rust]
# With no package, bumps all of them (continues past individual failures
# and reports them at the end).
set -euo pipefail

# Retry flaky release downloads (observed: minutes-long windows where GitHub
# serves 404s for assets that exist before and after). --retry-all-errors
# is what makes 404s retryable at all; the delay spaces attempts across
# short blips. Longer outages still fail cleanly — rerunning is safe
# because already-bumped packages exit early with no changes.
curl() { command curl --retry 4 --retry-delay 5 --retry-all-errors "$@"; }

if [ $# -eq 0 ]; then
  failed=""
  for p in muse-code muse-acp photocraft pdfcraft beads-rust; do
    "$0" "$p" || failed="$failed $p"
  done
  if [ -n "$failed" ]; then
    echo "failed:$failed" >&2
    exit 1
  fi
  exit 0
fi

pkg="${1:?usage: bump.sh [muse-code|muse-acp|photocraft|pdfcraft|beads-rust]}"
nixfile="packages/${pkg}.nix"
case "$pkg" in
  muse-code|muse-acp|photocraft|pdfcraft) ;;
  beads-rust) nixfile="packages/beads_rust.nix" ;;
  *) echo "unknown package: $pkg" >&2; exit 1 ;;
esac
[ -f "$nixfile" ] || { echo "missing file: $nixfile" >&2; exit 1; }

current="$(sed -n 's/^[[:space:]]*version = "\(.*\)";/\1/p' "$nixfile" | head -1)"

# Per-package release metadata. The asset lists are in the same order as
# the `hash = ...` lines in the .nix file, with {VER} as the placeholder.
case "$pkg" in
  muse-code)
    latest="$(curl -m 20 -fsSL https://api.meta.ai/muse-code/channels/muse-stable | python3 -c 'import json,sys; print(json.load(sys.stdin)["version"])')"
    base="https://lookaside.facebook.com/lookaside/muse/download/?channel=muse&version=${latest}"
    manifest="$(curl -m 60 -fsSL "${base}&file=manifest.json")"
    mapfile -t assets < <(printf '%s\n' muse-aarch64-macos muse-aarch64-linux muse-x86-macos muse-x86-linux)
    hexes="$(python3 - "$manifest" "${assets[@]}" <<'EOF'
import json, sys
m = json.loads(sys.argv[1])
arts = list(m["artifacts"].values()) if isinstance(m.get("artifacts"), dict) else m["artifacts"]
for want in sys.argv[2:]:
    for a in arts:
        if a["url"].endswith("file=" + want):
            print(a["checksum"])
            break
    else:
        sys.exit("missing artifact for " + want)
EOF
)"
    ;;
  muse-acp)
    repo="BrokkAi/muse-acp"
    latest="$(curl -m 20 -fsSL "https://api.github.com/repos/${repo}/releases/latest" | python3 -c 'import json,sys; print(json.load(sys.stdin)["tag_name"].lstrip("v"))')"
    base="https://github.com/${repo}/releases/download/v${latest}"
    # NOTE: unlike the other projects here, muse-acp keeps a "v" prefix in
    # the file names themselves (muse-acp-v0.18.0-...), not just the tag.
    mapfile -t assets < <(printf '%s\n' muse-acp-v{VER}-aarch64-apple-darwin.tar.gz muse-acp-v{VER}-aarch64-unknown-linux-gnu.tar.gz muse-acp-v{VER}-x86_64-apple-darwin.tar.gz muse-acp-v{VER}-x86_64-unknown-linux-gnu.tar.gz)
    hexes=""
    for a in "${assets[@]}"; do
      a="${a//\{VER\}/$latest}"
      hexes+="$(curl -m 30 -fsSL "${base}/${a}.sha256" | awk '{print $1}')"$'\n'
    done
    ;;
  photocraft|pdfcraft)
    repo="storytold/${pkg}"
    latest="$(curl -m 20 -fsSL "https://api.github.com/repos/${repo}/releases/latest" | python3 -c 'import json,sys; print(json.load(sys.stdin)["tag_name"].lstrip("v"))')"
    sums="$(curl -m 30 -fsSL "https://github.com/${repo}/releases/download/v${latest}/SHA256SUMS.txt")"
    # Order must match the `hash = ...` lines in the .nix file: the two
    # Linux tarballs, the shared macOS DMG twice (one entry per arch),
    # then the macOS CLI zip (darwinCliSrc).
    mapfile -t assets < <(printf '%s\n' "${pkg}-{VER}-linux-aarch64.tar.gz" "${pkg}-{VER}-linux-x86_64.tar.gz" "${pkg}-{VER}-macos-universal.dmg" "${pkg}-{VER}-macos-universal.dmg" "${pkg}-cli-{VER}-macos-universal.zip")
    hexes=""
    for a in "${assets[@]}"; do
      a="${a//\{VER\}/$latest}"
      # `|| true`: a renamed asset must surface as a hash-count mismatch
      # below, not a bare grep failure.
      hexes+="$(printf '%s' "$sums" | grep -F " $a" | head -1 | awk '{print $1}' || true)"$'\n'
    done
    ;;
  beads-rust)
    repo="Dicklesworthstone/beads_rust"
    latest="$(curl -m 20 -fsSL "https://api.github.com/repos/${repo}/releases/latest" | python3 -c 'import json,sys; print(json.load(sys.stdin)["tag_name"].lstrip("v"))')"
    base="https://github.com/${repo}/releases/download/v${latest}"
    mapfile -t assets < <(printf '%s\n' br-{VER}-darwin_arm64.tar.gz br-{VER}-linux_amd64.tar.gz)
    hexes=""
    for a in "${assets[@]}"; do
      a="${a//\{VER\}/$latest}"
      hexes+="$(curl -m 30 -fsSL "${base}/${a}.sha256" | awk '{print $1}')"$'\n'
    done
    ;;
esac

if [ "$latest" = "$current" ]; then
  echo "$pkg is already at the latest release ($current)"
  exit 0
fi
echo "$pkg: $current -> $latest"

# NOTE: the trailing newline matters — `read` silently skips a final
# line without one, and command substitution strips it.
mapfile -t sris < <(printf '%s\n' "$hexes" | while IFS= read -r h; do
  [ -n "$h" ] && nix hash convert --hash-algo sha256 --to sri "$h"
done)
want="$(printf '%s\n' "$hexes" | grep -c .)"
[ "${#sris[@]}" -eq "$want" ] || { echo "checksum conversion dropped lines" >&2; exit 1; }
python3 - "$nixfile" "$latest" "${sris[@]}" <<'EOF'
import re, sys
path, newver, *hashes = sys.argv[1:]
with open(path) as f:
    lines = f.readlines()
n_hash = sum(1 for ln in lines if re.match(r'\s*hash = "sha256-', ln))
assert n_hash == len(hashes), f"hash count mismatch: file has {n_hash}, got {len(hashes)}"
assert any(re.match(r'\s*version = "', ln) for ln in lines), "version line not found"
hi = 0
out = []
for ln in lines:
    if re.match(r'\s*version = "', ln):
        out.append(re.sub(r'version = "[^"]*"', f'version = "{newver}"', ln, count=1))
    elif re.match(r'\s*hash = "sha256-', ln):
        out.append(re.sub(r'hash = "sha256-[^"]*"', f'hash = "{hashes[hi]}"', ln, count=1))
        hi += 1
    else:
        out.append(ln)
with open(path, "w") as f:
    f.writelines(out)
EOF

nix-instantiate --parse "$nixfile" >/dev/null
echo "patched $nixfile; next: git add $nixfile && just check, then just switch"
