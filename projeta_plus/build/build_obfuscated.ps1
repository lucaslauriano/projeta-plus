# build_obfuscated.ps1 - Windows build for Projeta Plus (creates obfuscated .rbz)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$pluginName = 'projeta_plus'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$versionFile = Join-Path $scriptDir 'version.txt'

# Read and increment version
if (Test-Path -LiteralPath $versionFile) {
  $version = (Get-Content -LiteralPath $versionFile -Raw).Trim()
} else {
  $version = '2.0.0'
  Set-Content -LiteralPath $versionFile -Value $version -NoNewline
}

# Auto-increment patch version (2.0.0 -> 2.0.1 -> 2.0.2, etc)
$versionParts = $version -split '\.'
$major = [int]$versionParts[0]
$minor = [int]$versionParts[1]
$patch = [int]$versionParts[2]
$patch++
$newVersion = "$major.$minor.$patch"
Set-Content -LiteralPath $versionFile -Value $newVersion -NoNewline

$pluginsDir = Split-Path -Parent $scriptDir                       # .../Plugins/projeta_plus
$obfuscatedDir = Join-Path $scriptDir 'obfuscated_build'
$buildDir = Join-Path $scriptDir 'build_obfuscated_temp'
$distDir = Join-Path $pluginsDir 'dist'
$outputFile = Join-Path $distDir ("{0}_obfuscated_v{1}.rbz" -f $pluginName, $newVersion)

Write-Host "🔀 Build Ofuscado - Projeta Plus v$newVersion (anterior: v$version)"`n

# Ensure Ruby obfuscation exists (run automatically if missing)
if (-not (Test-Path -LiteralPath $obfuscatedDir)) {
  Write-Host "❌ Arquivos ofuscados não encontrados!" 
  Write-Host "" 
  Write-Host "📌 EXECUTANDO OFUSCAÇÃO AUTOMATICAMENTE..."
  & ruby (Join-Path $scriptDir 'obfuscate.rb')
  if (-not (Test-Path -LiteralPath $obfuscatedDir)) {
    throw "Falha na ofuscação. Abortando."
  }
  Write-Host ""
}

# Clean previous build
Write-Host "🧹 Limpando builds anteriores..."
if (Test-Path -LiteralPath $buildDir) { Remove-Item -LiteralPath $buildDir -Recurse -Force }
if (-not (Test-Path -LiteralPath $distDir)) { New-Item -ItemType Directory -Path $distDir | Out-Null }
New-Item -ItemType Directory -Path $buildDir | Out-Null

# Copy loader (projeta_plus.rb)
Write-Host "📦 Copiando loader..."
$workspaceDir = Split-Path -Parent $pluginsDir                    # .../Plugins
$loaderInPluginDir = Join-Path $pluginsDir ("{0}.rb" -f $pluginName)
$loaderInWorkspace = Join-Path $workspaceDir ("{0}.rb" -f $pluginName)
if (Test-Path -LiteralPath $loaderInPluginDir) {
  Copy-Item -LiteralPath $loaderInPluginDir -Destination $buildDir -Force
} elseif (Test-Path -LiteralPath $loaderInWorkspace) {
  Copy-Item -LiteralPath $loaderInWorkspace -Destination $buildDir -Force
} else {
  throw "Loader $pluginName.rb não encontrado em: `n - $pluginsDir `n - $workspaceDir"
}

# Ensure target package dir exists
$packageRoot = Join-Path $buildDir $pluginName
if (-not (Test-Path -LiteralPath $packageRoot)) { New-Item -ItemType Directory -Path $packageRoot | Out-Null }

# Copy obfuscated sources
Write-Host "📦 Copiando arquivos ofuscados..."
Copy-Item -LiteralPath (Join-Path $obfuscatedDir '*') -Destination $packageRoot -Recurse -Force -ErrorAction Stop

# Copy resources (components, icons, translations)
Write-Host "📦 Copiando recursos (ícones, componentes, traduções)..."
if (Test-Path -LiteralPath (Join-Path $pluginsDir 'components')) { Copy-Item -LiteralPath (Join-Path $pluginsDir 'components') -Destination $packageRoot -Recurse -Force }
if (Test-Path -LiteralPath (Join-Path $pluginsDir 'icons')) { Copy-Item -LiteralPath (Join-Path $pluginsDir 'icons') -Destination $packageRoot -Recurse -Force }
if (Test-Path -LiteralPath (Join-Path $pluginsDir 'lang')) { Copy-Item -LiteralPath (Join-Path $pluginsDir 'lang') -Destination $packageRoot -Recurse -Force }

# Copy top-level css/html/json in plugin folder
Get-ChildItem -LiteralPath $pluginsDir -File | Where-Object { $_.Extension -in '.css', '.html', '.json' } | ForEach-Object {
  Copy-Item -LiteralPath $_.FullName -Destination $packageRoot -Force
}

# Create the .rbz (zip)
Write-Host ""; Write-Host "📦 Criando arquivo .rbz ofuscado..."
if (Test-Path -LiteralPath $outputFile) { Remove-Item -LiteralPath $outputFile -Force }
Compress-Archive -Path (Join-Path $buildDir '*') -DestinationPath $outputFile -Force

function Format-Size([long]$bytes) {
  if ($bytes -lt 1KB) { return "$bytes B" }
  $units = 'KB','MB','GB','TB'
  $size = [double]$bytes
  foreach ($u in $units) {
    $size = $size / 1024
    if ($size -lt 1024) { return "{0:N1} $u" -f $size }
  }
  return "{0:N1} PB" -f ($size/1024)
}

$fileSize = (Get-Item -LiteralPath $outputFile).Length | ForEach-Object { Format-Size $_ }

Write-Host "" 
Write-Host "✅ Build ofuscado concluído!"
Write-Host "📍 Arquivo criado: $outputFile"
Write-Host "📊 Tamanho: $fileSize"
Write-Host "🔀 Código minificado e comentários removidos"

# Cleanup
Write-Host ""; Write-Host "🧹 Limpando arquivos temporários..."
if (Test-Path -LiteralPath $buildDir) { Remove-Item -LiteralPath $buildDir -Recurse -Force }
if (Test-Path -LiteralPath $obfuscatedDir) { Remove-Item -LiteralPath $obfuscatedDir -Recurse -Force }
$encryptedBuild = Join-Path $scriptDir 'encrypted_build'
if (Test-Path -LiteralPath $encryptedBuild) { Remove-Item -LiteralPath $encryptedBuild -Recurse -Force }

Write-Host "" 
Write-Host "✨ Build ofuscado finalizado!" 
Write-Host "" 
Write-Host "✅ Arquivos temporários removidos:" 
Write-Host "   - obfuscated_build/" 
Write-Host "   - encrypted_build/" 
Write-Host "   - build_obfuscated_temp/" 
Write-Host "" 
Write-Host "⚠️  IMPORTANTE:" 
Write-Host "   - Código foi minificado (sem comentários/espaços extras)" 
Write-Host "   - APIs públicas preservadas (frontend funcionará normalmente)" 
Write-Host "   - Teste o .rbz antes de distribuir" 
Write-Host "" 
Write-Host "📌 Para testar:" 
Write-Host "   Window > Extension Manager > Install Extension > Selecione o .rbz"


