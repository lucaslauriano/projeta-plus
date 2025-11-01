#!/bin/bash
# clean_builds.sh - Limpa todos os arquivos temporários de build

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "🧹 Limpando builds temporários do Projeta Plus..."
echo ""

# Diretórios a limpar
DIRS_TO_CLEAN=(
  "$SCRIPT_DIR/encrypted_build"
  "$SCRIPT_DIR/obfuscated_build"
  "$SCRIPT_DIR/build_temp"
  "$SCRIPT_DIR/build_encrypted_temp"
  "$SCRIPT_DIR/build_obfuscated_temp"
  "$SCRIPT_DIR/test_extract"
)

# Arquivos a limpar
FILES_TO_CLEAN=(
  "$SCRIPT_DIR/encrypt_commands.txt"
)

CLEANED=0

# Limpar diretórios
for dir in "${DIRS_TO_CLEAN[@]}"; do
  if [ -d "$dir" ]; then
    echo "🗑️  Removendo: $(basename $dir)/"
    rm -rf "$dir"
    CLEANED=$((CLEANED + 1))
  fi
done

# Limpar arquivos
for file in "${FILES_TO_CLEAN[@]}"; do
  if [ -f "$file" ]; then
    echo "🗑️  Removendo: $(basename $file)"
    rm -f "$file"
    CLEANED=$((CLEANED + 1))
  fi
done

echo ""
if [ $CLEANED -eq 0 ]; then
  echo "✨ Já está limpo! Nada para remover."
else
  echo "✅ Limpeza concluída! $CLEANED item(s) removido(s)."
fi

echo ""
echo "📁 Mantidos:"
echo "   - dist/ (builds finais .rbz)"
echo "   - Todos os arquivos fonte (.rb)"
echo "   - Scripts de build"

