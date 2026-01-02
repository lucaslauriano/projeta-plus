# ProScenes Module

## Overview

The ProScenes module provides comprehensive scene management functionality for SketchUp, allowing users to create, configure, and manage scenes with specific styles, camera settings, and layer visibility.

## Architecture

This module follows the standard ProjetaPlus architecture pattern with:

### Backend (Ruby)

- **Module**: `projeta_plus/modules/inteli-skt/scenes/pro_scenes.rb`
- **Handler**: `projeta_plus/dialog_handlers/scenes_handlers.rb`
- **Data**: `projeta_plus/modules/inteli-skt/scenes/json_data/scenes_data.json`

### Frontend (TypeScript/React)

- **Hook**: `hooks/useScenes.ts`
- **Component**: `app/dashboard/inteli-sket/components/scenes.tsx`
- **Types**: `types/global.d.ts`

## Features

### Scene Management

- **Get Scenes**: Retrieve all scenes from the SketchUp model with their configurations
- **Add Scene**: Create new scenes with custom settings
- **Update Scene**: Modify existing scene configurations
- **Delete Scene**: Remove scenes from the model
- **Apply Config**: Apply or update scene configurations

### Scene Configuration Options

#### Styles

- Load and apply any style available in the SketchUp model
- Dynamic style selection from model's style library

#### Camera Types

- `iso_perspectiva` - Isometric view with perspective
- `iso_ortogonal` - Isometric view orthogonal
- `iso_invertida_perspectiva` - Inverted isometric with perspective
- `iso_invertida_ortogonal` - Inverted isometric orthogonal
- `topo_perspectiva` - Top view with perspective
- `topo_ortogonal` - Top view orthogonal

#### Layer Visibility

- Select which layers should be visible in each scene
- "All", "None", and "Current State" quick selection buttons
- Dynamic layer list from the model

### Data Persistence

#### JSON Storage

- **User Data**: `user_scenes_data.json` - User's custom configurations
- **Default Data**: `scenes_data.json` - Default scene templates

#### Operations

- **Save to JSON**: Save current scene groups and configurations
- **Load from JSON**: Load previously saved configurations
- **Load Default**: Reset to default scene templates
- **Load from File**: Import configurations from external JSON file

## Usage

### Ruby API

```ruby
# Get all scenes
result = ProjetaPlus::Modules::ProScenes.get_scenes

# Add a new scene
result = ProjetaPlus::Modules::ProScenes.add_scene({
  name: 'My Scene',
  style: 'PRO_VISTAS',
  cameraType: 'iso_perspectiva',
  activeLayers: ['Layer0', '-2D-AMBIENTE']
})

# Update existing scene
result = ProjetaPlus::Modules::ProScenes.update_scene('My Scene', {
  style: 'PRO_PLANTAS',
  cameraType: 'topo_ortogonal'
})

# Get available styles
result = ProjetaPlus::Modules::ProScenes.get_available_styles

# Get available layers
result = ProjetaPlus::Modules::ProScenes.get_available_layers

# Get current model state
result = ProjetaPlus::Modules::ProScenes.get_current_state
```

### Frontend Hook

```typescript
import { useScenes } from '@/hooks/useScenes';

function MyComponent() {
  const {
    data,
    availableStyles,
    availableLayers,
    currentState,
    isBusy,
    addScene,
    updateScene,
    deleteScene,
    saveToJson,
    loadFromJson,
    getCurrentState,
  } = useScenes();

  // Use the hook methods...
}
```

## Data Structure

### Scene Object

```typescript
interface Scene {
  id: string;
  name: string;
  style: string;
  cameraType: string;
  activeLayers: string[];
}
```

### Group Object

```typescript
interface SceneGroup {
  id: string;
  name: string;
  scenes: Array<{
    id: string;
    title: string;
    segments: any[];
  }>;
}
```

### Complete Data Structure

```typescript
interface ScenesData {
  groups: SceneGroup[];
  scenes: Scene[];
}
```

## Integration

The module is fully integrated into the ProjetaPlus system:

1. **Handler Registration**: Registered in `commands.rb`
2. **Module Loading**: Loaded in `main.rb`
3. **UI Integration**: Accessible through the Inteli-Sket dashboard
4. **Type Safety**: Full TypeScript support with global type definitions

## Key Differences from Legacy Code

### Removed Features

- HTML dialog generation (moved to React)
- Facade-specific methods (executar_fachadas, configurar_fachada)
- Old layer visibility logic (grupos_ocultar, expandir_grupos_para_camadas)
- Embedded UI::HtmlDialog interfaces

### Simplified Architecture

- Uses only `camadas_ativas` array for layer visibility
- Streamlined camera types (6 options instead of complex logic)
- All UI in React frontend (no Ruby HTML generation)
- Consistent with other ProjetaPlus modules

### Enhanced Features

- Real-time sync with SketchUp model
- Dynamic style and layer detection
- "Current State" capture functionality
- Better error handling and user feedback
- Mock mode for development without SketchUp

## File Locations

```
projeta_plus/
├── modules/
│   └── inteli-skt/
│       ├── scenes/
│       │   ├── pro_scenes.rb              # Main module
│       │   ├── json_data/
│       │   │   ├── scenes_data.json       # Default data
│       │   │   └── user_scenes_data.json  # User data (auto-generated)
│       │   └── README.md                  # This file
│       └── layers/
│           ├── pro_layers.rb              # Layers module
│           └── json_data/
│               ├── tags_data.json         # Default tags
│               └── user_tags_data.json    # User tags
├── dialog_handlers/
│   ├── scenes_handlers.rb             # Scenes dialog callbacks
│   └── layers_handlers.rb             # Layers dialog callbacks
└── frontend/projeta-plus-html/
    ├── hooks/
    │   ├── useScenes.ts               # Scenes React hook
    │   └── useLayers.ts               # Layers React hook
    ├── app/dashboard/inteli-sket/components/
    │   ├── scenes.tsx                 # Scenes UI component
    │   └── layers.tsx                 # Layers UI component
    └── types/
        └── global.d.ts                # TypeScript types
```

## Development Notes

- The module uses SketchUp's native Pages API for scene management
- Camera configurations use Geom::Point3d and Geom::Vector3d for positioning
- All operations are wrapped in transactions for undo/redo support
- The frontend includes mock data for development without SketchUp connection
- Layer visibility is applied before creating/updating scenes for accurate capture

## Future Enhancements

Potential improvements for future versions:

- Scene animation sequences
- Batch scene operations
- Scene templates library
- Export scenes as images
- Scene comparison tools
- Advanced camera path animations
