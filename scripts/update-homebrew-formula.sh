#!/bin/bash
# Usage: update-homebrew-formula.sh <version> <dist_dir> <tap_repo_url>
set -euo pipefail

VERSION="${1:?version required}"
DIST="${2:?dist dir required}"
TAP_REPO="${3:?tap repo URL required}"

sha_of() { shasum -a 256 "${DIST}/$1" | awk '{print $1}'; }

SHA_MACOS_ARM64=$(sha_of tgeraser-darwin-arm64)
SHA_MACOS_AMD64=$(sha_of tgeraser-darwin-amd64)
SHA_LINUX_ARM64=$(sha_of tgeraser-linux-arm64)
SHA_LINUX_AMD64=$(sha_of tgeraser-linux-amd64)

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

git clone "$TAP_REPO" "$TMPDIR/tap"
cp packaging/homebrew/tgeraser.rb "$TMPDIR/tap/Formula/tgeraser.rb"

sed -i.bak \
  -e "s/VERSION_PLACEHOLDER/${VERSION}/g" \
  -e "s/SHA256_MACOS_ARM64/${SHA_MACOS_ARM64}/g" \
  -e "s/SHA256_MACOS_AMD64/${SHA_MACOS_AMD64}/g" \
  -e "s/SHA256_LINUX_ARM64/${SHA_LINUX_ARM64}/g" \
  -e "s/SHA256_LINUX_AMD64/${SHA_LINUX_AMD64}/g" \
  "$TMPDIR/tap/Formula/tgeraser.rb"
rm -f "$TMPDIR/tap/Formula/tgeraser.rb.bak"

cd "$TMPDIR/tap"
git config user.name "github-actions[bot]"
git config user.email "github-actions[bot]@users.noreply.github.com"
git add Formula/tgeraser.rb
git commit -m "tgeraser ${VERSION}" || true
git push

echo "Updated homebrew-tap Formula/tgeraser.rb to v${VERSION}"
