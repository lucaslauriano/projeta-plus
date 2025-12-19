#!/bin/bash
# build_encrypted.sh - Build com arquivos .rbe criptografados

PLUGIN_NAME="projeta_plus"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
VERSION_FILE="$SCRIPT_DIR/version.txt"

# Read and increment version
if [ -f "$VERSION_FILE" ]; then
  VERSION=$(cat "$VERSION_FILE")
else
  VERSION="2.0.0"
  echo "$VERSION" > "$VERSION_FILE"
fi

# Auto-increment patch version (2.0.0 -> 2.0.1 -> 2.0.2, etc)
IFS='.' read -r major minor patch <<< "$VERSION"
patch=$((patch + 1))
NEW_VERSION="${major}.${minor}.${patch}"
echo "$NEW_VERSION" > "$VERSION_FILE"

PLUGINS_DIR="$( cd "$SCRIPT_DIR/.." && pwd )"
ENCRYPTED_DIR="$SCRIPT_DIR/encrypted_build"
BUILD_DIR="$SCRIPT_DIR/build_encrypted_temp"
DIST_DIR="$PLUGINS_DIR/dist"
OUTPUT_FILE="$DIST_DIR/${PLUGIN_NAME}_encrypted_v${NEW_VERSION}.rbz"

echo ""
echo "🔒 Build Criptografado - Projeta Plus v${NEW_VERSION} (anterior: v${VERSION})"
echo ""

# Verificar se os arquivos criptografados existem
if [ ! -d "$ENCRYPTED_DIR" ]; then
  echo "❌ Arquivos criptografados (.rbe) não encontrados!"
  echo ""
  echo "📌 EXECUTE PRIMEIRO NO SKETCHUP 2023:"
  echo "   1. Abra SketchUp 2023"
  echo "   2. Window > Ruby Console"
  echo "   3. Cole e execute:"
  echo ""
  echo "   load '${SCRIPT_DIR}/encrypt_with_sketchup2023.rb'"
  echo ""
  echo "   4. Após finalizar, execute este script novamente"
  exit 1
fi

# Verificar se há arquivos .rbe
RBE_COUNT=$(find "$ENCRYPTED_DIR" -name "*.rbe" | wc -l)
if [ "$RBE_COUNT" -eq 0 ]; then
  echo "❌ Nenhum arquivo .rbe encontrado em: $ENCRYPTED_DIR"
  echo "   Execute o encrypt_with_sketchup2023.rb primeiro!"
  exit 1
fi

echo "✅ Encontrados $RBE_COUNT arquivos .rbe criptografados"
echo ""

# Limpar build anterior
echo "🧹 Limpando builds anteriores..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
mkdir -p "$DIST_DIR"

# Copiar loader principal (não criptografado - apenas registra extensão)
echo "📦 Copiando loader..."
WORKSPACE_DIR="$( cd "$PLUGINS_DIR/.." && pwd )"
if [ -f "$PLUGINS_DIR/${PLUGIN_NAME}.rb" ]; then
  cp "$PLUGINS_DIR/${PLUGIN_NAME}.rb" "$BUILD_DIR/"
elif [ -f "$WORKSPACE_DIR/${PLUGIN_NAME}.rb" ]; then
  cp "$WORKSPACE_DIR/${PLUGIN_NAME}.rb" "$BUILD_DIR/"
else
  echo "❌ Loader ${PLUGIN_NAME}.rb não encontrado em:"
  echo "   - $PLUGINS_DIR"
  echo "   - $WORKSPACE_DIR"
  exit 1
fi

# Copiar arquivos criptografados (.rbe)
echo "📦 Copiando arquivos criptografados (.rbe)..."
rsync -av \
  --exclude='.DS_Store' \
  "$ENCRYPTED_DIR/" "$BUILD_DIR/$PLUGIN_NAME/"

# Copiar arquivos não-Ruby (componentes, ícones, traduções)
echo "📦 Copiando recursos (ícones, componentes, traduções)..."

# Componentes .skp
if [ -d "$PLUGINS_DIR/components" ]; then
  rsync -av "$PLUGINS_DIR/components/" "$BUILD_DIR/$PLUGIN_NAME/components/"
fi

# Ícones
if [ -d "$PLUGINS_DIR/icons" ]; then
  rsync -av "$PLUGINS_DIR/icons/" "$BUILD_DIR/$PLUGIN_NAME/icons/"
fi

# Traduções
if [ -d "$PLUGINS_DIR/lang" ]; then
  rsync -av "$PLUGINS_DIR/lang/" "$BUILD_DIR/$PLUGIN_NAME/lang/"
fi

# Data (tags, etc)
if [ -d "$PLUGINS_DIR/data" ]; then
  rsync -av "$PLUGINS_DIR/data/" "$BUILD_DIR/$PLUGIN_NAME/data/"
fi

# Frontend (se houver arquivos HTML/CSS/JS locais)
if [ -d "$PLUGINS_DIR/frontend" ]; then
  rsync -av "$PLUGINS_DIR/frontend/" "$BUILD_DIR/$PLUGIN_NAME/frontend/"
fi

# Criar o .rbz (é apenas um zip)
echo "📦 Criando arquivo .rbz..."
cd "$BUILD_DIR"
zip -r -q "$OUTPUT_FILE" .
cd "$SCRIPT_DIR"

# Verificar se foi criado
if [ -f "$OUTPUT_FILE" ]; then
  FILE_SIZE=$(ls -lh "$OUTPUT_FILE" | awk '{print $5}')
  echo ""
  echo "="*70
  echo "✅ BUILD CONCLUÍDO COM SUCESSO!"
  echo "="*70
  echo "📦 Arquivo: ${PLUGIN_NAME}_encrypted_v${NEW_VERSION}.rbz"
  echo "📊 Tamanho: $FILE_SIZE"
  echo "📍 Local: $DIST_DIR"
  echo "🔒 Tipo: Arquivos .rbe criptografados"
  echo ""
  echo "📌 PRÓXIMOS PASSOS:"
  echo "   1. Instale no SketchUp: Extensions > Extension Manager > Install"
  echo "   2. Teste todas as funcionalidades"
  echo ""
  
  # Limpar diretório temporário
  echo "🧹 Limpando arquivos temporários..."
  rm -rf "$BUILD_DIR"
  echo "✓ Build temporário removido"
  echo ""
  echo "="*70
else
  echo "❌ ERRO ao criar .rbz"
  exit 1
fi
