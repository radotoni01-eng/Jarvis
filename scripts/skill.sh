#!/usr/bin/env bash
# Jarvis Skill-Verwaltung (OmniRoute-Skills)
# Kopiert Skill-Ordner zwischen integrations/omniroute/skills/ und .claude/skills/.
# Keine Downloads, keine Installation.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ACTIVE="$ROOT/.claude/skills"
LIB="$ROOT/integrations/omniroute/skills"

usage() {
  cat <<'EOF'
Verwendung: scripts/skill.sh <befehl> [argumente]

  list                  Aktive Skills anzeigen
  available             Alle verfügbaren Skills mit Status
  info <name>           Beschreibung eines Skills
  activate <name>...    Skill(s) aktivieren (nach .claude/skills/)
  deactivate <name>...  Skill(s) deaktivieren (Original bleibt erhalten)

Skills in restricted/ brauchen --force (installieren Fremdcode oder öffnen Netzwerkzugänge).
OmniRoute-Skills funktionieren nur, wenn ein OmniRoute-Server erreichbar ist.
Nach dem Aktivieren eine neue Claude-Code-Sitzung starten.
EOF
}

find_src() { for b in library restricted; do [ -f "$LIB/$b/$1/SKILL.md" ] && { echo "$LIB/$b/$1"; return 0; }; done; return 0; }
desc_of() { awk '/^---$/{n++; next} n==1 && /^description:/{sub(/^description:[ ]*/,""); gsub(/^"|"$/,""); print; exit}' "$1/SKILL.md"; }

cmd="${1:-}"; shift || true
case "$cmd" in
  list)
    echo "Aktive Skills:"
    for d in "$ACTIVE"/*/; do [ -d "$d" ] && echo "  - $(basename "$d")"; done; true ;;
  available)
    for b in library restricted; do
      for d in "$LIB/$b"/*/; do
        n="$(basename "$d")"; tag=""; [ "$b" = restricted ] && tag=" [eingeschränkt]"; [ -d "$ACTIVE/$n" ] && tag="$tag [aktiv]"
        printf '%-24s%s\n' "$n" "$tag"
      done
    done ;;
  info)
    [ $# -eq 1 ] || { usage; exit 1; }
    src="$(find_src "$1")"; [ -n "$src" ] || { echo "Unbekannter Skill: $1"; exit 1; }
    echo "Name:  $1"; echo "Ort:   ${src#$ROOT/}"; echo "Info:  $(desc_of "$src")" ;;
  activate)
    force=0; names=()
    for a in "$@"; do [ "$a" = "--force" ] && force=1 || names+=("$a"); done
    [ ${#names[@]} -ge 1 ] || { usage; exit 1; }
    mkdir -p "$ACTIVE"
    for n in "${names[@]}"; do
      src="$(find_src "$n")"
      if [ -z "$src" ]; then echo "✗ $n: nicht gefunden (scripts/skill.sh available)"; continue; fi
      if [ -e "$ACTIVE/$n" ]; then echo "• $n: bereits aktiv"; continue; fi
      if [[ "$src" == */restricted/* && $force -eq 0 ]]; then
        echo "⚠ $n: eingeschränkt (siehe integrations/omniroute/README.md). Mit --force trotzdem aktivieren."; continue
      fi
      cp -r "$src" "$ACTIVE/$n" && echo "✓ $n aktiviert"
    done ;;
  deactivate)
    [ $# -ge 1 ] || { usage; exit 1; }
    for n in "$@"; do
      if [ ! -d "$ACTIVE/$n" ]; then echo "• $n: nicht aktiv"; continue; fi
      src="$(find_src "$n")"
      if [ -z "$src" ]; then echo "⚠ $n: kein Original in integrations/ – nicht gelöscht (eigener Skill?)"; continue; fi
      if ! diff -rq "$src" "$ACTIVE/$n" >/dev/null; then echo "⚠ $n: aktive Version wurde verändert – nicht gelöscht."; continue; fi
      rm -r "$ACTIVE/$n" && echo "✓ $n deaktiviert"
    done ;;
  *) usage ;;
esac
