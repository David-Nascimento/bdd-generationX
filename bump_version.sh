#!/usr/bin/env bash
set -e
set -x

# CONFIGURAÇÃO
# Se existir arquivo VERSION na raiz, usa aquele.
# Senão, busca em lib/bddgenx/VERSION.
if [ -f "VERSION" ]; then
  VERSION_FILE="VERSION"
elif [ -f "lib/bddgenx/VERSION" ]; then
  VERSION_FILE="lib/bddgenx/VERSION"
else
  echo "❌ Nenhum arquivo de versão encontrado (VERSION ou lib/bddgenx/VERSION)."
  exit 1
fi

GEMSPEC_FILE="bddgenx.gemspec"
REMOTE="origin"
BRANCH="main"

# Atualiza as referências do remote (importante para diffs e logs)
git fetch "$REMOTE" "$BRANCH"

# Função para detectar tipo de bump
detectar_tipo_versao() {
  # Conta quantos arquivos foram alterados desde o último commit no remote
  arquivos_modificados=$(git diff --name-only "$REMOTE/$BRANCH"...HEAD | wc -l)
  mensagens_commit=$(git log "$REMOTE/$BRANCH"..HEAD --pretty=format:"%s")

  if echo "$mensagens_commit" | grep -iq "BREAKING CHANGE"; then
    echo "major"
  elif [ "$arquivos_modificados" -ge 35 ]; then
    echo "major"
  elif echo "$mensagens_commit" | grep -iq "^feat"; then
    echo "minor"
  elif [ "$arquivos_modificados" -ge 10 ]; then
    echo "minor"
  else
    echo "patch"
  fi
}

# 1) Define a nova versão
if [ "$#" -eq 1 ]; then
  NEW_VERSION="$1"
else
  # Se não existe, cria com 0.0.0
  [ -f "$VERSION_FILE" ] || echo "0.0.0" > "$VERSION_FILE"
  CURRENT_VERSION=$(cat "$VERSION_FILE")
  IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_VERSION"

  tipo_bump=$(detectar_tipo_versao)

  case "$tipo_bump" in
    major)
      MAJOR=$((MAJOR + 1))
      MINOR=0
      PATCH=0
      ;;
    minor)
      MINOR=$((MINOR + 1))
      PATCH=0
      ;;
    patch)
      PATCH=$((PATCH + 1))
      ;;
  esac

  NEW_VERSION="$MAJOR.$MINOR.$PATCH"
fi

echo "🔖 Bump de versão: ${CURRENT_VERSION:-N/A} → $NEW_VERSION"

# 2) Atualiza o arquivo de versão
echo "$NEW_VERSION" > "$VERSION_FILE"

# 3) Commit, tag e push
git checkout "$BRANCH"
git pull "$REMOTE" "$BRANCH"
git add "$VERSION_FILE"
git commit -m "Bump version to v$NEW_VERSION"
git tag -a "v$NEW_VERSION" -m "Release v$NEW_VERSION"
git push "$REMOTE" "$BRANCH"
git push "$REMOTE" "v$NEW_VERSION"

# 4) Gera a gem
echo "📦 Gerando pacote gem..."
gem build "$GEMSPEC_FILE"

GEMFILE="bddgenx-$NEW_VERSION.gem"
if [ -f "$GEMFILE" ]; then
  echo "✅ Pacote gerado: $GEMFILE"
else
  echo "❌ Falha ao encontrar o arquivo $GEMFILE após build."
  exit 1
fi
