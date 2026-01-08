# Módulo de Relatórios de Iluminação

## 📋 Visão Geral

O módulo `pro_lightning_reports` é responsável pela coleta, processamento e exportação de dados de componentes de iluminação do SketchUp. Ele segue a arquitetura padrão do ProjetaPlus e está integrado com o frontend React.

## 🏗️ Arquitetura

### Backend (Ruby)

#### Arquivo: `pro_lightning_reports.rb`

**Localização:** `projeta_plus/modules/reports/pro_lightning_reports.rb`

**Responsabilidades:**

- Buscar componentes de iluminação recursivamente no modelo
- Extrair atributos dinâmicos (`fm_ilu` e `fm_ilu_mar`)
- Agrupar componentes idênticos e contar quantidades
- Exportar dados para CSV/XLSX
- Gerenciar preferências de colunas

**Métodos Públicos:**

- `get_lightning_types` - Retorna tipos disponíveis (Padrão e Marcenaria)
- `get_lightning_data(type)` - Coleta dados de um tipo específico
- `get_column_preferences` - Carrega preferências salvas
- `save_column_preferences(prefs)` - Salva preferências
- `export_to_csv(params)` - Exporta dados para CSV
- `export_to_xlsx(params)` - Exporta dados para XLSX

**Constantes:**

```ruby
PREFIX_STANDARD = "fm_ilu"      # Iluminação padrão
PREFIX_FURNITURE = "fm_ilu_mar" # Iluminação de marcenaria
MAX_RECURSION_LEVEL = 5         # Profundidade máxima de busca
```

**Atributos Dinâmicos Suportados:**

- `fm_ilu` / `fm_ilu_mar` - Legenda
- `_t1` - Luminária
- `_t2` - Marca da Luminária
- `_t3` - Lâmpada
- `_t4` - Marca da Lâmpada
- `_t5` - Temperatura
- `_t6` - IRC
- `_t7` - Lumens
- `_t8` - Dímer
- `_t9` - Ambiente

### Handler (Ruby)

#### Arquivo: `lightning_reports_handler.rb`

**Localização:** `projeta_plus/dialog_handlers/lightning_reports_handler.rb`

**Callbacks Registrados:**

- `getLightningTypes` → `handleGetLightningTypesResult`
- `getLightningData` → `handleGetLightningDataResult`
- `getLightningColumnPreferences` → `handleGetLightningColumnPreferencesResult`
- `saveLightningColumnPreferences` → `handleSaveLightningColumnPreferencesResult`
- `exportLightningCSV` → `handleExportLightningCSVResult`
- `exportLightningXLSX` → `handleExportLightningXLSXResult`

**Logging:**

- Arquivo de log: `lightning_reports_log.txt`
- Registra todas as chamadas e erros

### Frontend (React/TypeScript)

#### Arquivo: `useLightningReports.ts`

**Localização:** `projeta_plus/frontend/projeta-plus-html/hooks/useLightningReports.ts`

**Hook Personalizado:**

```typescript
const {
  types, // Tipos disponíveis
  lightningData, // Dados carregados por tipo
  columnPrefs, // Preferências de colunas
  isBusy, // Estado de loading
  isAvailable, // SketchUp disponível?
  getLightningTypes,
  getLightningData,
  getColumnPreferences,
  saveColumnPreferences,
  exportCSV,
  exportXLSX,
} = useLightningReports();
```

**Tipos:**

```typescript
interface LightningItem {
  legenda: string;
  luminaria: string;
  marca_luminaria: string;
  lampada: string;
  marca_lampada: string;
  temperatura: string;
  irc: string;
  lumens: string;
  dimer: string;
  ambiente: string;
  quantidade: number;
}
```

#### Arquivo: `lightning.tsx`

**Localização:** `projeta_plus/frontend/projeta-plus-html/app/dashboard/generate-report/components/lightning.tsx`

**Componente Principal:**

- **Tabs** para alternar entre tipos (Padrão/Marcenaria)
- **Seleção de Colunas** com checkboxes
- **Tabela** responsiva com dados
- **Exportação** CSV/XLSX via menu
- **Empty State** quando sem dados
- **Loading State** durante carregamento

## 🔧 Funcionalidades

### 1. Coleta de Dados

- Busca recursiva em todas as entidades (até 5 níveis)
- Suporta `ComponentInstance` e `Group`
- Extrai atributos dinâmicos automaticamente
- Agrupa componentes idênticos

### 2. Processamento

- Conta quantidade de cada tipo
- Agrupa por características idênticas
- Calcula totais automaticamente

### 3. Exportação

