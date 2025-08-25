# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Architecture Overview

This is a collection of SketchUp plugins developed by Francieli Madeira (FM Extensions) and other contributors. The codebase follows SketchUp's Ruby API plugin architecture with the following structure:

### Core Plugin Structure
- **Main Plugin Files**: Each plugin has a main `.rb` file that registers the extension with SketchUp
- **Implementation Directory**: Each plugin has its own subdirectory containing the actual implementation code
- **Module Organization**: All plugins are organized under the `FM_Extensions` namespace module
- **Resource Assets**: Each plugin includes its own icons and resources in subdirectories

### Key Plugins
1. **FM_Anotacoes** - Annotation tools for room names and section cuts
2. **FM_Iluminacao** - Dynamic lighting fixtures and points
3. **FM_Interiores** - Interior design tools with scene management and layer organization
4. **FM_Mobiliario** - Furniture dimensioning and quantification tools
5. **FM_PontosTecnicos** - Technical points management
6. **FM_RevestimentosRodapes** - Wall coverings and baseboards
7. **mad_floor_design** - Floor covering design tools (third-party plugin)

### Layer Management System
The plugins use an extensive standardized layer naming convention organized by functional groups:
- **2D** layers for technical drawings and annotations
- **ARQUITETURA** layers for architectural elements
- **INTERIORES** layers for interior design elements with specific color coding
- **TETO/FORRO** layers for ceiling elements with distinct colors
- **CIVIL** layers for construction/demolition work
- **TECNICO** layers for technical installations
- **ILUMINACAO** layers for lighting design

### Scene Management
The FM_Interiores plugin provides automated scene creation and configuration with predefined views:
- **Base scenes**: Foundation architectural views with section planes
- **Specialized views**: Layout, mobiliary, construction, technical, lighting scenes
- **Camera positioning**: Automated top-down and isometric camera setups
- **Layer visibility**: Intelligent layer hiding/showing based on scene purpose

## Common Development Tasks

### Plugin Installation and Registration
```ruby
# Main plugin file structure (e.g., FM_PluginName.rb)
require 'sketchup.rb'
require 'extensions.rb'

module FM_Extensions
  module PluginName
    extension = SketchupExtension.new(
      'Display Name',
      File.join(__dir__, 'PluginDirectory', 'implementation_file.rb')
    )
    extension.description = 'Plugin description'
    extension.version = '1.0.0'
    extension.creator = 'Creator Name'
    extension.copyright = '© Year Creator'
    
    Sketchup.register_extension(extension, true)
  end
end
```

### Creating Toolbars and Commands
```ruby
# Creating toolbar with icons
toolbar = UI::Toolbar.new('Toolbar Name')

cmd = UI::Command.new('Command Name') {
  # Command implementation
}
icon_path = File.join(__dir__, 'icones', 'icon.png')
cmd.small_icon = icon_path
cmd.large_icon = icon_path
cmd.tooltip = 'Tooltip text'
cmd.status_bar_text = 'Status bar description'
toolbar.add_item(cmd)
toolbar.show
```

### Working with Layers and Scenes
```ruby
# Creating organized layer structure
model = Sketchup.active_model
manager = model.layers

# Create folder and add layers
folder = manager.folders.find { |f| f.name == "GROUP_NAME" } || manager.add_folder("GROUP_NAME")
layer = manager.layers.find { |l| l.name == "LAYER_NAME" } || manager.add_layer("LAYER_NAME")
folder.add_layer(layer) unless folder.layers.include?(layer)

# Set layer colors
layer.color = Sketchup::Color.new(r, g, b)

# Create and configure scenes
scene = model.pages.add("scene_name")
model.pages.selected_page = scene
# Configure camera, layers, styles
scene.update
```

### 3D Text Creation
```ruby
# Create 3D text with specific formatting
text_group = entities.add_group
height = 0.3.cm * scale
text_group.entities.add_3d_text(text, alignment, font, is_bold, is_italic, height, thickness)

# Apply materials
black_material = model.materials['Black'] || model.materials.add('Black')
text_group.entities.grep(Sketchup::Face).each do |face|
  face.material = black_material
  face.back_material = black_material
end
```

## File Organization

```
/
├── README.md                     # Basic project information
├── FM_PluginName.rb             # Main plugin registration files
├── FM_PluginName/               # Plugin implementation directories
│   ├── implementation_file.rb   # Main plugin logic
│   ├── icones/                  # Plugin-specific icons
│   │   └── icon.png
│   └── additional_files.rb      # Additional plugin modules
└── mad_floor_design/            # Third-party plugin directory
    ├── main.rbe                 # Encrypted main implementation
    ├── icons/                   # Plugin icons
    └── dist/                    # Distribution assets
```

## Key Implementation Patterns

### Preference Management
- Use `Sketchup.read_default()` and `Sketchup.write_default()` for persistent settings
- Store plugin-specific preferences with namespaced keys
- Implement both model-level and global preference storage

### Entity Management
- Always use `model.start_operation()` and `model.commit_operation()` for undoable operations
- Group related entities for better organization
- Use proper material assignment for consistent appearance

### UI Development
- Create HTML dialogs for complex user interfaces using `UI::HtmlDialog`
- Use `UI.inputbox()` for simple parameter collection
- Implement proper callback handling for interactive dialogs

### Component and Group Handling
- Recursively traverse entity hierarchies when needed
- Check entity types before accessing type-specific properties
- Use proper transformation handling for positioning elements

## Testing and Development

Since this is a SketchUp plugin collection, testing requires:
1. SketchUp 2025 or compatible version
2. Loading plugins through SketchUp's Extension Manager
3. Testing within 3D models with appropriate geometry and layers
4. Verification of toolbar creation and command functionality
5. Testing scene creation and layer visibility management

## Plugin Dependencies

- SketchUp Ruby API (version 2025)
- Standard Ruby libraries: `csv`, `json`
- SketchUp-specific modules: `sketchup.rb`, `extensions.rb`
- File system operations for icon and resource loading
