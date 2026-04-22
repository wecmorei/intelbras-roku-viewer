#!/usr/bin/env pwsh
# Script de Empacotamento do App Roku - Intelbras Viewer
# Uso: .\package-roku-app.ps1

param(
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = "./roku_app.zip",
    [switch]$OpenLocation
)

Write-Host "🎬 Empacotando App Roku - Intelbras Viewer" -ForegroundColor Cyan

# Verificar se estamos no diretório correto
if (-not (Test-Path "manifest" -PathType Leaf)) {
    Write-Host "❌ Erro: Arquivo 'manifest' não encontrado!" -ForegroundColor Red
    Write-Host "   Execute este script dentro da pasta 'intelbras-roku-viewer'" -ForegroundColor Yellow
    exit 1
}

# Verificar arquivos necessários
$requiredFiles = @(
    "manifest",
    "source/main.brs",
    "components/MainScene.xml",
    "components/MainScene.brs"
)

$allExist = $true
foreach ($file in $requiredFiles) {
    if (-not (Test-Path $file)) {
        Write-Host "❌ Arquivo faltando: $file" -ForegroundColor Red
        $allExist = $false
    }
}

if (-not $allExist) {
    Write-Host "   Estrutura incompleta!" -ForegroundColor Red
    exit 1
}

# Remover ZIP anterior se existir
if (Test-Path $OutputPath) {
    Write-Host "🗑️  Removendo arquivo anterior..." -ForegroundColor Yellow
    Remove-Item $OutputPath -Force
}

# Criar ZIP
Write-Host "📦 Criando arquivo ZIP..." -ForegroundColor Cyan
Compress-Archive -Path @(
    "manifest",
    "source",
    "components"
) -DestinationPath $OutputPath

if (Test-Path $OutputPath) {
    $fileSize = (Get-Item $OutputPath).Length
    Write-Host "✅ Sucesso! App empacotado:" -ForegroundColor Green
    Write-Host "   Arquivo: $OutputPath" -ForegroundColor Green
    Write-Host "   Tamanho: $([math]::Round($fileSize/1024, 2)) KB" -ForegroundColor Green
    
    if ($OpenLocation) {
        Invoke-Item (Split-Path -Parent (Resolve-Path $OutputPath))
    }
    
    Write-Host ""
    Write-Host "📱 Próximas etapas:" -ForegroundColor Cyan
    Write-Host "   1. Ativar modo desenvolvedor no Roku (GUIA-FINAL-INTEGRADO.md)" -ForegroundColor White
    Write-Host "   2. Acessar http://IP_DO_ROKU:8080" -ForegroundColor White
    Write-Host "   3. Upload: $OutputPath" -ForegroundColor White
    Write-Host "   4. Instalar e executar!" -ForegroundColor White
}
else {
    Write-Host "❌ Erro ao criar ZIP!" -ForegroundColor Red
    exit 1
}
