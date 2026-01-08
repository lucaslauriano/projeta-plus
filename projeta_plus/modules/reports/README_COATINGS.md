# Módulo de Relatórios de Revestimentos (Coatings)

## 📋 Visão Geral

O módulo `pro_coatings_reports` gerencia a coleta, edição e exportação de dados de materiais/revestimentos aplicados no modelo do SketchUp. Inclui persistência de dados, cálculo de áreas, acréscimos e exportação em múltiplos formatos.

## 🏗️ Arquitetura

### Backend (Ruby)

#### Arquivo: `pro_coatings_reports.rb`
**Localização:** `projeta_plus/modules/reports/pro_coatings_reports.rb`

**Responsabilidades:**
- Persistência de dados em JSON (salva junto ao arquivo .skp)
- Adicionar material selecionado (conta-gotas do SketchUp)
- Calcular área total de cada material
- Exportar para CSV/XLSX com colunas selecionáveis

**Métodos Públicos:**
```ruby
save_data(params)              # Salva dados em JSON
load_data                      # Carrega dados do JSON
add_selected_material          # Adiciona material atual do SketchUp
export_to_csv(params)          # Exporta para CSV
export_to_xlsx(params)         # Exporta para XLSX
```

**Cálculo de Área:**
```ruby
# Conversão de área do SketchUp para m²
CONVERSION_FACTOR = 0.00064516
area_m2 = (selected_area * CONVERSION_FACTOR).round(2)
```

**Persistência:**
```ruby
# Arquivo salvo em: {modelo}_materiais.json
# Localização: mesma pasta do arquivo .skp
```

### Handler (Ruby)

#### Arquivo: `coatings_reports_handler.rb`
**Localização:** `projeta_plus/dialog_handlers/coatings_reports_handler.rb`

**Callbacks Registrados:**
- `loadCoatingsData` → `handleLoadCoatingsDataResult`
- `saveCoatingsData` → `handleSaveCoatingsDataResult`
- `addSelectedMaterial` → `handleAddSelectedMaterialResult`
- `exportCoatingsCSV` → `handleExportCoatingsCSVResult`
- `exportCoatingsXLSX` → `handleExportCoatingsXLSXResult`

**Logging:**
- Arquivo: `coatings_reports_log.txt`
- Registra todas as operações e erros

### Frontend (React/TypeScript)

#### Arquivo: `useCoatingsReports.ts`
**Localização:** `projeta_plus/frontend/projeta-plus-html/hooks/useCoatingsReports.ts`

**Hook Personalizado:**
```typescript
const {
  coatingsData,          // Array de materiais
  summary,               // Estatísticas (total, itens, ambientes)
  isBusy,               // Estado de loading
  isAvailable,          // SketchUp disponível?
  loadData,             // Carregar dados salvos
  saveData,             // Salvar dados
  addSelectedMaterial,  // Adicionar material do SketchUp
  updateItem,           // Atualizar item (edição inline)
  removeItem,           // Remover item
  exportCSV,            // Exportar CSV
  exportXLSX,           // Exportar XLSX
} = useCoatingsReports();
```

**Interface de Dados:**
```typescript
interface CoatingItem {
  ambiente: string;      // Ambiente (editável)
  material: string;      // Nome do material
  marca: string;         // Marca (editável)
  acabamento: string;    // Acabamento (editável)
  area: number;          // Área base (m²)
  acrescimo: number;     // Acréscimo percentual
  total: number;         // Área total com acréscimo
}
```

**Cálculo de Total:**
```typescript
total = area * (1 + acrescimo / 100)
// Exemplo: area=10m², acrescimo=15% → total=11.5m²
```

#### Arquivo: `coatings.tsx`
**Localização:** `projeta_plus/frontend/projeta-plus-html/app/dashboard/generate-report/components/coatings.tsx`

**Funcionalidades:**
- ✅ **Adicionar Material** - Via conta-gotas do SketchUp
- ✅ **Tabela Editável** - Todos os campos exceto área e total
- ✅ **Filtros** - Por material e por ambiente
- ✅ **Agrupamento** - Por ambiente
- ✅ **Seleção de Colunas** - Escolher quais colunas exibir/exportar
- ✅ **Cálculo Automático** - Total recalcula ao alterar acréscimo
- ✅ **Persistência Automática** - Salva ao editar/adicionar/remover
- ✅ **Exportação** - CSV/XLSX com colunas selecionadas
- ✅ **Remoção** - Delete individual com confirmação

## 🔧 Funcionalidades

