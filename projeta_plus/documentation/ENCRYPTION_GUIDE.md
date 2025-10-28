# 🔒 Guia de Criptografia - Projeta Plus

## Por que Criptografar?

- **Proteger propriedade intelectual**: Código fica ilegível
- **Prevenir cópias**: Dificulta muito o roubo de código
- **Manter funcionalidade**: Arquivos `.rbs` funcionam normalmente no SketchUp

## ⚠️ IMPORTANTE: Limitações

1. **Não é 100% seguro**: É ofuscação, não criptografia militar
2. **Dificulta debug**: Erros mostram código criptografado
3. **Mantenha originais**: SEMPRE guarde os `.rb` originais em local seguro
4. **Apenas SketchUp**: `.rbs` só funciona no SketchUp

## 🔐 Método 1: Criptografia Oficial (.rbs)

### Passo 1: Gerar Arquivos Criptografados

```bash
# No terminal (gera apenas o script de comandos)
cd "/Users/lucaslauriano/Library/Application Support/SketchUp 2025/SketchUp/Plugins/projeta_plus"
ruby encrypt_rb.rb
```

### Passo 2: Executar no SketchUp

1. **Abra o SketchUp**
2. **Window** > **Ruby Console**
3. **Cole este comando**:

```ruby
load '/Users/lucaslauriano/Library/Application Support/SketchUp 2025/SketchUp/Plugins/projeta_plus/encrypt_sketchup.rb'
```

4. Aguarde (vai mostrar progresso):
```
✓ Criptografado: main.rb -> main.rbs
✓ Criptografado: commands.rb -> commands.rbs
✓ Criptografado: core.rb -> core.rbs
...
✅ Criptografia concluída!
📊 Arquivos criptografados: 25
```

### Passo 3: Gerar .rbz Criptografado

```bash
./build_encrypted.sh
```

**Resultado**: `dist/projeta_plus_encrypted_v2.0.0.rbz` 🔒

## 📊 Comparação: Normal vs Criptografado

### Arquivo Normal (.rb)
```ruby
# main.rb (legível)
require 'sketchup.rb'

module ProjetaPlus
  VERSION = "2.0.0".freeze
  
  def self.create_menu
    # ... código visível ...
  end
end
```

### Arquivo Criptografado (.rbs)
```
ÆÜ¢Ç≈†∂ƒ∆˙©˚¬µ˜øπ∂∑´...
[binário ilegível]
```

## 🔧 Estrutura dos Builds

### Build Normal
```
projeta_plus_v2.0.0.rbz
├── projeta_plus.rb
└── projeta_plus/
    ├── main.rb          ← LEGÍVEL
    ├── commands.rb      ← LEGÍVEL
    ├── core.rb          ← LEGÍVEL
    └── modules/
        └── *.rb         ← LEGÍVEL
```

### Build Criptografado
```
projeta_plus_encrypted_v2.0.0.rbz
├── projeta_plus.rb      ← Loader (legível)
└── projeta_plus/
    ├── main.rbs         ← CRIPTOGRAFADO
    ├── commands.rbs     ← CRIPTOGRAFADO
    ├── core.rbs         ← CRIPTOGRAFADO
    └── modules/
        └── *.rbs        ← CRIPTOGRAFADO
```

## 🛡️ Método 2: Ofuscação Manual (Alternativa)

Se não quiser usar `.rbs`, pode ofuscar o código Ruby:

```ruby
# Original
def calculate_area(width, height)
  width * height
end

# Ofuscado (exemplo simples)
def a(b,c);b*c;end

# Ou usar ofuscador online
# https://ruby-obfuscator.com (exemplo)
```

**Limitações**: Menos seguro que `.rbs`, mais trabalhoso.

## 📦 Workflows Recomendados

### Para Distribuição Pública (Extension Warehouse)
```bash
# Build normal (código aberto é mais confiável)
./build_simple.sh
```

### Para Clientes Comerciais (Licenciamento)
```bash
# 1. Criptografar
# (Rodar no SketchUp) load 'encrypt_sketchup.rb'

# 2. Build criptografado
./build_encrypted.sh
```

### Para Desenvolvimento
```bash
# Build normal (facilita debug)
./build_simple.sh
```

## 🔍 Verificar Criptografia

```bash
# Ver conteúdo de um arquivo .rbs
cat projeta_plus/encrypted_build/main.rbs

# Deve mostrar caracteres ilegíveis/binário
# Se mostrar código Ruby normal = NÃO está criptografado!
```

## ⚠️ Checklist Antes de Distribuir Versão Criptografada

- [ ] Código funciona 100% na versão normal
- [ ] Backup dos `.rb` originais feito (Git + backup externo)
- [ ] Testado versão criptografada em SketchUp limpo
- [ ] Todas as funcionalidades testadas
- [ ] Errors/exceptions tratados adequadamente
- [ ] Documentação de usuário criada (não mencione criptografia)
- [ ] Sistema de licenciamento implementado (se comercial)

## 🐛 Troubleshooting

### Erro: "Sketchup.scramble_script: no such method"
**Solução**: Você está executando fora do SketchUp. Use o Ruby Console do SketchUp.

### Erro ao carregar plugin criptografado
**Solução**: Verifique se o loader (`projeta_plus.rb`) aponta para `.rbs`:
```ruby
# Deve ser assim:
extension = SketchupExtension.new("PROJETA PLUS", File.join(PATH, 'projeta_plus', 'main.rbs'))
```

### Arquivos .rbs não funcionam
**Causas comuns**:
1. Encoding incorreto (use BINARY ao salvar)
2. Arquivo corrompido durante cópia
3. Versão do SketchUp muito antiga

### Debug de código criptografado é difícil
**Solução**: 
- Mantenha versão não-criptografada para desenvolvimento
- Use build criptografado apenas para distribuição
- Implemente logging detalhado antes de criptografar

## 🔒 Segurança Adicional

### 1. Licenciamento Online
```ruby
# Verificar licença no servidor
module ProjetaPlus
  def self.verify_license
    # HTTP request para seu servidor
    # Verificar UUID da máquina, etc
  end
end
```

### 2. Obfuscação de Strings Importantes
```ruby
# Em vez de:
LICENSE_SERVER = "https://api.example.com/verify"

# Use:
LICENSE_SERVER = ["68747470", "733a2f2f", "6170692e", ...].map{|h|h.to_i(16).chr}.join
```

### 3. Verificação de Integridade
```ruby
# Calcular hash dos arquivos e verificar
require 'digest'
EXPECTED_HASH = "abc123def456..."
```

## 📝 Notas Legais

- Criptografar código não substitui licenciamento adequado
- Considere usar EULA (End User License Agreement)
- Para vendas comerciais, consulte advogado
- Extension Warehouse tem suas próprias regras de licenciamento

## 🆘 Suporte

Se tiver problemas:
1. Verifique se seguiu todos os passos
2. Teste versão não-criptografada primeiro
3. Consulte logs do SketchUp (`Window > Ruby Console`)
4. Mantenha sempre backup dos originais!

