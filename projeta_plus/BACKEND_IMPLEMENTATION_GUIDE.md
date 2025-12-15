# Guia de Implementação Backend - Base Plans

## Métodos Ruby que precisam ser implementados

### 1. `getBasePlans`
Lê as configurações do arquivo JSON `user_base_plans.json`.

**Handler Frontend:** `handleGetBasePlansResult`

**Resposta esperada:**
```ruby
{
  success: true,
  plans: [
    {
      id: 'base',
      name: 'Base',
      style: 'FM_VISTAS',
      activeLayers: ['Layer0', 'Walls', ...]
    },
    {
      id: 'ceiling',
      name: 'Forro',
      style: 'FM_VISTAS',
      activeLayers: ['Layer0', 'Ceiling', ...]
    }
  ]
}
```

### 2. `saveBasePlans`
Salva as configurações no arquivo JSON `user_base_plans.json`.

**Parâmetros recebidos:**
```ruby
{
  plans: [
    {
      id: 'base',
      name: 'Base',
      style: 'FM_VISTAS',
      activeLayers: ['Layer0', 'Walls', ...]
    },
    {
      id: 'ceiling',
      name: 'Forro',
      style: 'FM_VISTAS',
      activeLayers: ['Layer0', 'Ceiling', ...]
    }
  ]
}
```

**Handler Frontend:** `handleSaveBasePlansResult`

**Resposta esperada:**
```ruby
{
  success: true,
  message: 'Configurações salvas com sucesso!'
}
```

### 3. `getAvailableStylesForBasePlans`
Lista todos os arquivos `.style` da pasta `modules/inteli-skt/styles`.

**Handler Frontend:** `handleGetAvailableStylesForBasePlansResult`

**Resposta esperada:**
```ruby
{
  success: true,
  styles: [
    'FM_VISTAS',
    'FM_VISTAS_EXTERNAS',
    'FM_VISTAS_PB',
    'FM_PLANTAS_PB',
    'FM_PLANTAS',
    'FM_PLANTAS_CORES',
    'FM_PLANOS',
    'FM_MOBILIARIO_OPACO',
    'FM_MOBILIARIO_ARTISTICO',
    'FM_MOBILIARIO_LINHAS',
    'FM_IMAGENS_VISTAS_AO',
    'FM_IMAGENS_VISTAS',
    'FM_IMAGENS_CORTES_AO',
    'FM_IMAGENS_CORTES',
    'FM_DRYWALL',
    'FM_DEMOLIR',
    'FM_CIVIL',
    'FM_CONSTRUIR'
  ]
}
```

**Exemplo de implementação:**
```ruby
def get_available_styles_for_base_plans
  styles_folder = File.join(__dir__, '..', 'modules', 'inteli-skt', 'styles')
  
  if Dir.exist?(styles_folder)
    style_files = Dir.glob(File.join(styles_folder, '*.style'))
    styles = style_files.map { |f| File.basename(f, '.style') }
    
    execute_script("window.handleGetAvailableStylesForBasePlansResult({
      success: true,
      styles: #{styles.to_json}
    })")
  else
    execute_script("window.handleGetAvailableStylesForBasePlansResult({
      success: false,
      message: 'Pasta de estilos não encontrada'
    })")
  end
end
```

### 4. `getAvailableLayersForBasePlans`
Lista todas as camadas (tags/layers) existentes no modelo atual do SketchUp.

**Handler Frontend:** `handleGetAvailableLayersForBasePlansResult`

**Resposta esperada:**
```ruby
{
  success: true,
  layers: ['Layer0', 'Walls', 'Roof', 'Floor', 'Ceiling', 'Furniture', ...]
}
```

**Exemplo de implementação:**
```ruby
def get_available_layers_for_base_plans
  model = Sketchup.active_model
  
  if model
    layers = model.layers.map(&:name)
    
    execute_script("window.handleGetAvailableLayersForBasePlansResult({
      success: true,
      layers: #{layers.to_json}
    })")
  else
    execute_script("window.handleGetAvailableLayersForBasePlansResult({
      success: false,
      message: 'Nenhum modelo ativo'
    })")
  end
end
```

## Localização dos arquivos JSON

- **Padrão:** `modules/inteli-skt/plans/json_data/base_plans.json`
- **Usuário:** `modules/inteli-skt/plans/json_data/user_base_plans.json`

## Fluxo de execução

1. Ao abrir o diálogo de níveis, o hook `useBasePlans` automaticamente chama:
   - `getBasePlans` - carrega configurações salvas
   - `getAvailableStylesForBasePlans` - lista estilos disponíveis
   - `getAvailableLayersForBasePlans` - lista camadas do modelo

2. Quando o usuário clica em "Salvar Configurações":
   - Frontend chama `saveBasePlans` com os dados atualizados
   - Backend salva no JSON e retorna sucesso
   - Frontend recebe confirmação e recarrega os dados

## Logs de Debug

O frontend agora possui logs de debug para facilitar o troubleshooting:
- `[useBasePlans] Salvando plantas:` - mostra os dados sendo enviados
- `[useBasePlans] Resposta do save:` - mostra a resposta do backend
- `[LevelsManagerDialog] Salvando configurações:` - mostra quando o botão é clicado

Verifique o console do navegador para ver se os métodos estão sendo chamados corretamente.

