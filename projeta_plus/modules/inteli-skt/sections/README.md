# ProSections Module

Módulo para gerenciamento de planos de seção (section planes) no SketchUp.

## Funcionalidades

### CRUD de Seções

- **get_sections**: Retorna todas as section planes do modelo
- **add_section**: Adiciona nova section plane com posição e direção
- **update_section**: Atualiza section plane existente
- **delete_section**: Remove section plane do modelo

### Criação Automática de Seções

#### 1. Cortes Padrões (A, B, C, D)

```ruby
ProjetaPlus::Modules::ProSections.create_standard_sections
```

Cria 4 cortes padrões baseados no centro do modelo:

- **A**: Frente (direção Y+)
- **B**: Esquerda (direção X+)
- **C**: Voltar (direção Y-)
- **D**: Direita (direção X-)

Cada corte é criado em sua própria layer `-CORTES-[LETRA]`.

#### 2. Vistas Automáticas

```ruby
ProjetaPlus::Modules::ProSections.create_auto_views
```

Cria 4 vistas baseadas no objeto selecionado:

- Solicita nome do ambiente ao usuário
- Cria cortes ao redor do bounding box do objeto
- Nomenclatura: `{ambiente}_a`, `{ambiente}_b`, etc.
- Todos os cortes ficam na layer `-CORTES-{AMBIENTE}`

#### 3. Corte Individual

```ruby
ProjetaPlus::Modules::ProSections.create_individual_section({
  directionType: 'frente', # ou 'esquerda', 'voltar', 'direita'
  name: 'Cozinha'
})
```

Cria um único corte com direção específica.

### Persistência JSON

#### Estrutura do JSON

```json
{
  "sections": [
    {
      "id": "A",
      "name": "A",
      "position": [0, 40, 0],
      "direction": [0, 1, 0],
      "active": false
    }
  ]
}
```

#### Métodos

- **save_to_json**: Salva configurações em `user_sections_data.json`
- **load_from_json**: Carrega de `user_sections_data.json` ou `sections_data.json`
- **load_default_data**: Força carregamento de `sections_data.json`
- **load_from_file**: Abre dialog para selecionar arquivo JSON
- **import_to_model**: Importa seções do JSON para o modelo

## Frontend

### Hook: useSections

```typescript
const {
  data,
  isBusy,
  getSections,
  createStandardSections,
  createAutoViews,
  createIndividualSection,
  deleteSection,
  saveToJson,
  loadFromJson,
  // ...
} = useSections();
```

### Componente: sections.tsx

Interface completa para gerenciamento de seções:

- Botões para criar cortes padrões
- Botão para vistas automáticas (requer seleção)
- Dialog para corte individual
- Lista de seções existentes no modelo
- Gerenciamento de dados (salvar/carregar/importar)

## Callbacks Ruby ↔ JavaScript

### Ruby → JS

- `handleGetSectionsResult`
- `handleAddSectionResult`
- `handleUpdateSectionResult`
- `handleDeleteSectionResult`
- `handleCreateStandardSectionsResult`
- `handleCreateAutoViewsResult`
- `handleCreateIndividualSectionResult`
- `handleSaveSectionsToJsonResult`
- `handleLoadSectionsFromJsonResult`
- `handleLoadDefaultSectionsResult`
- `handleLoadSectionsFromFileResult`
- `handleImportSectionsToModelResult`

### JS → Ruby

- `getSections()`
- `addSection(params)`
- `updateSection(params)`
- `deleteSection(params)`
- `createStandardSections()`
- `createAutoViews()`
- `createIndividualSection(params)`
- `saveSectionsToJson(data)`
- `loadSectionsFromJson()`
- `loadDefaultSections()`
- `loadSectionsFromFile()`
- `importSectionsToModel(data)`

## Arquivos

```
sections/
├── pro_sections.rb              # Módulo principal
├── json_data/
│   ├── sections_data.json       # Dados padrão
│   └── user_sections_data.json  # Dados do usuário (criado automaticamente)
└── README.md                    # Esta documentação
```

## Integração

### main.rb

```ruby
require File.join(ProjetaPlus::PATH, 'projeta_plus', 'modules', 'inteli-skt', 'sections', 'pro_sections.rb')
require File.join(ProjetaPlus::PATH, 'projeta_plus', 'dialog_handlers', 'sections_handlers.rb')
```

### commands.rb

```ruby
sections_handler = ProjetaPlus::DialogHandlers::SectionsHandler.new(@@main_dashboard_dialog)
sections_handler.register_callbacks
```

## Notas Técnicas

- Section planes não podem ser "atualizados" diretamente no SketchUp API
- Para atualizar, o método `update_section` remove o antigo e cria um novo
- Posições são em unidades do SketchUp (inches internamente)
- Direções são vetores normalizados [x, y, z]
- Cada section plane pode ter um nome único
- Section planes podem ser organizadas em layers específicas
