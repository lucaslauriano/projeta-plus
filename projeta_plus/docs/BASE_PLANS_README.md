# Base Plans - Sistema de Configuração de Plantas Base e Forro

## Descrição

Sistema completo para gerenciar configurações de estilos e camadas para plantas de Base e Forro no InteliSket.

## Arquivos Criados/Modificados

### Backend (Ruby)

1. **`pro_base_plans.rb`** - Módulo Ruby principal
   - `get_base_plans` - Carrega configurações do JSON
   - `save_base_plans` - Salva configurações no JSON
   - `get_available_styles_for_base_plans` - Lista estilos da pasta styles/
   - `get_available_layers_for_base_plans` - Lista camadas do modelo

2. **`scenes_handlers.rb`** - Handler de callbacks
   - Registra os 4 métodos acima como callbacks do dialog

3. **Arquivos JSON**
   - `json_data/base_plans.json` - Configurações padrão
   - `json_data/user_base_plans.json` - Configurações do usuário

### Frontend (TypeScript/React)

1. **`hooks/useBasePlans.ts`** - Hook React customizado
   - Gerencia estado e comunicação com backend
   - Carrega dados automaticamente ao inicializar
   - Handlers para respostas do Ruby

2. **`components/base-plans-config-dialog.tsx`** - Componente de diálogo
   - Abas separadas para Base e Forro
   - Seleção de estilo
   - Gerenciamento de camadas com busca
   - Botões: Todos, Nenhum, Estado Atual

3. **`components/levels-manager-dialog.tsx`** - Integração
   - Botão "Configurar Plantas" no header
   - Integra o novo diálogo
   - Carrega e salva configurações

4. **`components/ui/tabs.tsx`** - Componente de abas
   - Novo componente criado para suportar as abas

5. **`types/global.d.ts`** - Tipos TypeScript
   - Handlers para window callbacks
   - Interfaces para Base Plans

## Estrutura de Dados

### Prioridade de Carregamento

O sistema carrega as configurações na seguinte ordem:

1. **`plans/json_data/user_base_plans.json`** (Prioridade 1 - Arquivo Dedicado)
   - Arquivo específico para configurações de Base e Forro
   - Formato simplificado com apenas estas duas plantas

2. **`plans/json_data/user_plans_data.json`** (Prioridade 2 - Fallback)
   - Busca por `planta_baixa` → mapeia para "Base"
   - Busca por `planta_cobertura` → mapeia para "Forro"
   - Usado se user_base_plans.json não existir

3. **`plans/json_data/base_plans.json`** (Prioridade 3 - Padrão)
   - Configurações padrão do sistema
   - Usado se nenhum dos anteriores existir

4. **Criar Padrão** (Última opção)
   - Gera configurações básicas em memória
   - Salva em user_base_plans.json para uso futuro

### Estrutura no user_base_plans.json (Arquivo Principal)

```json
{
  "plans": [
    {
      "id": "base",
      "name": "Base",
      "style": "FM_PLANTAS",
      "activeLayers": ["Layer0", "Walls", "Floor", ...]
    },
    {
      "id": "ceiling",
      "name": "Forro",
      "style": "FM_PLANTAS",
      "activeLayers": ["Layer0", "Ceiling", ...]
    }
  ]
}
```

### Estrutura no user_plans_data.json (Fallback 1)

```json
{
  "groups": [...],
  "plans": [
    {
      "id": "planta_baixa",
      "name": "Base",
      "style": "FM_PLANTAS",
      "cameraType": "topo_ortogonal",
      "activeLayers": ["Layer0", "Walls", "Floor", ...]
    },
    {
      "id": "planta_cobertura",
      "name": "Forro",
      "style": "FM_PLANTAS",
      "cameraType": "topo_ortogonal",
      "activeLayers": ["Layer0", "Ceiling", ...]
    }
  ]
}
```

### Estrutura no base_plans.json (Fallback 2)

```json
{
  "plans": [
    {
      "id": "base",
      "name": "Base",
      "style": "FM_VISTAS",
      "activeLayers": ["Layer0"]
    },
    {
      "id": "ceiling",
      "name": "Forro",
      "style": "FM_VISTAS",
      "activeLayers": ["Layer0"]
    }
  ]
}
```

## Fluxo de Funcionamento

1. **Ao abrir o Gerenciador de Níveis:**
   - Hook `useBasePlans` é inicializado
   - Chama automaticamente:
     - `getBasePlans` → carrega configurações
     - `getAvailableStylesForBasePlans` → lista estilos da pasta
     - `getAvailableLayersForBasePlans` → lista camadas do modelo

2. **Ao clicar em "Configurar Plantas":**
   - Abre dialog com abas Base e Forro
   - Mostra estilos disponíveis da pasta `styles/`
   - Mostra camadas existentes no modelo

3. **Ao editar e salvar:**
   - Frontend chama `saveBasePlans` com novos dados
   - Backend atualiza/adiciona as entradas em `user_plans_data.json`:
     - "base" → salvo como "planta_baixa"
     - "ceiling" → salvo como "planta_cobertura"
   - Frontend recebe confirmação e recarrega dados

## Como Usar

### No SketchUp

1. Abrir o Gerenciador de Níveis
2. Clicar no botão "Configurar Plantas" (ícone de engrenagem)
3. Selecionar aba "Planta Base" ou "Planta de Forro"
4. Escolher estilo desejado
5. Selecionar camadas que devem estar visíveis
6. Clicar em "Salvar Configurações"

### Logs de Debug

Para verificar o funcionamento, abra o Console do Navegador (F12):

```
[useBasePlans] Carregando dados iniciais...
[useBasePlans] Salvando plantas: [...]
[useBasePlans] Resposta do save: { success: true, ... }
[LevelsManagerDialog] Salvando configurações: [...]
```

No Ruby Console do SketchUp:
```
Estilos encontrados: FM_VISTAS, FM_PLANTAS, ...
Camadas encontradas: Layer0, Walls, Floor, ...
Base plans salvas com sucesso em: ...
```

## Integração com Níveis

As configurações de Base Plans são usadas ao criar plantas base e forro através do Gerenciador de Níveis. Quando um usuário:

1. Clica em "Base" ou "Forro" para um nível
2. O sistema usa as configurações salvas em `user_base_plans.json`
3. Aplica o estilo e camadas configurados
4. Cria o plano de seção automaticamente

## Manutenção

### Adicionar novo estilo
1. Adicionar arquivo `.style` na pasta `modules/inteli-skt/styles/`
2. O estilo aparecerá automaticamente na lista

### Resetar para padrão
1. No `user_plans_data.json`, remover ou editar as entradas:
   - `planta_baixa`
   - `planta_cobertura`
2. Ou criar/editar `base_plans.json` com configurações desejadas
3. Reabrir o diálogo
4. Configurações serão carregadas do fallback

## Arquivos Relacionados

- Backend: `modules/inteli-skt/plans/pro_base_plans.rb`
- Handler: `dialog_handlers/scenes_handlers.rb`
- Hook: `frontend/projeta-plus-html/hooks/useBasePlans.ts`
- Dialog: `frontend/projeta-plus-html/app/dashboard/inteli-sket/components/base-plans-config-dialog.tsx`
- Integração: `frontend/projeta-plus-html/app/dashboard/inteli-sket/components/levels-manager-dialog.tsx`