- **CSV**: Formato padrão com encoding UTF-8
- **XLSX**: Compatível com Excel (via CSV renomeado)
- Salva no mesmo diretório do modelo
- Nomenclatura automática: `Iluminacao.csv` ou `Iluminacao_Marcenaria.csv`

### 4. Interface

- Design moderno e responsivo
- Feedback visual de estados (loading, error, empty)
- Ações rápidas via menu contextual
- Seleção flexível de colunas

## 📊 Fluxo de Dados

```
1. Frontend → callSketchupMethod('getLightningTypes')
2. Ruby Handler → ProLightningReports.get_lightning_types
3. Ruby Module → Retorna [ { id, name, prefix } ]
4. Handler → send_json_response('handleGetLightningTypesResult')
5. Frontend → Atualiza state 'types'

Similar para: getLightningData, exportCSV, exportXLSX, etc.
```

## 🎨 Padrões e Convenções

### Nomenclatura

- **Ruby**: snake_case (`get_lightning_data`)
- **TypeScript**: camelCase (`getLightningData`)
- **Callbacks**: handle + Nome + Result (`handleGetLightningDataResult`)

### Estrutura de Resposta

```ruby
{
  success: true/false,
  message: "Mensagem de erro (opcional)",
  data: { ... } # Dados específicos
}
```

### Error Handling

- **Ruby**: `begin/rescue` com logging
- **TypeScript**: Toast notifications via `sonner`
- **Handler**: `handle_error(e, context)` do `BaseHandler`

## 🚀 Como Usar

### No Frontend

```typescript
import { useLightningReports } from '@/hooks/useLightningReports';

function MyComponent() {
  const { types, lightningData, getLightningData, exportCSV } =
    useLightningReports();

  // Carregar dados do tipo 'standard'
  useEffect(() => {
    getLightningData('standard');
  }, []);

  // Exportar
  const handleExport = () => {
    exportCSV('standard', lightningData['standard'].items, columns);
  };
}
```

### No Ruby (Testes)

```ruby
# Obter tipos
result = ProjetaPlus::Modules::ProLightningReports.get_lightning_types
puts result[:types]

# Obter dados
result = ProjetaPlus::Modules::ProLightningReports.get_lightning_data('standard')
puts result[:data][:items].size
```

## ⚙️ Configuração

### Preferências

- Salvas em `Sketchup.write_default('projeta_plus_lightning', ...)`
- Key: `lightning_column_prefs`
- Formato: Array de strings com nomes das colunas

### Colunas Padrão

```ruby
DEFAULT_COLUMNS = %w[
  legenda luminaria marca_luminaria lampada marca_lampada
  temperatura irc lumens dimer ambiente quantidade
]
```

## 📝 Logs e Debug

### Arquivos de Log

- `projeta_plus/lightning_reports_log.txt`
- Registra: timestamps, chamadas, erros, stack traces

### Console Logs

- Frontend: `console.log('[LightningReports] ...')`
- Ruby: `puts "[ProLightningReports] ..."`

## 🔗 Integrações

### Dependências Ruby

- `sketchup.rb` - API do SketchUp
- `csv` - Exportação CSV
- `json` - Serialização de dados
- `base_handler.rb` - Classe base para handlers

### Dependências Frontend

- `@/contexts/SketchupContext` - Bridge Ruby ↔ JS
- `@/utils/register-handlers` - Registro de callbacks
- `sonner` - Toast notifications
- `shadcn/ui` - Componentes UI

## ✅ Checklist de Implementação

- [x] Módulo Ruby (`pro_lightning_reports.rb`)
- [x] Handler Ruby (`lightning_reports_handler.rb`)
- [x] Hook React (`useLightningReports.ts`)
- [x] Componente React (`lightning.tsx`)
- [x] Registro em `main.rb`
- [x] Registro em `commands.rb`
- [x] Documentação (este arquivo)

## 🐛 Troubleshooting

### Dados não aparecem

1. Verificar se componentes têm atributos dinâmicos
2. Conferir prefixo (`fm_ilu` ou `fm_ilu_mar`)
3. Checar logs: `lightning_reports_log.txt`

### Exportação falha

1. Salvar modelo antes de exportar
2. Verificar permissões de escrita no diretório
3. Conferir encoding UTF-8

### Frontend não responde

1. Verificar console do navegador
2. Confirmar registro de handlers
3. Testar `isAvailable` do SketchupContext

## 📚 Referências

- **Módulo Original**: `FM_Iluminacao` (código legado HTML/JS)
- **Padrão de Arquitetura**: `pro_furniture_reports.rb`
- **Convenções**: `projeta_plus/docs/new_module.md`

---

**Autor**: Implementado seguindo padrões senior-level  
**Data**: Janeiro 2026  
**Versão**: 1.0.0
