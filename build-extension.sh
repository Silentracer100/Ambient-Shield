#!/usr/bin/env bash
# build-extension.sh
# Builds the Next.js app as a static export, renames _next -> next_assets,
# extracts inline scripts to external JS files (to comply with MV3 CSP),
# injects a route-fix script to prevent Next.js 404 client-side exceptions,
# and copies everything into extension/.
#
# Run from the project root:  chmod +x build-extension.sh && ./build-extension.sh

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIST_DIR="$ROOT/dist"
EXT_DIR="$ROOT/extension"
MANIFEST_PATH="$EXT_DIR/manifest.json"

PRESERVE=(
  "manifest.json"
  "background.js"
  "content.js"
  "content.css"
  "content-firewall.js"
  "content-firewall.css"
  "block-rules.json"
  "blocked.html"
  "dashboard.html"
  "dashboard.js"
  "popup.html"
  "popup.js"
  "generate-icons.html"
  "icon16.svg"
  "icon48.svg"
  "icon128.svg"
  "route-fix.js"
)

echo ""
echo "Ambient Shield -- Extension Builder"
echo "--------------------------------------"

# -- Step 1: Static export -----------------------------------------------------
echo ""
echo "[1/4] Building Next.js static export..."
cd "$ROOT"
npm run build
echo "Build complete -> dist/"

# -- Step 2: Rename _next -> next_assets inside dist/ --------------------------
echo ""
echo "[2/4] Renaming _next -> next_assets (Chrome extension requirement)..."

if [ -d "$DIST_DIR/_next" ]; then
  rm -rf "$DIST_DIR/next_assets"
  mv "$DIST_DIR/_next" "$DIST_DIR/next_assets"
fi

echo "  Updating asset references..."
node -e '
const fs = require("fs");
const path = require("path");

function walk(dir) {
  const files = fs.readdirSync(dir);
  for (const f of files) {
    const full = path.join(dir, f);
    if (fs.statSync(full).isDirectory()) {
      walk(full);
    } else if (/\.(html|js|css|txt)$/i.test(f)) {
      let content = fs.readFileSync(full, "utf8");
      if (content.includes("_next")) {
        content = content
          .replace(/\/_next\//g, "/next_assets/")
          .replace(/"_next\//g, "\"/next_assets/")
          .replace(/'_next\//g, "\x27/next_assets/")
          .replace(/\._next\//g, "/next_assets/")
          .replace(/\.\/next_assets\//g, "/next_assets/");
        fs.writeFileSync(full, content, "utf8");
      }
    }
  }
}
walk(process.argv[1]);
' "$DIST_DIR"
echo "  References updated."

# -- Step 3: Extract Inline Scripts & Inject Route Fix --------------------------
echo ""
echo "[3/4] Extracting inline scripts and injecting Next.js router fix..."

# Create route-fix.js
cat << 'EOF' > "$DIST_DIR/route-fix.js"
// Next.js router fix for Chrome Extensions
// Next.js expects URLs like /analyze/, not /analyze/index.html
if (window.location.pathname.endsWith('.html')) {
  var newPath = window.location.pathname.replace(/\/[^\/]+\.html$/, '/');
  if (newPath === '') newPath = '/';
  window.history.replaceState(null, '', newPath);
}
EOF

node -e '
const fs = require("fs");
const path = require("path");

function processHtml(dir) {
  const files = fs.readdirSync(dir);
  for (const f of files) {
    const full = path.join(dir, f);
    if (fs.statSync(full).isDirectory()) {
      processHtml(full);
    } else if (f.endsWith(".html")) {
      let content = fs.readFileSync(full, "utf8");
      const baseName = path.basename(f, ".html");
      const dirName = path.dirname(full);
      
      const pattern = /<script(?![^>]*src=)(?![^>]*type=["\x27]application\/json["\x27])[^>]*>([\s\S]*?)<\/script>/gi;
      let counter = 1;
      let injected = [];
      let match;
      
      const original = content;
      content = content.replace(pattern, (fullMatch, scriptContent) => {
        const trimmed = scriptContent.trim();
        if (!trimmed) return "";
        const scriptName = `${baseName}-inline-${counter}.js`;
        fs.writeFileSync(path.join(dirName, scriptName), trimmed, "utf8");
        injected.push(`<script src="./${scriptName}"></script>`);
        counter++;
        return "";
      });
      
      if (injected.length > 0) {
        content = content.replace(/<\/body>/i, `</body>${injected.join("")}`);
      }
      
      const routeFixTag = "<script src=\"/route-fix.js\"></script>";
      content = content.replace(/<head>/i, `<head>${routeFixTag}`);
      content = content.replace(/ async=""/gi, "").replace(/ async\b/gi, "");
      
      fs.writeFileSync(full, content, "utf8");
    }
  }
}
processHtml(process.argv[1]);
' "$DIST_DIR"

# -- Step 4: Copy dist/ -> extension/ ------------------------------------------
echo ""
echo "[4/4] Copying dist/ -> extension/..."

rm -rf "$EXT_DIR/_next" "$EXT_DIR/next_assets"

declare -A PRESERVE_MAP
for f in "${PRESERVE[@]}"; do
  PRESERVE_MAP["$f"]=1
done

while IFS= read -r -d '' src; do
  rel="${src#$DIST_DIR/}"
  dest="$EXT_DIR/$rel"
  dest_dir="$(dirname "$dest")"

  if [[ "$rel" != */* ]]; then
    filename="$(basename "$rel")"
    if [[ -n "${PRESERVE_MAP[$filename]+_}" ]]; then
      continue
    fi
  fi

  mkdir -p "$dest_dir"
  cp "$src" "$dest"
done < <(find "$DIST_DIR" -type f -print0)

echo "Files copied."
echo ""
echo "Done! Reload the extension in Chrome."
