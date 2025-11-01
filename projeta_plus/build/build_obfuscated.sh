#!/bin/bash
# build_obfuscated.sh - Build com arquivos ofuscados

PLUGIN_NAME="projeta_plus"
VERSION="2.0.0"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PLUGINS_DIR="$( cd "$SCRIPT_DIR/.." && pwd )"
OBFUSCATED_DIR="$SCRIPT_DIR/obfuscated_build"
BUILD_DIR="$SCRIPT_DIR/build_obfuscated_temp"
DIST_DIR="$PLUGINS_DIR/dist"
OUTPUT_FILE="$DIST_DIR/${PLUGIN_NAME}_obfuscated_v${VERSION}.rbz"

echo "🔀 Build Ofuscado - Projeta Plus v${VERSION}"
echo ""

# Verificar se os arquivos ofuscados existem
if [ ! -d "$OBFUSCATED_DIR" ]; then
  echo "❌ Arquivos ofuscados não encontrados!"
  echo ""
  echo "📌 EXECUTANDO OFUSCAÇÃO AUTOMATICAMENTE..."
  ruby "$SCRIPT_DIR/obfuscate.rb"
  
  if [ ! -d "$OBFUSCATED_DIR" ]; then
    echo "❌ Falha na ofuscação. Abortando."
    exit 1
  fi
  echo ""
fi

# Limpar build anterior
echo "🧹 Limpando builds anteriores..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
mkdir -p "$DIST_DIR"

# Copiar loader principal (não ofuscado - apenas registra extensão)
echo "📦 Copiando loader..."
cp "$PLUGINS_DIR/${PLUGIN_NAME}.rb" "$BUILD_DIR/"

# Copiar arquivos ofuscados
echo "📦 Copiando arquivos ofuscados..."
rsync -av \
  --exclude='.DS_Store' \
  "$OBFUSCATED_DIR/" "$BUILD_DIR/$PLUGIN_NAME/"

# Copiar arquivos não-Ruby (componentes, ícones, traduções)
echo "📦 Copiando recursos (ícones, componentes, traduções)..."

# Componentes .skp
if [ -d "$PLUGINS_DIR/$PLUGIN_NAME/components" ]; then
  rsync -av "$PLUGINS_DIR/$PLUGIN_NAME/components/" "$BUILD_DIR/$PLUGIN_NAME/components/"
fi

# Ícones
if [ -d "$PLUGINS_DIR/$PLUGIN_NAME/icons" ]; then
  rsync -av "$PLUGINS_DIR/$PLUGIN_NAME/icons/" "$BUILD_DIR/$PLUGIN_NAME/icons/"
fi

# Traduções
if [ -d "$PLUGINS_DIR/$PLUGIN_NAME/lang" ]; then
  rsync -av "$PLUGINS_DIR/$PLUGIN_NAME/lang/" "$BUILD_DIR/$PLUGIN_NAME/lang/"
fi

# CSS, HTML, etc (se houver)
find "$PLUGINS_DIR/$PLUGIN_NAME" -maxdepth 1 \( -name "*.css" -o -name "*.html" -o -name "*.json" \) -exec cp {} "$BUILD_DIR/$PLUGIN_NAME/" \; 2>/dev/null

# Criar o .rbz
echo ""
echo "📦 Criando arquivo .rbz ofuscado..."
cd "$BUILD_DIR"
rm -f "$OUTPUT_FILE"
zip -r "$OUTPUT_FILE" . -q

FILE_SIZE=$(du -h "$OUTPUT_FILE" | cut -f1)

echo ""
echo "✅ Build ofuscado concluído!"
echo "📍 Arquivo criado: $OUTPUT_FILE"
echo "📊 Tamanho: $FILE_SIZE"
echo "🔀 Código minificado e comentários removidos"

# Limpar tudo
echo ""
echo "🧹 Limpando arquivos temporários..."
cd "$SCRIPT_DIR"
rm -rf "$BUILD_DIR"
rm -rf "$OBFUSCATED_DIR"
rm -rf "$SCRIPT_DIR/encrypted_build"

echo ""
echo "✨ Build ofuscado finalizado!"
echo ""
echo "✅ Arquivos temporários removidos:"
echo "   - obfuscated_build/"
echo "   - encrypted_build/"
echo "   - build_obfuscated_temp/"
echo ""
echo "⚠️  IMPORTANTE:"
echo "   - Código foi minificado (sem comentários/espaços extras)"
echo "   - APIs públicas preservadas (frontend funcionará normalmente)"
echo "   - Teste o .rbz antes de distribuir"
echo ""
echo "📌 Para testar:"
echo "   Window > Extension Manager > Install Extension > Selecione o .rbz"

