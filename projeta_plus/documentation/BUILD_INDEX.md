# 📦 Índice de Build e Proteção - Projeta Plus

## 🎯 Start Aqui

**Primeira vez?** → Leia **[QUICK_START.md](QUICK_START.md)**

**Quer proteger o código?** → Leia **[PROTECTION_COMPARISON.md](PROTECTION_COMPARISON.md)**

---

## 📚 Documentação

| Arquivo                                                      | Descrição                              |
| ------------------------------------------------------------ | -------------------------------------- |
| **[QUICK_START.md](QUICK_START.md)**                         | ⭐ Guia rápido: 3 métodos de build     |
| **[BUILD_README.md](BUILD_README.md)**                       | Como gerar .rbz normal (sem proteção)  |
| **[ENCRYPTION_GUIDE.md](ENCRYPTION_GUIDE.md)**               | Guia completo de criptografia .rbs     |
| **[PROTECTION_COMPARISON.md](PROTECTION_COMPARISON.md)**     | Comparação: Aberto vs Ofuscado vs .rbs |
| **[PRODUCTION_CHECKLIST.md](PRODUCTION_CHECKLIST.md)**       | Checklist antes de distribuir          |
| **[PRODUCTION_IMPROVEMENTS.md](PRODUCTION_IMPROVEMENTS.md)** | Melhorias para código de produção      |

---

## 🛠️ Scripts de Build

### Build Normal (Código Aberto)

```bash
./build_simple.sh          # ⭐ Recomendado: rápido, sem dependências
ruby build_rbz.rb          # Alternativa: precisa da gem rubyzip
```

**Gera**: `dist/projeta_plus_v2.0.0.rbz` (código visível)

### Build Criptografado (.rbs)

```bash
# 1. No SketchUp Ruby Console:
load 'encrypt_sketchup.rb'

# 2. No terminal:
./build_encrypted.sh
```

**Gera**: `dist/projeta_plus_encrypted_v2.0.0.rbz` (código protegido)

### Build Ofuscado (Base64)

```bash
ruby obfuscate_simple.rb   # Gera arquivos ofuscados
# Então usar build_simple.sh com arquivos ofuscados
```

**Gera**: `obfuscated_build/` com .rb ofuscados

---

## 🔧 Ferramentas Auxiliares

| Script            | Função                                          |
| ----------------- | ----------------------------------------------- |
| `clean_builds.sh` | Limpa builds temporários                        |
| `auto_encrypt.sh` | [Experimental] Auto-abre SketchUp e criptografa |
| `encrypt_rb.rb`   | Gera comandos de criptografia                   |

---

## 📊 Fluxograma de Decisão

```
Você vai distribuir o Projeta Plus?
│
├─ Gratuitamente / Open Source
│  └─→ ./build_simple.sh
│     (Código aberto, gera confiança)
│
├─ Comercialmente (< R$50)
│  └─→ ruby obfuscate_simple.rb OU .rbs
│     (Proteção básica/média)
│
└─ Comercialmente (R$50+) / B2B
   └─→ Método .rbs + Licenciamento
      (Proteção máxima)

      Passos:
      1. load 'encrypt_sketchup.rb' (SketchUp)
      2. ./build_encrypted.sh
      3. Adicionar sistema de licenças
```

---

## 📁 Estrutura de Arquivos

```
projeta_plus/
│
├── 📄 BUILD/PROTEÇÃO
│   ├── build_simple.sh              ⭐ Build rápido (normal)
│   ├── build_rbz.rb                 Build normal (Ruby)
│   ├── build_encrypted.sh           Build criptografado
│   ├── encrypt_sketchup.rb          Criptografa para .rbs
│   ├── encrypt_rb.rb                Gera comandos de criptografia
│   ├── obfuscate_simple.rb          Ofuscação Base64
│   ├── auto_encrypt.sh              Auto-criptografia
│   └── clean_builds.sh              Limpar temporários
│
├── 📖 DOCUMENTAÇÃO
│   ├── QUICK_START.md               ⭐ START AQUI
│   ├── BUILD_README.md              Builds normais
│   ├── ENCRYPTION_GUIDE.md          Criptografia .rbs
│   ├── PROTECTION_COMPARISON.md     Comparação de métodos
│   ├── PRODUCTION_CHECKLIST.md      Checklist de produção
│   ├── PRODUCTION_IMPROVEMENTS.md   Melhorias de código
│   └── BUILD_INDEX.md               📍 VOCÊ ESTÁ AQUI
│
├── 📦 OUTPUTS
│   └── dist/
│       ├── projeta_plus_v2.0.0.rbz             (normal)
│       └── projeta_plus_encrypted_v2.0.0.rbz   (criptografado)
│
└── 🔧 CÓDIGO FONTE
    ├── projeta_plus.rb              Loader principal
    ├── main.rb                      Entry point
    ├── commands.rb                  Comandos
    ├── core.rb                      UI
    ├── localization.rb              i18n
    ├── modules/                     Funcionalidades
    ├── dialog_handlers/             Handlers
    ├── components/                  Componentes SketchUp
    ├── icons/                       Ícones
    └── lang/                        Traduções
```

