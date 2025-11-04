# 📦 Instruções de Build - Projeta Plus

## ✅ Build Ofuscado (Recomendado)

### Como gerar:

```bash
cd '/Users/lucaslauriano/Library/Application Support/SketchUp 2025/SketchUp/Plugins/projeta_plus/build'
./build_obfuscated.sh
```

No Windows (PowerShell):

```powershell
cd "C:\Users\<YOU>\AppData\Roaming\SketchUp\SketchUp 2025\SketchUp\Plugins\projeta_plus\build"
./build_obfuscated.ps1
```

O arquivo será criado em: `dist/projeta_plus_obfuscated_v2.0.0.rbz`

### O que faz:

- ✅ Remove comentários
- ✅ Minifica espaços (redução ~15-35%)
- ✅ Preserva APIs públicas
- ✅ Preserva callbacks do frontend
- ✅ Frontend funciona normalmente
- ✅ Remove diretórios temporários automaticamente
- ⚠️ Código ainda é legível (ofuscação leve)

---

## 🔒 Build Criptografado (Não funciona no SketchUp 2025)

SketchUp 2025 **removeu** a API `Sketchup.scramble_script`.

**Não é possível** gerar arquivos `.rbs` criptografados.

**Alternativas:**

- Use SketchUp 2023 (última versão com suporte)
- Use build ofuscado (atual)

---

## 📋 Arquivos Gerados

### Após Build:

- `dist/projeta_plus_obfuscated_v2.0.0.rbz` - Pronto para distribuir

**Nota:** Diretórios temporários (`obfuscated_build/`, `encrypted_build/`) são removidos automaticamente após o build.

---

## 🧪 Como Testar

1. Abra SketchUp
2. `Window > Extension Manager`
3. `Install Extension...`
4. Selecione: `dist/projeta_plus_obfuscated_v2.0.0.rbz`
5. Teste todas as funcionalidades

---

## 🔄 Gerar Novo Build

Para regenerar após mudanças no código:

```bash
cd build/

# 1. Ofuscar novamente (opcional, build_obfuscated.sh já faz isso)
ruby obfuscate.rb

# 2. Gerar .rbz
./build_obfuscated.sh
```

Ou tudo de uma vez:

```bash
cd build/
./build_obfuscated.sh
```

Windows (PowerShell):

```powershell
cd build
./build_obfuscated.ps1
```

(O script executa a ofuscação automaticamente se necessário)

---

## ⚙️ Personalizar Versão

Edite `build_obfuscated.sh`:

```bash
VERSION="2.0.1"  # Altere aqui
```

---

## 📊 Comparação: Original vs Ofuscado

| Aspecto        | Original | Ofuscado   |
| -------------- | -------- | ---------- |
| Tamanho        | 100%     | ~65-85%    |
| Comentários    | ✅       | ❌         |
| Espaços        | Normal   | Minificado |
| Legibilidade   | Alta     | Baixa      |
| Funcionalidade | 100%     | 100%       |
| Frontend       | ✅       | ✅         |

---

## ⚠️ Importante

- **Sempre** teste o .rbz antes de distribuir
- **Mantenha** os arquivos .rb originais seguros
- **Não** commite `obfuscated_build/` no git
- **Versione** os .rbz gerados

---

## 🚫 Arquivos Ignorados na Ofuscação

- `obfuscated_build/`
- `encrypted_build/`
- `build_*.sh`
- `obfuscate.rb`
- `encrypt_*.rb`
- Arquivos `.backup`
