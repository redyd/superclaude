#!/usr/bin/env bash
# Déploie la stack Claude Code depuis ce repo. Idempotent : relançable sans risque.
#   ./install.sh             déploie tout
#   ./install.sh update-ecc  rafraîchit les skills ECC vendorisés dans claude/skills/ (à committer)
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
SETTINGS="$REPO_DIR/claude/settings.json"
ECC_REF="${ECC_REF:-main}"
ECC_SKILLS=(
  springboot-patterns springboot-tdd java-coding-standards jpa-patterns
  api-design postgres-patterns docker-patterns deployment-patterns
)

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$*" >&2; }

# Crée un lien symbolique, en sauvegardant ce qui existait déjà à la destination.
link() {
  local src="$1" dst="$2"
  [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]] && return
  if [[ -e "$dst" || -L "$dst" ]]; then
    mv "$dst" "$dst.bak.$(date +%s)"
    warn "ancien $dst sauvegardé en .bak"
  fi
  mkdir -p "$(dirname "$dst")"
  ln -s "$src" "$dst"
}

install_prereqs() {
  local missing=0
  for cmd in git jq node npm gh curl; do command -v "$cmd" >/dev/null || missing=1; done
  if (( missing )); then
    log "Installation des prérequis (dnf)"
    sudo dnf install -y git jq nodejs npm gh curl
  fi
}

install_claude() {
  command -v claude >/dev/null && return
  log "Installation de Claude Code"
  curl -fsSL https://claude.ai/install.sh | bash
  export PATH="$HOME/.local/bin:$PATH"
}

# Les plugins *-lsp ne font que brancher Claude sur un serveur de langage déjà présent dans le PATH.
install_lsps() {
  log "Serveurs de langage"
  npm install -g --prefix "$HOME/.local" typescript typescript-language-server pyright >/dev/null
  if command -v dotnet >/dev/null; then
    dotnet tool update -g csharp-ls >/dev/null || warn "csharp-ls : échec"
  else
    warn "dotnet absent : csharp-lsp restera inactif"
  fi
  command -v jdtls >/dev/null || warn "jdtls absent du PATH : jdtls-lsp restera inactif (voir README du plugin)"
}

update_ecc() {
  local tmp; tmp="$(mktemp -d)"
  trap "rm -rf '$tmp'" RETURN
  log "Récupération des skills ECC ($ECC_REF)"
  git clone -q --depth 1 --branch "$ECC_REF" https://github.com/affaan-m/ECC.git "$tmp/ecc"
  mkdir -p "$REPO_DIR/claude/skills"
  for s in "${ECC_SKILLS[@]}"; do
    if [[ -d "$tmp/ecc/skills/$s" ]]; then
      rm -rf "$REPO_DIR/claude/skills/$s"
      cp -R "$tmp/ecc/skills/$s" "$REPO_DIR/claude/skills/"
    else
      warn "skill ECC introuvable : $s"
    fi
  done
}

merge_settings() {
  local dst="$CLAUDE_DIR/settings.json"
  mkdir -p "$CLAUDE_DIR"
  [[ -L "$dst" ]] && rm "$dst"
  [[ -f "$dst" ]] || echo '{}' > "$dst"
  jq -s '.[0] * .[1]' "$dst" "$SETTINGS" > "$dst.tmp" && mv "$dst.tmp" "$dst"
}

link_config() {
  log "Configuration"
  merge_settings
  link "$REPO_DIR/claude/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
  link "$REPO_DIR/ponytail/config.json" "$HOME/.config/ponytail/config.json"
  # Un lien par skill, pour ne pas écraser d'éventuels skills installés à la main.
  compgen -G "$REPO_DIR/claude/skills/*/" >/dev/null || update_ecc
  for dir in "$REPO_DIR"/claude/skills/*/; do
    link "${dir%/}" "$CLAUDE_DIR/skills/$(basename "$dir")"
  done
}

# settings.json est la source de vérité : on installe ce qu'il déclare.
# </dev/null empêche claude de consommer l'entrée de la boucle.
install_plugins() {
  log "Marketplaces et plugins"
  claude plugin marketplace add anthropics/claude-plugins-official </dev/null 2>/dev/null || true
  jq -r '.extraKnownMarketplaces // {} | .[].source.repo' "$SETTINGS" | while read -r repo; do
    claude plugin marketplace add "$repo" </dev/null || true
  done
  claude plugin marketplace update </dev/null || true
  jq -r '.enabledPlugins // {} | to_entries[] | select(.value) | .key' "$SETTINGS" | while read -r p; do
    claude plugin install "$p" </dev/null || warn "échec : $p"
  done
}

main() {
  if [[ "${1:-}" == "update-ecc" ]]; then update_ecc; exit; fi
  install_prereqs
  install_claude
  install_lsps
  link_config
  install_plugins
  log "Terminé. Lance 'claude', puis /plugin et /context pour vérifier."
}

main "$@"
