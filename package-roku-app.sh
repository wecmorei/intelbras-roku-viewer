#!/bin/bash
# Script de Empacotamento do App Roku - Intelbras Viewer
# Uso: ./package-roku-app.sh

OUTPUT_PATH="${1:-.}/roku_app.zip"
OPEN_LOCATION="${2:-false}"

echo "🎬 Empacotando App Roku - Intelbras Viewer"

# Verificar se estamos no diretório correto
if [ ! -f "manifest" ]; then
    echo "❌ Erro: Arquivo 'manifest' não encontrado!"
    echo "   Execute este script dentro da pasta 'intelbras-roku-viewer'"
    exit 1
fi

# Verificar arquivos necessários
REQUIRED_FILES=(
    "manifest"
    "source/main.brs"
    "components/MainScene.xml"
    "components/MainScene.brs"
)

ALL_EXIST=true
for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        echo "❌ Arquivo faltando: $file"
        ALL_EXIST=false
    fi
done

if [ "$ALL_EXIST" = false ]; then
    echo "   Estrutura incompleta!"
    exit 1
fi

# Remover ZIP anterior se existir
if [ -f "$OUTPUT_PATH" ]; then
    echo "🗑️  Removendo arquivo anterior..."
    rm -f "$OUTPUT_PATH"
fi

# Criar ZIP
echo "📦 Criando arquivo ZIP..."
zip -r "$OUTPUT_PATH" manifest source components > /dev/null 2>&1

if [ -f "$OUTPUT_PATH" ]; then
    FILE_SIZE=$(stat -f%z "$OUTPUT_PATH" 2>/dev/null || stat -c%s "$OUTPUT_PATH" 2>/dev/null)
    SIZE_KB=$((FILE_SIZE / 1024))
    
    echo "✅ Sucesso! App empacotado:"
    echo "   Arquivo: $OUTPUT_PATH"
    echo "   Tamanho: $SIZE_KB KB"
    
    if [ "$OPEN_LOCATION" = "true" ]; then
        open "$(dirname "$OUTPUT_PATH")" 2>/dev/null || xdg-open "$(dirname "$OUTPUT_PATH")" 2>/dev/null
    fi
    
    echo ""
    echo "📱 Próximas etapas:"
    echo "   1. Ativar modo desenvolvedor no Roku (GUIA-FINAL-INTEGRADO.md)"
    echo "   2. Acessar http://IP_DO_ROKU:8080"
    echo "   3. Upload: $OUTPUT_PATH"
    echo "   4. Instalar e executar!"
else
    echo "❌ Erro ao criar ZIP!"
    exit 1
fi
