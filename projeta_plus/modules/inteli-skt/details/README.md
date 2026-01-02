# Módulo de Detalhamento (ProDetails)

Módulo para criação e gerenciamento de detalhamentos técnicos no SketchUp, integrado ao sistema Inteli-Skt.

## Funcionalidades

### 1. Detalhamento de Marcenaria (`create_carpentry_detail`)

Cria uma camada de detalhamento para um grupo ou componente selecionado.

**Uso:**

- Selecione um único grupo ou componente
- Execute `create_carpentry_detail`
- Uma nova camada `-DET-N` será criada automaticamente (onde N é um número sequencial)

**Retorno:**

```ruby
{
  success: true,
  message: "Detalhe -DET-1 criado.",
  layer_name: "-DET-1"
}
```

### 2. Detalhamento Geral (`create_general_details`)

Cria ou atualiza cenas para todas as camadas de detalhamento existentes.

**Comportamento:**

- Busca todas as camadas que começam com `-DET-`
- Para cada camada, cria/atualiza uma cena correspondente
- Configura câmera isométrica ortográfica
- Oculta todas as outras camadas de detalhamento
- Ajusta zoom para extents

**Retorno:**

```ruby
{
  success: true,
  message: "3 cena(s) criada(s)/atualizada(s).",
  count: 3
}
```

### 3. Obter Estilos

Lista todos os estilos disponíveis no modelo atual.

**Retorno:**

```ruby
{
  success: true,
  styles: ["PRO_PLANTAS", "PRO_CORTES", "PRO_VISTAS"],
  message: "3 estilos encontrados"
}
```

### 4. Duplicar Cenas (`duplicate_scene`)

Duplica a cena atual aplicando um novo estilo e sufixo.

**Requisitos:**

- Cena atual deve começar com `det-`
- Estilo deve existir no modelo
- Sufixo não pode estar vazio

**Parâmetros:**

```json
{
  "estilo": "PRO_PLANTAS",
  "sufixo": "planta"
}
```

**Retorno:**

```ruby
{
  success: true,
  message: "Cena 'det-1-planta' criada com sucesso.",
  scene_name: "det-1-planta"
}
```

### 5. Alternar Vista (`toggle_perspective`)

Alterna entre 4 ângulos de câmera isométrica predefinidos.

**Ângulos:**

1. `[1000, 1000, 1000]` - Frontal direita superior
2. `[-1000, 1000, 1000]` - Frontal esquerda superior
3. `[-1000, -1000, 1000]` - Traseira esquerda superior
4. `[1000, -1000, 1000]` - Traseira direita superior

**Retorno:**

```ruby
{
  success: true,
  message: "Vista alternada para ângulo 2.",
  angle_index: 1
}
```

## Integração Frontend

### Hook: `useDetails`

```typescript
import { useDetails } from '@/hooks/useDetails';

const {
  styles, // string[] - Lista de estilos disponíveis
  isProcessing, // boolean - Estado de carregamento
  isAvailable, // boolean - SketchUp disponível
  createCarpentryDetail, // () => Promise<boolean>
  createGeneralDetails, // () => Promise<boolean>
  getStyles, // () => Promise<boolean>
  duplicateScene, // (style, suffix) => Promise<boolean>
  togglePerspective, // () => Promise<boolean>
} = useDetails();
```

### Componente: `DetailsComponent`

Localizado em: `app/dashboard/inteli-sket/components/details.tsx`

**Funcionalidades:**

- Botões para todas as operações de detalhamento
- Modal para duplicação de cenas com seleção de estilo
- Feedback visual com toasts
- Estados de loading

## Estrutura de Arquivos

```
inteli-skt/details/
├── pro_details.rb          # Módulo Ruby principal
└── README.md              # Esta documentação

frontend/
├── hooks/
│   └── useDetails.ts      # Hook React
└── app/dashboard/inteli-sket/components/
    └── details.tsx        # Componente UI
```

## Fluxo de Comunicação

