# Módulo de Relatórios de Rodapés

## 📋 Visão Geral

O módulo `pro_baseboard_reports` gerencia a coleta, processamento e exportação de dados de componentes de rodapés do SketchUp. Segue a arquitetura padrão do ProjetaPlus com integração completa entre Ruby e React.

## 🏗️ Arquitetura

### Backend (Ruby)

#### Arquivo: `pro_baseboard_reports.rb`
**Localização:** `projeta_plus/modules/reports/pro_baseboard_reports.rb`

**Responsabilidades:**
- Buscar componentes de rodapés recursivamente (até 5 níveis)
- Calcular comprimentos dinâmicos usando LenX
- Agrupar e somar por modelo
- Calcular quantidade de barras necessárias
- Exportar para CSV/XLSX

**Métodos Públicos:**
```ruby
get_baseboard_data       # Coleta e agrupa dados de rodapés
export_to_csv(params)    # Exporta para CSV
export_to_xlsx(params)   # Exporta para XLSX
```

**Atributos Dinâmicos Necessários:**
- `comprimentorodape` - Identifica componente como rodapé
- `modelorodape` - Modelo/tipo do rodapé
- `_lenx_formula` - Comprimento dinâmico (opcional, calculado automaticamente)

**Cálculo de Comprimento:**
```ruby
# Comprimento em metros
lenx_em_metros = (entity.transformation.xscale * definition.bounds.width) * 0.0254
lenx_dinamico = entity.get_attribute("dynamic_attributes", "_lenx_formula")&.to_f || lenx_em_metros
```

**Cálculo de Barras:**
```ruby
total_barras = (soma_comprimentos / tamanho_barra).ceil
# Padrão: barra de 2.4m
```

### Handler (Ruby)

#### Arquivo: `baseboard_reports_handler.rb`
**Localização:** `projeta_plus/dialog_handlers/baseboard_reports_handler.rb`

**Callbacks Registrados:**
- `getBaseboardData` → `handleGetBaseboardDataResult`
- `exportBaseboardCSV` → `handleExportBaseboardCSVResult`
- `exportBaseboardXLSX` → `handleExportBaseboardXLSXResult`

**Logging:**
- Arquivo: `baseboard_reports_log.txt`
- Registra todas as operações e erros

### Frontend (React/TypeScript)

#### Arquivo: `useBaseboardReports.ts`
**Localização:** `projeta_plus/frontend/projeta-plus-html/hooks/useBaseboardReports.ts`

**Hook Personalizado:**
```typescript
const {
  baseboardData,      // Dados carregados
  isBusy,            // Estado de loading
  isAvailable,       // SketchUp disponível?
  getBaseboardData,  // Recarregar dados
  updateItem,        // Atualizar item (ex: mudar tamanho da barra)
  exportCSV,         // Exportar CSV
  exportXLSX,        // Exportar XLSX
} = useBaseboardReports();
```

**Interface de Dados:**
```typescript
interface BaseboardItem {
  modelo: string;   // Modelo do rodapé
  soma: number;     // Comprimento total em metros
  barra: number;    // Tamanho da barra em metros
  total: number;    // Quantidade de barras necessárias
}

interface BaseboardData {
  items: BaseboardItem[];
  total: number;    // Total de barras
  summary: {
    totalLength: number;     // Comprimento total (m)
    totalUnits: number;      // Total de barras
    uniqueModels: number;    // Quantidade de modelos únicos
  };
}
```

#### Arquivo: `baseboards.tsx`
**Localização:** `projeta_plus/frontend/projeta-plus-html/app/dashboard/generate-report/components/baseboards.tsx`

**Funcionalidades:**
- **Tabela editável** - Input para alterar tamanho da barra
- **Cálculo automático** - Recalcula total ao mudar barra
- **Exportação** - CSV/XLSX via menu
- **Empty State** - Mensagem quando não há dados
- **Loading State** - Feedback visual durante carregamento
- **Badges** - Indicadores de resumo (modelos, metragem, barras)

## 🔧 Funcionalidades

### 1. Coleta de Dados
- Busca recursiva em todas as entidades (até 5 níveis)
- Suporta `ComponentInstance` e `Group`
- Filtra apenas componentes com `comprimentorodape`
- Calcula comprimento usando transformação e bounds

### 2. Processamento
- Agrupa por `modelorodape`
- Soma comprimentos de cada modelo
- Calcula quantidade de barras (comprimento / tamanho_barra)
- Arredonda para cima (ceil) quantidade de barras

### 3. Interface Editável
- **Tamanho da barra configurável** por modelo
- Recálculo automático ao alterar valor
- Input numérico com validação

### 4. Exportação
- **CSV**: Formato padrão UTF-8
- **XLSX**: Compatível com Excel (CSV renomeado)
- Salva no mesmo diretório do modelo
- Inclui coluna de legenda vazia (para preenchimento manual)
- Linha de total automática

## 📊 Fluxo de Dados