### 1. Adicionar Material
```
Fluxo:
1. Usuário seleciona material no SketchUp (conta-gotas)
2. Clica em "Adicionar Material"
3. Ruby calcula área total aplicada
4. Frontend adiciona à tabela
5. Auto-salva em JSON
```

**Validações:**
- Material deve estar selecionado
- Material deve estar aplicado em pelo menos uma face
- Área > 0

### 2. Edição Inline
- **Editável:** ambiente, material, marca, acabamento, acréscimo
- **Somente leitura:** área (vem do SketchUp), total (calculado)
- **Auto-save:** Salva automaticamente ao alterar qualquer campo

### 3. Cálculo de Acréscimo
```typescript
// Acréscimo de 15%
area: 10.00 m²
acrescimo: 15%
total: 11.50 m² // = 10 * (1 + 15/100)
```

### 4. Filtros e Agrupamento
- **Busca:** Filtra por nome do material
- **Filtro de Ambiente:** Dropdown com ambientes únicos
- **Agrupamento:** Agrupa linhas por ambiente (visual)

### 5. Seleção de Colunas
- Checkboxes para mostrar/ocultar colunas
- Afeta tanto visualização quanto exportação
- Persiste na sessão

### 6. Persistência
**Arquivo:** `{nome_do_modelo}_materiais.json`
**Localização:** Mesma pasta do arquivo .skp
**Formato:**
```json
[
  {
    "ambiente": "Sala",
    "material": "Porcelanato Branco",
    "marca": "Portobello",
    "acabamento": "Polido",
    "area": 15.75,
    "acrescimo": 10,
    "total": 17.33
  }
]
```

### 7. Exportação
**CSV/XLSX:**
- Inclui apenas colunas selecionadas
- Linha de total automática
- Salva na pasta do modelo
- Nome fixo: `Revestimentos.csv` / `Revestimentos.xlsx`

**Estrutura CSV:**
```csv
Ambiente,Material,Marca,Acabamento,Área (m²),Acréscimo (%),Total (m²)
Sala,Porcelanato Branco,Portobello,Polido,15.75,10,17.33
Cozinha,Cerâmica Cinza,Eliane,Acetinado,8.50,15,9.78
TOTAL,,,,24.25,,27.11
```

## 📊 Fluxo de Dados

### Adicionar Material
```
1. Frontend → callSketchupMethod('addSelectedMaterial')
2. Handler → ProCoatingsReports.add_selected_material
3. Module → model.materials.current + iterate_entities
4. Module → Calcula área total do material
5. Handler → send_json_response('handleAddSelectedMaterialResult')
6. Frontend → Adiciona à lista + Auto-save
```

### Edição
```
1. Usuário → Altera campo na tabela
2. Frontend → updateItem(index, updates)
3. Frontend → Recalcula total se acréscimo mudou
4. Frontend → saveData(newData)
5. Handler → ProCoatingsReports.save_data
6. Ruby → Salva JSON no disco
```

### Exportação
```
1. Frontend → Seleciona colunas + clica exportar
2. Frontend → exportCSV(data, columns)
3. Handler → ProCoatingsReports.export_to_csv
4. Ruby → Gera CSV com colunas filtradas
5. Ruby → Salva na pasta do modelo
6. Frontend → Toast de sucesso
```

## 🎨 Padrões e Convenções

### Colunas Disponíveis
```typescript
const AVAILABLE_COLUMNS = [
  { id: 'ambiente', label: 'Ambiente' },
  { id: 'material', label: 'Material' },
  { id: 'marca', label: 'Marca' },
  { id: 'acabamento', label: 'Acabamento' },
  { id: 'area', label: 'Área (m²)' },
  { id: 'acrescimo', label: 'Acréscimo (%)' },
  { id: 'total', label: 'Total (m²)' },
];
```

### Cálculo de Área no Ruby
```ruby
def self.iterate_entities(entities, areas = Hash.new(0))
  entities.each do |entity|
    if entity.is_a?(Sketchup::Face)
      # Material da frente
      mat = entity.material
      areas[mat] += entity.area if mat
      
      # Material de trás
      back_mat = entity.back_material
      areas[back_mat] += entity.area if back_mat
    elsif entity.is_a?(Sketchup::Group)
      iterate_entities(entity.entities, areas)
    elsif entity.is_a?(Sketchup::ComponentInstance)
      iterate_entities(entity.definition.entities, areas)
    end
  end
  areas
end
```

## 🚀 Como Usar

