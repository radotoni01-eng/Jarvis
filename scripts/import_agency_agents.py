"""Convert agency-agents into a Claude Code project layout for Jarvis.

Only touches frontmatter lines `name:` and `color:`; the body is copied verbatim.
Usage: python3 -I build.py <src_repo> <dest_project>
"""
import colorsys, json, os, re, sys

src, dest = sys.argv[1], sys.argv[2]
CLAUDE_COLORS = {"red": 0, "orange": 30, "yellow": 55, "green": 120, "cyan": 185, "blue": 220, "purple": 275, "pink": 325}
ALIASES = {"teal": "cyan", "indigo": "blue", "amber": "yellow", "violet": "purple", "gold": "yellow",
           "slate": "blue", "navy": "blue", "magenta": "pink", "lime": "green", "emerald": "green",
           "rose": "pink", "sky": "cyan", "black": "blue", "gray": "blue", "grey": "blue", "brown": "orange"}

# Core team that is active immediately (.claude/agents/)
CORE = [
    "specialized-chief-of-staff", "agents-orchestrator",
    "research-synthesist", "academic-psychologist", "academic-statistician", "academic-historian",
    "academic-anthropologist", "academic-narratologist", "healthcare-clinical-evidence-agent",
    "language-translator", "personal-growth-mentor",
    "project-management-meeting-notes-specialist", "support-executive-summary-generator",
    "engineering-senior-developer", "engineering-code-reviewer", "engineering-minimal-change-engineer",
    "engineering-prompt-engineer", "engineering-ai-engineer", "engineering-technical-writer",
    "engineering-git-workflow-master", "testing-reality-checker", "security-ai-generated-code-auditor",
]
# Agents whose work depends on software/accounts a Linux cloud container does not have
RESTRICTED = {
    "blender-addon-engineer": "Benötigt Blender (Desktop-Programm)",
    "game-audio-engineer": "Benötigt FMOD/Wwise (Desktop-Programme)",
    "godot-gameplay-scripter": "Godot-Engine nicht installiert; Code nur schreibbar, nicht testbar",
    "godot-multiplayer-engineer": "Godot-Engine nicht installiert; Code nur schreibbar, nicht testbar",
    "godot-shader-developer": "Godot-Engine nicht installiert; Shader nicht testbar",
    "roblox-avatar-creator": "Benötigt Roblox Studio (Windows/macOS)",
    "roblox-experience-designer": "Benötigt Roblox Studio (Windows/macOS)",
    "roblox-systems-scripter": "Benötigt Roblox Studio (Windows/macOS)",
    "unity-architect": "Benötigt Unity Editor",
    "unity-editor-tool-developer": "Benötigt Unity Editor",
    "unity-multiplayer-engineer": "Benötigt Unity Editor + Unity Gaming Services",
    "unity-shader-graph-artist": "Benötigt Unity Editor",
    "unreal-multiplayer-architect": "Benötigt Unreal Engine",
    "unreal-systems-engineer": "Benötigt Unreal Engine",
    "unreal-technical-artist": "Benötigt Unreal Engine",
    "unreal-world-builder": "Benötigt Unreal Engine",
    "macos-spatial-metal-engineer": "Benötigt macOS + Xcode + Metal",
    "visionos-spatial-engineer": "Benötigt macOS + Xcode (visionOS)",
    "terminal-integration-specialist": "Benötigt macOS/Swift-App-Umgebung (SwiftTerm)",
    "marketing-x-twitter-intelligence-analyst": "Benötigt kostenpflichtigen Dienst Xquik",
    "marketing-carousel-growth-engine": "Benötigt API-Schlüssel (Gemini, TikTok, Instagram)",
    "marketing-multi-platform-publisher": "Benötigt lokale Tools und Plattform-Logins",
}
NOTES = {
    "engineering-mobile-app-builder": "iOS-Builds brauchen macOS; Code schreiben geht",
    "engineering-embedded-firmware-engineer": "Hardware nicht anschließbar; Code schreiben geht",
    "design-ui-finish-gate-reviewer": "Nutzt die freie Website uizze.com (Netzwerkfreigabe nötig)",
}


def map_color(raw):
    v = raw.strip().strip("'\"").lower()
    if v in CLAUDE_COLORS:
        return v
    if v in ALIASES:
        return ALIASES[v]
    m = re.fullmatch(r"#?([0-9a-f]{6})", v)
    if not m:
        return "blue"
    r, g, b = (int(m.group(1)[i:i + 2], 16) / 255 for i in (0, 2, 4))
    h, _, s = colorsys.rgb_to_hls(r, g, b)
    if s < 0.15:
        return "blue"
    h *= 360
    return min(CLAUDE_COLORS, key=lambda c: min(abs(h - CLAUDE_COLORS[c]), 360 - abs(h - CLAUDE_COLORS[c])))


