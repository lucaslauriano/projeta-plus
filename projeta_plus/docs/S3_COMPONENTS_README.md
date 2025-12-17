# ☁️ Sistema de Componentes S3 + Customizados

## 📋 Visão Geral

Sistema completo para gerenciar componentes SketchUp com duas fontes:

1. **Componentes do Sistema** - Armazenados no S3 (padrão do plugin)
2. **Componentes Customizados** - Upload do usuário (local + sincronização)

---

## 🏗️ Arquitetura

### Backend Ruby

```
projeta_plus/
├── build/
│   └── upload_to_s3.rb              # Script para upload ao S3
├── modules/
│   ├── pro_blocks.rb                # Gerenciador genérico (atualizado)
│   └── pro_s3_downloader.rb         # Download de componentes do S3
└── dialog_handlers/
    └── custom_components_handler.rb  # Handler para componentes customizados
```

### Frontend React

```
frontend/projeta-plus-html/
├── app/dashboard/
│   └── custom-components/
│       └── page.tsx                  # Interface de gerenciamento
├── hooks/
│   └── useCustomComponents.ts        # Hook para componentes customizados
└── types/
    └── global.d.ts                   # Tipos atualizados
```

---

## 🚀 Como Usar

### 1. Upload de Componentes Padrão para S3

#### Pré-requisitos

```bash
# Instalar AWS SDK
gem install aws-sdk-s3

# Configurar credenciais
export AWS_ACCESS_KEY_ID="sua-access-key"
export AWS_SECRET_ACCESS_KEY="sua-secret-key"
```

#### Executar Upload

```bash
cd build/
ruby upload_to_s3.rb
```

O script irá:
- Listar todos os arquivos .skp
- Pedir confirmação
- Fazer upload para S3 com metadados

### 2. Componentes Customizados (Usuário)

#### No Plugin

1. **Abrir Interface:**
   - Dashboard → Componentes Customizados

2. **Upload Individual:**
   - Clicar em "Upload Componente"
   - Selecionar arquivo .skp
   - Componente é salvo em `~/.projeta_plus/custom_components/`

3. **Sincronizar Pasta:**
   - Clicar em "Sincronizar Pasta"
   - Selecionar pasta com múltiplos .skp
   - Todos são copiados automaticamente

4. **Abrir Pasta:**
   - Clicar em "Abrir Pasta"
   - Abre `~/.projeta_plus/custom_components/` no explorador

---

## 📂 Estrutura de Pastas

### S3 Bucket

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

### Local (Componentes Customizados)

```
~/.projeta_plus/
└── custom_components/
    ├── Geral/*.skp
    ├── Meus Blocos/*.skp
    └── ...
```

---

## ⚙️ Configuração AWS S3

### 1. Criar Bucket

- Nome: `projeta-plus-components` (único globalmente)
- Região: `us-east-1` ou `sa-east-1`
- Bloquear acesso público: **Ativado**
- Versionamento: **Ativado**
- Criptografia: **SSE-S3**

### 2. IAM Policy (Mínima)

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::projeta-plus-components",
        "arn:aws:s3:::projeta-plus-components/*"
      ]
    }
  ]
}
```

### 3. Criar Usuário IAM

1. Nome: `projeta-plus-uploader`
2. Anexar policy acima
3. Gerar Access Key e Secret Key
4. Guardar credenciais com segurança

---

## 🔄 Fluxo de Dados

### Componentes do Sistema

```
Desenvolvedor → S3 (upload_to_s3.rb)
       ↓
   S3 Bucket
       ↓
Backend API (gera URL assinada)
       ↓
Plugin Ruby (download via S3Downloader)
       ↓
Cache Local (~/.projeta_plus/cache/)
       ↓
SketchUp Model
```

### Componentes Customizados

```
Usuário → Seletor de Arquivo
       ↓
Plugin Ruby (copia para pasta local)
       ↓
~/.projeta_plus/custom_components/
       ↓
