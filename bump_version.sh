#!/usr/bin/env bash
set -e

# CONFIGURAÇÃO
VERSION_FILE="VERSION"
GEMSPEC_FILE="bddgenx.gemspec"  # ajuste se seu gemspec tiver outro nome
REMOTE="origin"
BRANCH="main"    # ou 'master', conforme seu fluxo

# 1) Determina a nova versão
if [ "$#" -eq 1 ]; then
  NEW_VERSION="$1"
else
  # Garante que exista o arquivo VERSION
  [ -f "$VERSION_FILE" ] || echo "0.0.0" > "$VERSION_FILE"
  CURRENT_VERSION=$(cat "$VERSION_FILE")
  IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_VERSION"
  PATCH=$((PATCH + 1))
  NEW_VERSION="$MAJOR.$MINOR.$PATCH"
fi

echo "🔖 Bump de versão: ${CURRENT_VERSION:-N/A} → $NEW_VERSION"

# 2) Atualiza o arquivo VERSION
echo "$NEW_VERSION" > "$VERSION_FILE"

# 3) Commit, tag e push no Git
git checkout "$BRANCH"
git pull "$REMOTE" "$BRANCH"

git add "$VERSION_FILE"
git commit -m "Bump version to v$NEW_VERSION"
git tag -a "v$NEW_VERSION" -m "Release v$NEW_VERSION"
git push "$REMOTE" "$BRANCH"
git push "$REMOTE" "v$NEW_VERSION"

# 4) Gera o .gem com a versão nova
echo "📦 Gerando pacote gem..."
gem build "$GEMSPEC_FILE"

echo "✅ Pacote gerado: $(basename bddgenx-$NEW_VERSION.gem)"
