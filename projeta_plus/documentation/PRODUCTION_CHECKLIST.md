# Checklist de Produção - Projeta Plus

## ✅ Antes de Gerar o Build

### Código

- [ ] Remover todos os `puts` de debug (ou converter para logging condicional)
- [ ] Verificar se todos os arquivos `.backup` foram removidos
- [ ] Confirmar que não há código comentado desnecessário
- [ ] Testar todas as funcionalidades principais
- [ ] Verificar compatibilidade com versões do SketchUp (2019+)

### Arquivos

- [ ] Atualizar VERSION no `projeta_plus.rb`
- [ ] Verificar se todos os ícones estão presentes
- [ ] Confirmar que todos os arquivos de tradução (lang/\*.yml) estão completos
- [ ] Verificar se componentes SketchUp (.skp) estão incluídos

### Documentação

- [ ] Atualizar descrição da extensão
- [ ] Documentar novas features (se houver)
- [ ] Preparar release notes

## 🏗️ Gerando o Build

```bash
# Navegar até a pasta do plugin
cd "/Users/lucaslauriano/Library/Application Support/SketchUp 2025/SketchUp/Plugins/projeta_plus"

# Executar o script de build
ruby build_rbz.rb
```

## 📦 Arquivos Excluídos do Build

O script automaticamente exclui:

- `.DS_Store` e arquivos do macOS
- Arquivos `.git`
- Arquivos `.backup`
- Pasta `V_01/` (versão antiga)
- `BOOLEAN_USAGE_GUIDE.md`
- `PRODUCTION_CHECKLIST.md`
- `build_rbz.rb`

## 🧪 Testando o Build

1. **Desinstalar versão de desenvolvimento**

   - Window > Extension Manager
   - Desabilitar/Desinstalar Projeta Plus

2. **Instalar o .rbz gerado**

   - Window > Extension Manager > Install Extension
   - Selecionar `dist/projeta_plus_v2.0.0.rbz`

3. **Testar funcionalidades**

   - [ ] Anotação de ambientes
   - [ ] Anotação de seção
   - [ ] Anotação de teto
   - [ ] Iluminação
   - [ ] Conexão de circuitos
   - [ ] Indicação de vistas
   - [ ] Atualização de componentes
   - [ ] Configurações e idiomas

4. **Testar em versões diferentes do SketchUp**
   - [ ] SketchUp 2019
   - [ ] SketchUp 2020+
   - [ ] SketchUp 2025

## 🚀 Distribuição

### Opções de distribuição:

1. **Extension Warehouse** (oficial SketchUp)
2. **SketchUcation Plugin Store**
3. **Site próprio / GitHub Releases**
4. **Email direto para clientes**

## 📋 Pós-Release

- [ ] Criar tag de versão no Git
- [ ] Documentar bugs conhecidos
- [ ] Preparar suporte para usuários
- [ ] Monitorar feedback inicial