SketchUp Model
```

---

## 🎨 Interface do Usuário

### Página de Componentes Customizados

- **Upload Componente** - Adicionar arquivo .skp individual
- **Sincronizar Pasta** - Importar pasta inteira
- **Abrir Pasta** - Acessar pasta de componentes
- **Lista de Componentes** - Ver e remover componentes
- **Accordion por Categoria** - Organização visual

---

## 🔧 API Ruby

### BlocksManager (Atualizado)

```ruby
# Carregar estrutura (sistema + customizados)
BlocksManager.get_blocks_structure(path, include_custom: true)

# Importar bloco (sistema ou customizado)
BlocksManager.import_block(path, components_path, source: 'custom')

# Upload de componente customizado
BlocksManager.upload_custom_component(file_path, category)

# Remover componente customizado
BlocksManager.delete_custom_component(block_path)

# Obter caminho de componentes customizados
BlocksManager.get_custom_components_path
```

### S3Downloader

```ruby
# Download de componente do S3
S3Downloader.download_component(s3_key, local_path)

# Limpar cache
S3Downloader.clear_cache

# Obter tamanho do cache
S3Downloader.get_cache_size
```

---

## 📡 API Frontend

### useCustomComponents Hook

```typescript
const {
  data,              // { groups: [...] }
  isBusy,            // boolean
  uploadComponent,   // (category: string) => void
  deleteComponent,   // (path: string) => void
  openCustomFolder,  // () => void
  syncFolder,        // () => void
} = useCustomComponents();
```

---

## 🔐 Segurança

### S3

- ✅ Bucket privado (sem acesso público)
- ✅ URLs assinadas (temporárias)
- ✅ Criptografia SSE-S3
- ✅ Versionamento ativado
- ✅ IAM com permissões mínimas

### Componentes Customizados

- ✅ Armazenamento local isolado
- ✅ Validação de extensão (.skp apenas)
- ✅ Confirmação antes de remover
- ✅ Sem acesso à rede (100% local)

---

## 📊 Benefícios

### Para o Desenvolvedor

- ✅ Componentes padrão centralizados no S3
- ✅ Atualizações fáceis (re-upload)
- ✅ Versionamento automático
- ✅ CDN global (baixa latência)

### Para o Usuário

- ✅ Componentes customizados próprios
- ✅ Upload simples (drag & drop futuro)
- ✅ Sincronização de pastas
- ✅ Gerenciamento visual
- ✅ Sem necessidade de internet (customizados)

---

## 🚧 Próximos Passos (Opcional)

1. **Backend API** - Criar endpoint para gerar URLs assinadas
2. **Drag & Drop** - Interface para arrastar arquivos
3. **Sincronização S3** - Upload de customizados para S3 do usuário
4. **Compartilhamento** - Compartilhar componentes entre usuários
5. **Marketplace** - Loja de componentes da comunidade

---

## 📝 Notas Técnicas

### Cache Local

- Localização: `~/.projeta_plus/cache/`
- Componentes do S3 são cacheados após primeiro download
- Reduz uso de banda e melhora performance

### Componentes Customizados

- Localização: `~/.projeta_plus/custom_components/`
- Estrutura de pastas livre (usuário define)
- Suporta subpastas ilimitadas

### Cross-Platform

- ✅ Windows: `%USERPROFILE%\.projeta_plus\`
- ✅ macOS: `~/.projeta_plus/`
- ✅ Linux: `~/.projeta_plus/`

---

## 🐛 Troubleshooting

### Upload para S3 falha

```bash
# Verificar credenciais
echo $AWS_ACCESS_KEY_ID
echo $AWS_SECRET_ACCESS_KEY

# Testar conexão
aws s3 ls s3://projeta-plus-components/
```

### Componentes customizados não aparecem

1. Verificar se a pasta existe: `~/.projeta_plus/custom_components/`
2. Verificar se há arquivos .skp na pasta
3. Recarregar plugin no SketchUp

### Cache muito grande

```ruby
# No Ruby Console do SketchUp
ProjetaPlus::Modules::S3Downloader.clear_cache
```

---

## 📚 Referências

- [AWS S3 Documentation](https://docs.aws.amazon.com/s3/)
- [SketchUp Ruby API](https://ruby.sketchup.com/)
- [BUILD_INSTRUCTIONS.md](build/BUILD_INSTRUCTIONS.md)

---

**Desenvolvido para ProjetaPlus** 🚀

