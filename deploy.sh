#!/usr/bin/env bash
set -euo pipefail

SITE_DIR="$(cd "$(dirname "$0")" && pwd)"
PAGES_DIR="${PAGES_DIR:-$SITE_DIR/../asen-blog-pages}"
HUGO_BIN="${HUGO_BIN:-$SITE_DIR/../hugo/bin/hugo}"
PAGES_URL="https://6pmpcripa6zf.github.io/asen-blog/"

die() {
  echo "deploy: $*" >&2
  exit 1
}

[ -x "$HUGO_BIN" ] || die "hugo not found: $HUGO_BIN"
[ -d "$PAGES_DIR/.git" ] || die "pages repo not found: $PAGES_DIR"

pages_real="$(realpath "$PAGES_DIR")"
expected_real="$(realpath "$SITE_DIR/../asen-blog-pages")"
[ "$pages_real" = "$expected_real" ] || die "unexpected pages dir: $PAGES_DIR"

echo "==> build"
"$HUGO_BIN" --source "$SITE_DIR" --destination "$SITE_DIR/public" --minify

echo "==> sync public -> pages"
rsync -a --delete --exclude=.git "$SITE_DIR/public/" "$PAGES_DIR/"

echo "==> commit source"
git -C "$SITE_DIR" add -A
if ! git -C "$SITE_DIR" diff --cached --quiet; then
  git -C "$SITE_DIR" commit -m "deploy $(date '+%Y-%m-%d %H:%M')"
else
  echo "source: nothing to commit"
fi
git -C "$SITE_DIR" push origin main

echo "==> commit pages"
git -C "$PAGES_DIR" add -A
if ! git -C "$PAGES_DIR" diff --cached --quiet; then
  git -C "$PAGES_DIR" commit -m "deploy $(date '+%Y-%m-%d %H:%M')"
else
  echo "pages: nothing to commit"
fi
git -C "$PAGES_DIR" push origin gh-pages

echo "==> done"
echo "$PAGES_URL"
