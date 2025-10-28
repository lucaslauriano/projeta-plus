# 📦 Como Gerar o .rbz do Projeta Plus

## Opção 1: Script Bash (Recomendado para macOS/Linux)

```bash
cd "/Users/lucaslauriano/Library/Application Support/SketchUp 2025/SketchUp/Plugins/projeta_plus"
./build_simple.sh
```

**Requisitos**: Nenhum (usa ferramentas nativas do macOS)

## Opção 2: Script Ruby (Multiplataforma)

```bash
cd "/Users/lucaslauriano/Library/Application Support/SketchUp 2025/SketchUp/Plugins/projeta_plus"
gem install rubyzip
ruby build_rbz.rb
```

**Requisitos**: gem `rubyzip`

## Opção 3: Manual

1. **Criar estrutura temporária**

   ```bash
   mkdir build_temp
   ```

2. **Copiar arquivos necessários**

   ```bash
   cp ../projeta_plus.rb build_temp/
   rsync -av --exclude='*.backup' --exclude='V_01/' --exclude='build_temp/' \
     --exclude='dist/' --exclude='*.sh' --exclude='*.md' ./ build_temp/projeta_plus/
   ```

3. **Criar o .rbz**

   ```bash
   cd build_temp
   zip -r ../dist/projeta_plus_v2.0.0.rbz .
   ```

4. **Limpar**
   ```bash
   cd ..
   rm -rf build_temp
   ```

## 📂 Estrutura do .rbz Final

```
projeta_plus_v2.0.0.rbz
├── projeta_plus.rb                    # Loader principal
└── projeta_plus/
    ├── main.rb                        # Entry point
    ├── core.rb                        # UI
    ├── commands.rb                    # Comandos
    ├── localization.rb                # i18n
    ├── components/                    # Componentes SketchUp
    │   ├── Indicação de Vistas.skp
    │   ├── Nível Planta.skp
    │   └── proViewIndication_abcd.skp
    ├── dialog_handlers/               # Handlers de diálogo
    ├── icons/                         # Ícones
    ├── lang/                          # Traduções
    │   ├── en.yml
    │   ├── es.yml
    │   └── pt-BR.yml
    └── modules/                       # Módulos funcionais
        ├── annotation/
        ├── settings/
        └── view/
```

## 🎯 Após Gerar o .rbz

O arquivo será criado em: `../dist/projeta_plus_v2.0.0.rbz`

### Instalar no SketchUp

1. Abra o SketchUp
2. **Window** > **Extension Manager**
3. Clique em **Install Extension**
4. Selecione o arquivo `.rbz`
5. Reinicie o SketchUp

### Testar a Instalação

1. Verifique se o menu "PROJETA PLUS" aparece
2. Teste as funcionalidades principais
3. Verifique a troca de idiomas em Settings

## 🚀 Distribuição

### Extension Warehouse (oficial SketchUp)

- Cadastre-se como desenvolvedor em: https://extensions.sketchup.com
- Faça upload do .rbz e forneça screenshots/descrição
- Processo de aprovação leva ~1-2 semanas

### SketchUcation Plugin Store

- Cadastre-se em: https://sketchucation.com/pluginstore
- Faça upload do .rbz

### GitHub Releases

```bash
# Criar tag de versão
git tag -a v2.0.0 -m "Release v2.0.0"
git push origin v2.0.0

# Fazer upload do .rbz como asset da release
```

## 🔧 Troubleshooting

### Erro: "rsync: command not found"

No macOS, instale Xcode Command Line Tools:

```bash
xcode-select --install
```

### Erro: "zip: command not found"

O `zip` vem pré-instalado no macOS. Se não estiver disponível:

```bash
brew install zip
```

### Arquivo .rbz muito grande

Verifique se você excluiu:

- Pasta `V_01/` (versão antiga)
- Arquivos `.backup`
- Arquivos `__MACOSX`

### SketchUp não reconhece o .rbz

Certifique-se de que:

- O arquivo `projeta_plus.rb` está na raiz do .rbz
- A pasta `projeta_plus/` está na raiz do .rbz
- Não há pastas extras envolvendo o conteúdo
