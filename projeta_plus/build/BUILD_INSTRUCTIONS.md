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

---

## ☁️ Upload de Componentes para S3

### Pré-requisitos

1. **Conta AWS** com acesso ao S3
2. **Bucket S3** criado (ex: `projeta-plus-components`)
3. **Credenciais IAM** com permissões S3

### Configurar Credenciais AWS

**macOS/Linux:**

```bash
export AWS_ACCESS_KEY_ID="sua-access-key"
export AWS_SECRET_ACCESS_KEY="sua-secret-key"
```

**Windows (PowerShell):**

```powershell
$env:AWS_ACCESS_KEY_ID="sua-access-key"
$env:AWS_SECRET_ACCESS_KEY="sua-secret-key"
```

### Instalar AWS SDK

```bash
gem install aws-sdk-s3
```

### Executar Upload

```bash
cd build/
ruby upload_to_s3.rb
```

O script irá:

1. Listar todos os arquivos .skp que serão enviados
2. Pedir confirmação
3. Fazer upload para S3 com metadados

### Estrutura no S3

```
projeta-plus-components/
├── eletrical/
│   ├── Geral/*.skp
│   ├── Banheiro/*.skp
│   └── ...
├── lightning/
│   └── Geral/*.skp
└── baseboards/
    └── Geral/*.skp
```

### Configurar Bucket S3

1. **Criar Bucket:**

   - Nome: `projeta-plus-components` (único globalmente)
   - Região: `us-east-1` ou `sa-east-1` (Brasil)

2. **Configurações:**

   - Bloquear acesso público: **Ativado**
   - Versionamento: **Ativado**
   - Criptografia: **SSE-S3**

3. **IAM Policy (mínima):**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:PutObject", "s3:GetObject", "s3:ListBucket"],
      "Resource": [
        "arn:aws:s3:::projeta-plus-components",
        "arn:aws:s3:::projeta-plus-components/*"
      ]
    }
  ]
}
```

### Verificar Upload

```bash
# Listar arquivos no bucket
aws s3 ls s3://projeta-plus-components/ --recursive
```

---