```
Frontend (React)
    ↓ callSketchupMethod('createCarpentryDetail')
Dialog Handler (Ruby)
    ↓ @dialog.add_action_callback("createCarpentryDetail")
    ↓ ProjetaPlus::Modules::ProDetails.create_carpentry_detail
Módulo ProDetails (Ruby)
    ↓ Valida parâmetros
    ↓ Executa operação no SketchUp (transacional)
    ↓ Retorna resultado { success, message, data }
Dialog Handler
    ↓ send_json_response('handleCreateCarpentryDetailResult', result)
Frontend
    ↓ window.handleCreateCarpentryDetailResult(result)
Hook useDetails
    ↓ Atualiza estado e exibe toast
```

## Padrões Seguidos

Este módulo segue os padrões estabelecidos em `new_module.md`:

### Estrutura do Código Ruby

- ✅ Encoding UTF-8 na primeira linha
- ✅ Seção de configurações e constantes
- ✅ Métodos públicos em inglês (snake_case)
- ✅ Métodos privados para validação e auxiliares
- ✅ Operações transacionais (`start_operation`, `commit_operation`)
- ✅ Retorno padronizado: `{ success: Boolean, message: String, data: Hash }`
- ✅ Validação de parâmetros antes de processar
- ✅ Tratamento de erros com `rescue` e mensagens claras
- ✅ Documentação inline com `@param` e `@return`

### Métodos Públicos

| Método Ruby               | Callback Frontend       | Handler Response                    | Descrição                     |
| ------------------------- | ----------------------- | ----------------------------------- | ----------------------------- |
| `create_carpentry_detail` | `createCarpentryDetail` | `handleCreateCarpentryDetailResult` | Cria camada de detalhamento   |
| `create_general_details`  | `createGeneralDetails`  | `handleCreateGeneralDetailsResult`  | Cria cenas para todas camadas |
| `get_styles`              | `getStyles`             | `handleGetStylesResult`             | Lista estilos disponíveis     |
| `duplicate_scene`         | `duplicateScene`        | `handleDuplicateSceneResult`        | Duplica cena com novo estilo  |
| `toggle_perspective`      | `togglePerspective`     | `handleTogglePerspectiveResult`     | Alterna ângulo de câmera      |

### Métodos Privados

- `validate_single_entity_selection` - Valida seleção única
- `generate_unique_layer_name` - Gera nome único para camada
- `get_detail_layers` - Retorna camadas de detalhamento
- `create_or_update_scene_for_layer` - Cria/atualiza cena
- `validate_duplicate_params` - Valida parâmetros de duplicação

## Convenções

### Nomenclatura de Camadas

- Prefixo: `-DET-`
- Formato: `-DET-N` (onde N é sequencial: 1, 2, 3...)

### Nomenclatura de Cenas

- Formato: `det-N` (lowercase, sem o prefixo `-`)
- Exemplo: camada `-DET-1` → cena `det-1`

### Duplicação de Cenas

- Formato: `{nome-original}-{sufixo}`
- Exemplo: `det-1` + sufixo `planta` → `det-1-planta`

## Tratamento de Erros

Todos os métodos retornam um hash com:

- `success`: boolean
- `message`: string descritiva
- Dados adicionais específicos do método

Erros comuns:

- Nenhum modelo ativo
- Seleção inválida (para marcenaria)
- Nenhuma camada de detalhamento encontrada
- Cena com nome duplicado
- Estilo não encontrado

## Exemplo de Uso Completo

```typescript
// 1. Criar detalhamento de marcenaria
await createCarpentryDetail();
// → Cria camada -DET-1

// 2. Criar cenas de detalhamento
await createGeneralDetails();
// → Cria cena det-1

// 3. Obter estilos disponíveis
await getStyles();
// → Popula array 'styles'

// 4. Duplicar cena com novo estilo
await duplicateScene('PRO_PLANTAS', 'planta');
// → Cria cena det-1-planta

// 5. Alternar vista
await togglePerspective();
// → Muda para próximo ângulo
```

## Dependências

- `ProjetaPlus::DialogHandlers::DetailsHandler`
- `ProjetaPlus::Modules::ProDetails`
- Hook `useSketchup` (contexto)
- Componentes Shadcn/UI (Dialog, Button, Input, Select)