```
1. Frontend → callSketchupMethod('getBaseboardData')
2. Handler → ProBaseboardReports.get_baseboard_data
3. Module → Busca recursiva + Agrupamento + Cálculos
4. Handler → send_json_response('handleGetBaseboardDataResult')
5. Frontend → Atualiza state + Renderiza tabela
6. Usuário → Altera tamanho da barra (opcional)
7. Frontend → Recalcula totais localmente
8. Usuário → Exporta → callSketchupMethod('exportBaseboardCSV')
9. Module → Gera CSV com dados atualizados
```

## 🎨 Padrões e Convenções

### Estrutura CSV
```csv
LEGENDA,MODELO,SOMA (m),BARRA (m),TOTAL (un)
,Rodapé Branco,15.75,2.4,7
,Rodapé Madeira,8.30,2.4,4
TOTAL,,24.05,,11
```

### Cálculo de Exemplo
```
Modelo: "Rodapé Branco"
Soma: 15.75m
Barra: 2.4m
Total: ceil(15.75 / 2.4) = ceil(6.5625) = 7 barras
```

## 🚀 Como Usar

### No Frontend
```typescript
import { useBaseboardReports } from '@/hooks/useBaseboardReports';

function MyComponent() {
  const {
    baseboardData,
    updateItem,
    exportCSV
  } = useBaseboardReports();

  // Alterar tamanho da barra do primeiro item
  const handleBarChange = (newBarSize: number) => {
    updateItem(0, { barra: newBarSize });
  };

  // Exportar
  const handleExport = () => {
    if (baseboardData) {
      exportCSV(baseboardData.items);
    }
  };
}
```

### No Ruby (Testes)
```ruby
# Obter dados
result = ProjetaPlus::Modules::ProBaseboardReports.get_baseboard_data
puts result[:data][:items].size

# Exportar
params = { data: result[:data][:items] }
ProjetaPlus::Modules::ProBaseboardReports.export_to_csv(params)
```

## ⚙️ Configuração

### Constantes
```ruby
MAX_RECURSION_LEVEL = 5     # Profundidade máxima de busca
DEFAULT_BAR_LENGTH = 2.4    # Tamanho padrão da barra (metros)
```

### Atributos Requeridos no SketchUp
Para que um componente seja detectado como rodapé:
1. Deve ter o atributo `comprimentorodape` (qualquer valor)
2. Deve ter o atributo `modelorodape` (nome do modelo)

## 📝 Logs e Debug

### Arquivos de Log
- `projeta_plus/baseboard_reports_log.txt`
- Registra: chamadas, erros, stack traces, contagens

### Console Logs
- Frontend: `console.log('[BaseboardReports] ...')`
- Ruby: `puts "[ProBaseboardReports] ..."`

## 🔗 Integrações

### Dependências Ruby
- `sketchup.rb` - API do SketchUp
- `csv` - Exportação CSV
- `json` - Serialização
- `base_handler.rb` - Classe base

### Dependências Frontend
- `@/contexts/SketchupContext` - Bridge Ruby ↔ JS
- `@/utils/register-handlers` - Callbacks
- `sonner` - Toast notifications
- `shadcn/ui` - Componentes UI
- `EmptyState` - Componente de estado vazio

## ✅ Checklist de Implementação

- [x] Módulo Ruby (`pro_baseboard_reports.rb`)
- [x] Handler Ruby (`baseboard_reports_handler.rb`)
- [x] Hook React (`useBaseboardReports.ts`)
- [x] Componente React (`baseboards.tsx`)
- [x] Registro em `main.rb`
- [x] Registro em `commands.rb`
- [x] Documentação (este arquivo)

## 🐛 Troubleshooting

### Dados não aparecem
1. Verificar se componentes têm `comprimentorodape` e `modelorodape`
2. Conferir logs: `baseboard_reports_log.txt`
3. Testar manualmente: `FM_Rodapes::ReportManager.visualizar_relatorio`

### Cálculo errado
1. Verificar transformação do componente (escala X)
2. Conferir `_lenx_formula` se existir
3. Validar comprimento > 0

### Exportação falha
1. Salvar modelo antes de exportar
2. Verificar permissões de escrita
3. Conferir encoding UTF-8

## 📚 Referências

- **Módulo Original**: `FM_Rodapes` (código legado)
- **Padrão de Arquitetura**: Similar a `pro_lightning_reports.rb`
- **Convenções**: `projeta_plus/docs/new_module.md`

## 🎯 Diferenciais

### vs. Módulo Legado:
- ✅ **TypeScript completo** vs. JavaScript puro
- ✅ **React hooks** vs. DOM manipulation
- ✅ **Input editável** em tempo real vs. inputs na tabela HTML
- ✅ **Empty state** profissional
- ✅ **Cálculo reativo** vs. recálculo manual
- ✅ **Sem pasta customizada** (salva sempre com modelo)
- ✅ **Sem opção MAIÚSCULAS** (mantém original)

### Melhorias de UX:
1. **Auto-carregamento** ao abrir tela
2. **Edição inline** de tamanho de barra
3. **Recálculo instantâneo** ao alterar valores
4. **Feedback visual** em todos os estados
5. **Badges informativos** no header

---

**Autor**: Implementado seguindo padrões senior-level  
**Data**: Janeiro 2026  
**Versão**: 1.0.0