def first_desc(fm_lines):
    out, on = [], False
    for ln in fm_lines:
        if re.match(r"^description:", ln):
            on = True
            out.append(ln.split(":", 1)[1].strip())
        elif on and re.match(r"^\s+\S", ln):
            out.append(ln.strip())
        elif on:
            break
    return " ".join(out).strip("'\" >|")


def convert(path, slug):
    txt = open(path, encoding="utf-8").read()
    m = re.match(r"^---\n(.*?)\n---\n", txt, re.S)
    fm = m.group(1).splitlines()
    display, new = "", []
    for ln in fm:
        nm = re.match(r"^name:\s*(.*)$", ln)
        cm = re.match(r"^color:\s*(.*)$", ln)
        if nm:
            display = nm.group(1).strip().strip("'\"")
            new.append(f"name: {slug}")
            new.append(f"display_name: \"{display}\"")
        elif cm:
            new.append(f"color: {map_color(cm.group(1))}")
        else:
            new.append(ln)
    return "---\n" + "\n".join(new) + "\n---\n" + txt[m.end():], display, first_desc(fm)


divisions = json.load(open(os.path.join(src, "divisions.json")))["divisions"]
catalog = []
for div in sorted(divisions):
    for dp, _, files in os.walk(os.path.join(src, div)):
        for f in sorted(files):
            if not f.endswith(".md"):
                continue
            slug = f[:-3]
            out, display, desc = convert(os.path.join(dp, f), slug)
            if slug in CORE:
                status, rel = "aktiv", os.path.join(".claude", "agents", f)
            elif slug in RESTRICTED:
                status, rel = "eingeschränkt", os.path.join("agents", "restricted", div, f)
            else:
                status, rel = "bibliothek", os.path.join("agents", "library", div, f)
            os.makedirs(os.path.join(dest, os.path.dirname(rel)), exist_ok=True)
            with open(os.path.join(dest, rel), "x", encoding="utf-8") as fh:  # "x": never overwrite
                fh.write(out)
            catalog.append({"slug": slug, "display": display, "division": div, "status": status,
                            "path": rel, "note": RESTRICTED.get(slug) or NOTES.get(slug, ""),
                            "description": desc})

slugs = [c["slug"] for c in catalog]
assert len(slugs) == len(set(slugs)), "duplicate slugs"
missing = set(CORE) - {c["slug"] for c in catalog}
assert not missing, f"core agents not found: {missing}"
json.dump(catalog, open(os.path.join(dest, "agents", "catalog.json"), "x", encoding="utf-8"), ensure_ascii=False, indent=1)

# Markdown catalog
lab = {k: v["label"] for k, v in divisions.items()}
icon = {"aktiv": "✅ aktiv", "bibliothek": "📚 Bibliothek", "eingeschränkt": "⚠️ eingeschränkt"}
lines = ["# Agenten-Katalog", "", "Automatisch erzeugt aus agency-agents. Status: ✅ aktiv = sofort nutzbar, "
         "📚 Bibliothek = cloud-kompatibel, per `scripts/agent.sh activate <name>` aktivierbar, "
         "⚠️ eingeschränkt = braucht Software/Konten, die in der Cloud fehlen.", ""]
counts = {s: sum(c["status"] == s for c in catalog) for s in icon}
lines += [f"**Gesamt:** {len(catalog)} · ✅ {counts['aktiv']} · 📚 {counts['bibliothek']} · ⚠️ {counts['eingeschränkt']}", ""]
for div in sorted(divisions):
    rows = [c for c in catalog if c["division"] == div]
    lines += [f"## {lab[div]} ({len(rows)})", "", "| Name (zum Aktivieren) | Anzeigename | Status | Beschreibung / Hinweis |", "|---|---|---|---|"]
    for c in rows:
        d = c["description"].replace("|", "/")
        d = (d[:140] + "…") if len(d) > 140 else d
        if c["note"]:
            d = f"**{c['note']}** — {d}"
        lines.append(f"| `{c['slug']}` | {c['display']} | {icon[c['status']]} | {d} |")
    lines.append("")
open(os.path.join(dest, "agents", "KATALOG.md"), "x", encoding="utf-8").write("\n".join(lines))
print(json.dumps(counts), len(catalog))
