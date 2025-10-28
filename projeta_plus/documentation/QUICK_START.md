# 🚀 Guia Rápido - Proteger Código do Projeta Plus

## 📋 Resumo: 3 Opções

### 1. **SEM PROTEÇÃO** (Código Aberto)
```bash
./build_simple.sh
# → dist/projeta_plus_v2.0.0.rbz (código visível)
```
**Use se**: Plugin gratuito, quer comunidade, open source

---

### 2. **OFUSCAÇÃO SIMPLES** (Base64 + Zlib)
```bash
ruby obfuscate_simple.rb
# → obfuscated_build/ (código ofuscado, mas decodificável)
```
**Use se**: Proteção básica, não pode usar .rbs, valor baixo

---

### 3. **.RBS CRIPTOGRAFADO** (Método Oficial SketchUp) ⭐ RECOMENDADO
```bash
# Passo 1: Abrir SketchUp Ruby Console e colar:
load '/Users/lucaslauriano/Library/Application Support/SketchUp 2025/SketchUp/Plugins/projeta_plus/encrypt_sketchup.rb'

# Passo 2: Após criptografia concluir:
./build_encrypted.sh
# → dist/projeta_plus_encrypted_v2.0.0.rbz (SEGURO!)
```
**Use se**: Plugin comercial, precisa de proteção real

---

## 🎯 Qual Escolher?

| Seu Cenário | Método | Comando |
|-------------|--------|---------|
| Plugin grátis / Open Source | Sem proteção | `./build_simple.sh` |
| Proteção contra cópias casuais | Ofuscação | `ruby obfuscate_simple.rb` |
| Plugin pago / Comercial | **.rbs** ⭐ | Ver instruções abaixo |

---

## 📖 Instruções Detalhadas: Método .rbs (Recomendado)

### Passo 1️⃣: Criptografar Arquivos

**Abra o SketchUp**:
- Window > Ruby Console

**Cole este comando**:
```ruby
load '/Users/lucaslauriano/Library/Application Support/SketchUp 2025/SketchUp/Plugins/projeta_plus/encrypt_sketchup.rb'
```

**Aguarde**: Vai mostrar progresso
```
✓ Criptografado: main.rb -> main.rbs
✓ Criptografado: commands.rb -> commands.rbs
...
✅ Criptografia concluída!
📊 Arquivos criptografados: 20
```

### Passo 2️⃣: Gerar .rbz Criptografado

**Feche o SketchUp** e no terminal:
```bash
cd "/Users/lucaslauriano/Library/Application Support/SketchUp 2025/SketchUp/Plugins/projeta_plus"
./build_encrypted.sh
```

**Resultado**: 
```
📍 dist/projeta_plus_encrypted_v2.0.0.rbz
🔒 Código totalmente protegido!
```

---

## 🧪 Testar Versão Criptografada

1. **Desinstalar versão de desenvolvimento**
   - SketchUp > Window > Extension Manager
   - Desabilitar/Desinstalar "PROJETA PLUS"

2. **Instalar o .rbz criptografado**
   - Extension Manager > Install Extension
   - Selecionar: `dist/projeta_plus_encrypted_v2.0.0.rbz`

3. **Testar todas as funcionalidades**
   - Anotações
   - Iluminação
   - Configurações
   - Troca de idiomas

4. **Verificar se está criptografado**
   ```bash
   # Extrair .rbz para inspecionar
   unzip dist/projeta_plus_encrypted_v2.0.0.rbz -d test_extract
   cat test_extract/projeta_plus/main.rbs
   # Deve mostrar caracteres binários ilegíveis ✅
   ```

---

## 🔍 Comparação Visual

### Código Normal (.rb)
```ruby
# main.rb (legível)
module ProjetaPlus
  VERSION = "2.0.0".freeze
  
  def self.create_annotation(text)
    entity = Sketchup.active_model.active_entities.add_text(text)
  end
end
```

### Ofuscação Simples (.rb ofuscado)
```ruby
# main.rb (ofuscado, mas ainda .rb)
require 'base64'; require 'zlib'
_c = "eJzNV11P2zAUfc+vuGol2kioe6/EUAXlY+q2a..."
_d = Zlib::Inflate.inflate(Base64.strict_decode64(_c))
eval(_d)
```
⚠️ Pode ser decodificado com: `echo "_c" | base64 -d | zlib-decompress`

