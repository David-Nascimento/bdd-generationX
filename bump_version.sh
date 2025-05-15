#!/usr/bin/env bash
set -e

# CONFIGURAÇÃO
VERSION_FILE="VERSION"
GEMSPEC_FILE="bddgenx.gemspec"  # ajuste se seu gemspec tiver outro nome
REMOTE="origin"
BRANCH="main"    # ou 'master', conforme seu fluxo

# Função para detectar o tipo de bump necessário
detect_bump_type() {
  local since_tag="$1"
  # obtém commits desde a última tag
  commits=$(git log "${since_tag}..HEAD" --pretty=%B)

  # breaking change -> major
  if echo "$commits" | grep -q -E "BREAKING[[:space:]]+CHANGE|!:"; then
    echo "major"
  # feat  -> minor
  elif echo "$commits" | grep -q -E "^feat\b"; then
    echo "minor"
  else
    echo "patch"
  fi
}

# 1) Determina versão atual
[ -f "$VERSION_FILE" ] || echo "0.0.0" > "$VERSION_FILE"
CURRENT_VERSION=$(cat "$VERSION_FILE")
IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_VERSION"

# 2) Decide bump type: manual ou automático
if [ "$#" -eq 1 ]; then
  # usuário passou tipo ou versão completa
  case "$1" in
    major|minor|patch)
      bump="$1" ;;
    *)
      NEW_VERSION="$1" ;;
  esac
fi

# Se bump não definido, detecta automaticamente
if [ -z "$NEW_VERSION" ]; then
  bump=${bump:-$(detect_bump_type "v$CURRENT_VERSION")}
  case "$bump" in
    major)
      MAJOR=$((MAJOR + 1)); MINOR=0; PATCH=0 ;;
    minor)
      MINOR=$((MINOR + 1)); PATCH=0 ;;
    patch)
      PATCH=$((PATCH + 1)) ;;
    *)
      echo "Tipo de bump inválido: $bump" >&2
      exit 1 ;;
  esac
  NEW_VERSION="$MAJOR.$MINOR.$PATCH"
fi

# 3) Exibe info
echo "🔖 Version bump: $CURRENT_VERSION → $NEW_VERSION"

# 4) Atualiza arquivo VERSION
echo "$NEW_VERSION" > "$VERSION_FILE"

# 5) Commit, tag e push no Git
git checkout "$BRANCH"
git pull "$REMOTE" "$BRANCH"

git add "$VERSION_FILE"
git commit -m "chore(release): bump version to v$NEW_VERSION"
git tag -a "v$NEW_VERSION" -m "Release v$NEW_VERSION"
git push "$REMOTE" "$BRANCH"
git push "$REMOTE" "v$NEW_VERSION"

# 6) Gera o .gem com a nova versão
echo "📦 Gerando pacote gem..."
gem build "$GEMSPEC_FILE"

echo "✅ Pacote gerado: $(basename bddgenx-$NEW_VERSION.gem)"