---

## 🚀 Comandos Rápidos

### Build Normal

```bash
cd "/Users/lucaslauriano/Library/Application Support/SketchUp 2025/SketchUp/Plugins/projeta_plus"
./build_simple.sh
```

### Build Criptografado (Completo)

```bash
# Terminal 1: Preparar
cd "/Users/lucaslauriano/Library/Application Support/SketchUp 2025/SketchUp/Plugins/projeta_plus"

# Terminal 2: Abrir SketchUp e no Ruby Console:
load '/Users/lucaslauriano/Library/Application Support/SketchUp 2025/SketchUp/Plugins/projeta_plus/encrypt_sketchup.rb'

# Terminal 1: Após criptografia concluir
./build_encrypted.sh
```

### Limpar Tudo

```bash
./clean_builds.sh
```

---

## 📊 Comparação Rápida

| Método       | Comando                        | Segurança | Tempo | Reversível |
| ------------ | ------------------------------ | --------- | ----- | ---------- |
| **Normal**   | `./build_simple.sh`            | 0/10      | 5s    | ✅ Sim     |
| **Ofuscado** | `ruby obfuscate_simple.rb`     | 3/10      | 10s   | ⚠️ Fácil   |
| **.rbs** ⭐  | `encrypt + build_encrypted.sh` | 8/10      | 30s   | ❌ Difícil |

---

## ⚠️ Avisos Importantes

### Antes de Criptografar:

- [ ] **BACKUP**: Git commit + push
- [ ] **BACKUP EXTERNO**: Tar.gz para Drive/Dropbox
- [ ] **TESTE**: Versão normal funciona 100%

### Após Criptografar:

- [ ] **TESTE**: Instalar .rbz criptografado e testar tudo
- [ ] **VERIFIQUE**: Arquivos são realmente .rbs (binários)
- [ ] **MANTENHA ORIGINAIS**: Nunca delete os .rb

### ⚡ Regra de Ouro:

> "Criptografia é IRREVERSÍVEL. Sempre mantenha 2+ backups dos originais."

---

## 🆘 Problemas Comuns

| Problema                              | Solução                                                |
| ------------------------------------- | ------------------------------------------------------ |
| Script não executa                    | `chmod +x nome_do_script.sh`                           |
| "Sketchup.scramble_script: undefined" | Executar no Ruby Console do **SketchUp**, não terminal |
| Build criptografado falha             | Criptografar primeiro no SketchUp                      |
| Plugin não carrega                    | Testar versão normal primeiro                          |
| Arquivos .rbs legíveis                | Criptografia falhou, refazer                           |

---

## 📈 Workflow Recomendado

### Desenvolvimento

```bash
# Trabalhar nos .rb normais
# Testar no SketchUp (development install)
# Commits frequentes no Git
```

### Pre-Release

```bash
git commit -am "Prepare v2.0.0"
git tag v2.0.0
git push origin main --tags

# Backup
tar -czf projeta_plus_v2.0.0_source.tar.gz projeta_plus/ projeta_plus.rb
```

### Release (Gratuito)

```bash
./build_simple.sh
# Distribuir: dist/projeta_plus_v2.0.0.rbz
```

### Release (Comercial)

```bash
# 1. Criptografar (SketchUp)
load 'encrypt_sketchup.rb'

# 2. Build
./build_encrypted.sh

# 3. Testar
# Instalar e testar tudo!

# 4. Distribuir
# dist/projeta_plus_encrypted_v2.0.0.rbz
```

---

## 🎓 Recursos Adicionais

- [SketchUp Developer Center](https://extensions.sketchup.com/developer_center)
- [Extension Warehouse](https://extensions.sketchup.com/)
- [SketchUcation](https://sketchucation.com/)

---

## 📝 Versionamento

Ao lançar nova versão:

1. **Atualizar VERSION** em `projeta_plus.rb`
2. **Atualizar CHANGELOG** (criar se não existir)
3. **Git tag**: `git tag v2.0.1`
4. **Build**: escolher método apropriado
5. **Testar**: instalar e verificar
6. **Distribuir**: Extension Warehouse ou direto

---

## 💡 Dica Final

**90% dos plugins SketchUp usam código aberto**. Criptografia é mais para:

- Plugins comerciais premium
- Soluções enterprise/B2B
- Algoritmos proprietários únicos

Para **Projeta Plus**:

- **Gratuito**: Código aberto (gera comunidade)
- **Pago**: .rbs + licenciamento online

**Não deixe a proteção complicar o desenvolvimento!** ✨

---

**Criado para facilitar builds e distribuição do Projeta Plus** 🚀