### Criptografia .rbs (SEGURO)
```
main.rbs (binário)
��PNG
  IHDR   [caracteres ilegíveis]
\x89\x50\x4E\x47\x0D\x0A\x1A\x0A...
```
✅ **Impossível de ler sem ferramentas avançadas de engenharia reversa**

---

## 📁 Estrutura dos Arquivos Gerados

```
projeta_plus/
├── dist/                          # Builds finais
│   ├── projeta_plus_v2.0.0.rbz              (normal)
│   └── projeta_plus_encrypted_v2.0.0.rbz    (criptografado)
│
├── encrypted_build/               # Arquivos .rbs
│   ├── main.rbs
│   ├── commands.rbs
│   └── ...
│
└── obfuscated_build/              # Ofuscação simples
    ├── main.rb (ofuscado)
    └── ...
```

---

## 🧹 Limpar Builds de Teste

```bash
cd "/Users/lucaslauriano/Library/Application Support/SketchUp 2025/SketchUp/Plugins/projeta_plus"

# Remover builds temporários
rm -rf encrypted_build/
rm -rf obfuscated_build/
rm -rf build_temp/
rm -rf test_extract/

# Manter apenas dist/ com .rbz finais
```

---

## ⚠️ IMPORTANTE: Backup dos Originais

**ANTES de distribuir versão criptografada:**

```bash
# Commit no Git
git add .
git commit -m "Version 2.0.0 - ready for production"
git tag v2.0.0
git push origin main --tags

# Backup adicional
tar -czf projeta_plus_source_v2.0.0.tar.gz \
  projeta_plus/ projeta_plus.rb \
  --exclude="*/encrypted_build" \
  --exclude="*/obfuscated_build" \
  --exclude="*/dist"

# Mover para local seguro (Dropbox, Drive, etc)
mv projeta_plus_source_v2.0.0.tar.gz ~/Dropbox/Backups/
```

**Por quê?**
- Arquivos .rbs são **irreversíveis**
- Se perder os .rb originais, não consegue editar mais
- Sempre mantenha 2+ backups em locais diferentes

---

## 🐛 Troubleshooting

### "Sketchup.scramble_script: undefined method"
**Problema**: Script rodando fora do SketchUp  
**Solução**: Execute no **Ruby Console do SketchUp**, não no terminal

### "encrypted_build/ não encontrado"
**Problema**: Esqueceu de criptografar antes do build  
**Solução**: Execute Passo 1 (criptografar no SketchUp) primeiro

### Plugin criptografado não carrega
**Problema**: Loader ainda aponta para `.rb`  
**Solução**: `build_encrypted.sh` já corrige isso automaticamente

### Erro ao testar .rbz criptografado
**Problema**: Algum arquivo não foi criptografado corretamente  
**Solução**: 
```bash
# Limpar e recomeçar
rm -rf encrypted_build/
# Criptografar novamente no SketchUp
# Build novamente
```

---

## 📊 Checklist Final

Antes de distribuir versão criptografada:

- [ ] Versão normal funciona 100%
- [ ] Backup dos .rb originais feito (Git + externo)
- [ ] Criptografia executada com sucesso (20 arquivos)
- [ ] Build criptografado gerado
- [ ] Testado em SketchUp limpo
- [ ] Todas funcionalidades testadas
- [ ] Verificado que arquivos são realmente .rbs (binários)
- [ ] Licença/EULA preparado
- [ ] Instruções de instalação para usuários prontas

---

## 📚 Documentos Relacionados

- **BUILD_README.md**: Como gerar builds normais
- **ENCRYPTION_GUIDE.md**: Guia completo de criptografia
- **PROTECTION_COMPARISON.md**: Comparação detalhada dos métodos
- **PRODUCTION_CHECKLIST.md**: Checklist de produção

---

## 💡 Dica Final

**Para Projeta Plus, recomendo**:

**Se for gratuito**: 
```bash
./build_simple.sh  # Transparência > Proteção
```

**Se for vender (R$50+)**:
```bash
# 1. Criptografar (SketchUp Console)
load 'encrypt_sketchup.rb'

# 2. Build
./build_encrypted.sh

# 3. Adicionar licenciamento online (ver PROTECTION_COMPARISON.md)
```

**Regra de ouro**: Proteção proporcional ao valor do plugin.

🎉 **Pronto para distribuir!**