### No Frontend
```typescript
import { useCoatingsReports } from '@/hooks/useCoatingsReports';

function MyComponent() {
  const {
    coatingsData,
    addSelectedMaterial,
    updateItem,
    exportCSV
  } = useCoatingsReports();

  // Adicionar material selecionado
  const handleAdd = () => {
    addSelectedMaterial();
  };

  // Atualizar ambiente do primeiro item
  const handleUpdate = () => {
    updateItem(0, { ambiente: 'Sala de Estar' });
  };

  // Exportar
  const handleExport = () => {
    const columns = ['ambiente', 'material', 'total'];
    exportCSV(coatingsData, columns);
  };
}
```

### No Ruby (Testes)
```ruby
# Adicionar material selecionado
result = ProjetaPlus::Modules::ProCoatingsReports.add_selected_material
puts result[:material][:name], result[:material][:area]

# Salvar dados
data = [{ ambiente: 'Sala', material: 'Porcelanato', area: 10.0, total: 11.0 }]
ProjetaPlus::Modules::ProCoatingsReports.save_data({ data: data })

# Carregar dados
result = ProjetaPlus::Modules::ProCoatingsReports.load_data
puts result[:data].size

# Exportar
ProjetaPlus::Modules::ProCoatingsReports.export_to_csv({ 
  data: data, 
  columns: ['ambiente', 'material', 'total'] 
})
```

## ⚙️ Configuração

### Constantes
```ruby
CONVERSION_FACTOR = 0.00064516  # Área SketchUp → m²
```

### Colunas Padrão
```ruby
DEFAULT_COLUMNS = %w[ambiente material marca acabamento area acrescimo total]
```

## 📝 Logs e Debug

### Arquivos de Log
- `projeta_plus/coatings_reports_log.txt`
- Registra: load, save, add, export, erros

### Console Logs
- Frontend: `console.log('[CoatingsReports] ...')`
- Ruby: `puts "[ProCoatingsReports] ..."`

## 🔗 Integrações

### Dependências Ruby
- `sketchup.rb` - API do SketchUp
- `csv` - Exportação CSV
- `json` - Persistência
- `base_handler.rb` - Classe base

### Dependências Frontend
- `@/contexts/SketchupContext` - Bridge Ruby ↔ JS
- `@/utils/register-handlers` - Callbacks
- `sonner` - Toast notifications
- `shadcn/ui` - Componentes UI
- `EmptyState`, `ViewConfigMenu` - Componentes compartilhados

## ✅ Checklist de Implementação

- [x] Módulo Ruby (`pro_coatings_reports.rb`)
- [x] Handler Ruby (`coatings_reports_handler.rb`)
- [x] Hook React (`useCoatingsReports.ts`)
- [x] Componente React (`coatings.tsx`)
- [x] Registro em `main.rb`
- [x] Registro em `commands.rb`
- [x] Documentação (este arquivo)

## 🐛 Troubleshooting

### Material não é adicionado
1. Verificar se material está selecionado (conta-gotas)
2. Confirmar que material está aplicado em faces
3. Conferir logs: `coatings_reports_log.txt`

### Dados não persistem
1. Verificar se modelo está salvo
2. Conferir permissões de escrita na pasta
3. Verificar se JSON é válido

### Cálculo errado
1. Validar fórmula: `total = area * (1 + acrescimo/100)`
2. Conferir tipos (número vs. string)
3. Verificar conversão de área (CONVERSION_FACTOR)

### Exportação falha
1. Salvar modelo antes de exportar
2. Verificar permissões de escrita
3. Conferir encoding UTF-8

## 📚 Referências

- **Módulo Original**: `FM_ProjectMaterials` (código legado)
- **Padrão de Arquitetura**: Similar a `pro_baseboard_reports.rb`
- **Convenções**: `projeta_plus/docs/new_module.md`

## 🎯 Diferenciais

### vs. Módulo Legado:
- ✅ **Persistência em JSON** vs. inline em HTML
- ✅ **React hooks + TypeScript** vs. JavaScript puro
- ✅ **Tabela moderna shadcn/ui** vs. DOM manipulation
- ✅ **Auto-save** ao editar
- ✅ **Filtros e agrupamento** nativos
- ✅ **Seleção de colunas** para visualização e exportação
- ✅ **Cálculo reativo** de totais
- ✅ **Sem diálogos de confirmação** desnecessários
- ✅ **Feedback visual** (toasts, loading states)

### Melhorias de UX:
1. **Auto-carregamento** de dados salvos
2. **Edição inline** sem modals
3. **Auto-save** transparente
4. **Filtros em tempo real**
5. **Agrupamento visual** por ambiente
6. **Badges informativos** no header
7. **Empty state** com instruções claras
8. **Confirmação apenas para delete**

---

**Autor**: Implementado seguindo padrões senior-level  
**Data**: Janeiro 2026  
**Versão**: 1.0.0
