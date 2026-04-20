#!/bin/sh
set -eu

REPO="en9inerd/go-tgeraser"
BIN_NAME="tgeraser"
INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"
VERSION="${VERSION:-latest}"

log() { printf '%s\n' "$*" >&2; }
err() { log "error: $*"; exit 1; }

command -v curl >/dev/null 2>&1 || err "curl required"
command -v tar >/dev/null 2>&1 || true

OS=$(uname -s | tr '[:upper:]' '[:lower:]')
case "$OS" in
  linux|darwin) ;;
  *) err "unsupported OS: $OS" ;;
esac

ARCH=$(uname -m)
case "$ARCH" in
  x86_64|amd64) ARCH=amd64 ;;
  aarch64|arm64) ARCH=arm64 ;;
  *) err "unsupported arch: $ARCH" ;;
esac

ASSET="${BIN_NAME}-${OS}-${ARCH}"

if [ "$VERSION" = "latest" ]; then
  BASE_URL="https://github.com/${REPO}/releases/latest/download"
else
  case "$VERSION" in
    v*) TAG="$VERSION" ;;
    *)  TAG="v$VERSION" ;;
  esac
  BASE_URL="https://github.com/${REPO}/releases/download/${TAG}"
fi

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

log "downloading $ASSET from $BASE_URL"
curl -fsSL -o "$TMP_DIR/$BIN_NAME" "$BASE_URL/$ASSET" \
  || err "download failed: $BASE_URL/$ASSET"

log "downloading SHA256SUMS"
if curl -fsSL -o "$TMP_DIR/SHA256SUMS" "$BASE_URL/SHA256SUMS"; then
  EXPECTED=$(grep " ${ASSET}$" "$TMP_DIR/SHA256SUMS" | awk '{print $1}')
  [ -n "$EXPECTED" ] || err "checksum not found for $ASSET"

  if command -v sha256sum >/dev/null 2>&1; then
    ACTUAL=$(sha256sum "$TMP_DIR/$BIN_NAME" | awk '{print $1}')
  elif command -v shasum >/dev/null 2>&1; then
    ACTUAL=$(shasum -a 256 "$TMP_DIR/$BIN_NAME" | awk '{print $1}')
  else
    err "sha256sum or shasum required for verification"
  fi

  [ "$ACTUAL" = "$EXPECTED" ] || err "checksum mismatch: expected $EXPECTED, got $ACTUAL"
  log "checksum verified"
else
  log "warning: SHA256SUMS unavailable, skipping verification"
fi

chmod +x "$TMP_DIR/$BIN_NAME"

if [ -w "$INSTALL_DIR" ]; then
  mv "$TMP_DIR/$BIN_NAME" "$INSTALL_DIR/$BIN_NAME"
else
  log "installing to $INSTALL_DIR (requires sudo)"
  sudo mv "$TMP_DIR/$BIN_NAME" "$INSTALL_DIR/$BIN_NAME"
fi

log "installed $BIN_NAME to $INSTALL_DIR/$BIN_NAME"
"$INSTALL_DIR/$BIN_NAME" --version 2>/dev/null || true
