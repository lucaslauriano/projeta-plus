# Furniture Module

## Overview

The Furniture module provides comprehensive furniture management functionality for the Projeta Plus plugin. It has been refactored to follow modern patterns with separation of concerns, English naming conventions, and proper integration with the localization system.

## Architecture

### Module Structure

```
modules/
├── furniture/
│   ├── pro_furniture_attributes.rb    # Core attribute management
│   └── README.md                       # This file
├── report/
│   └── pro_furniture_reports.rb       # Report generation and export
└── settings/
    └── pro_settings.rb                 # Global settings (includes furniture configs)

dialog_handlers/
└── furniture_handler.rb                # Frontend-backend communication
```

## Core Components

### 1. ProFurnitureAttributes (`pro_furniture_attributes.rb`)

**Purpose**: Manages furniture component attributes, dimensions, and operations.

**Key Features**:

- Attribute management (safe get/set)
- Dimension calculations (width, depth, height)
- Component resizing (proportional and independent)
- Name generation and clipboard operations
- Component collection and caching
- Isolation and visibility operations

**Important Constants**:

- `DICTIONARY_NAME = "projeta_plus_furniture"` - Attribute dictionary name for furniture attributes
- `CM_TO_INCHES = 2.54` - Conversion factor
- `TYPE_COLORS` - Color mapping for each furniture type

**Main Methods**:

- `initialize_default_attributes(component)` - Sets up default attributes
- `get_attribute_safe(component, key, default)` - Safe attribute retrieval
- `set_attribute_safe(component, key, value)` - Safe attribute storage
- `calculate_dimension_string(entity)` - Calculate formatted dimensions
- `resize_proportional(entity, scale_factor)` - Proportional resizing
- `resize_independent(entity, width, depth, height)` - Independent axis resizing
- `isolate_item(target)` - Isolate component in viewport
- `collect_all_furniture_instances(entities, arr, level)` - Recursive collection

### 2. ProFurnitureReports (`pro_furniture_reports.rb`)

**Purpose**: Handles data collection, report generation, and export functionality.

**Key Features**:

- Data aggregation by category
- HTML table generation for dialogs
- CSV export
- XLSX export with formatting
- Category preferences management

**Main Methods**:

- `collect_data_for_category(model, category)` - Collect all items of a type
- `generate_category_table_html(model, category, ...)` - Generate HTML table
- `export_category_to_csv(model, category)` - Export single category to CSV
- `export_to_xlsx(model, categories, path)` - Export multiple categories to XLSX
- `load_category_preferences(types)` - Load user preferences
- `save_category_preferences(prefs)` - Save user preferences

### 3. FurnitureHandler (`furniture_handler.rb`)

**Purpose**: Bridge between frontend (Next.js) and backend (SketchUp Ruby).

**Registered Callbacks**:

- `get_furniture_attributes` - Get attributes of selected component
- `save_furniture_attributes` - Save edited attributes
- `resize_proportional` - Resize maintaining proportions
- `resize_independent` - Resize each axis independently
- `get_dimensions` - Get current dimensions
- `calculate_dimension_string` - Calculate formatted dimension string
- `isolate_furniture_item` - Isolate component
- `get_furniture_types` - Get available furniture types
- `export_furniture_category_csv` - Export category to CSV
- `export_furniture_xlsx` - Export to Excel
- `get_category_report_data` - Get report data for a category

## Attributes

Each furniture component stores the following attributes:

| Attribute        | Key                | Type   | Description                            |
| ---------------- | ------------------ | ------ | -------------------------------------- |
| Name             | `name`             | String | Furniture name                         |
| Color            | `color`            | String | Color/finish                           |
| Brand            | `brand`            | String | Manufacturer/brand                     |
| Type             | `type`             | String | Category (Furniture, Appliances, etc.) |
| Dimension Format | `dimension_format` | String | Format string (e.g., "L x D x H")      |
| Dimension        | `dimension`        | String | Formatted dimension string             |
| Environment      | `environment`      | String | Room/space name                        |
| Value            | `value`            | String | Price/value                            |
| Link             | `link`             | String | Product URL                            |
| Observations     | `observations`     | String | Notes                                  |
| Code             | `code`             | String | Generated code (e.g., FUR001)          |

**Dictionary**: All attributes are stored in the `projeta_plus_furniture` dictionary

## Furniture Types

The module supports the following furniture types:

1. **Furniture** (`Furniture`) - General furniture items
2. **Appliances** (`Appliances`) - Kitchen and home appliances
3. **Fixtures & Fittings** (`Fixtures & Fittings`) - Plumbing fixtures, hardware
4. **Accessories** (`Accessories`) - Decorative accessories
5. **Decoration** (`Decoration`) - Decorative items

Each type has an associated color for visual identification in reports and annotations.

## Frontend Integration

### Expected Frontend Fields (from `page.tsx`)

**Basic Information**:

- `name` - Component name
- `color` - Color/finish
- `brand` - Brand/manufacturer
- `type` - Furniture type

**Dimensions**:

- `width` - Width in cm
- `depth` - Depth in cm
- `height` - Height in cm
- `keepProportionWidth` - Lock width for proportional resize
- `keepProportionDepth` - Lock depth for proportional resize
- `keepProportionHeight` - Lock height for proportional resize

**Additional Information**:

- `dimensionFormat` - Dimension display format
- `finalDimension` - Calculated dimension string
- `environment` - Room/environment name
- `value` - Price/value
- `link` - Product link
- `observations` - Additional notes

### Communication Flow

```
Frontend (Next.js/React)
    ↓ (sketchup.save_furniture_attributes(data))
FurnitureHandler
    ↓ (calls ProFurnitureAttributes)
ProFurnitureAttributes
    ↓ (modifies component attributes)
SketchUp Model
```

## Settings

Furniture-related settings are stored in `ProSettings`:

- `furniture_dimension_format` - Default dimension format
- Available formats: "L x D x H", "L x H x D", "H x L x D", "H x D x L", "D x L x H", "D x H x L"

## Localization

All user-facing strings use the localization system:

**Translation Categories**:

- `furniture_types.*` - Furniture type names
- `table_headers.*` - Table column headers
- `buttons.*` - Button labels
- `reports.*` - Report titles
- `messages.*` - User messages

**Supported Languages**:

- English (`en`)
- Portuguese - Brazil (`pt-BR`)
- Spanish (`es`)

## Export Formats

### CSV Export

- Simple CSV format
- One category per file
- Includes all attributes and quantities

### XLSX Export

- Multi-category support
- Formatted with colors and fonts
- Grouped by furniture type
- Century Gothic font
- Type-specific color coding for codes
- Configurable column visibility

## Caching

The module implements a 2-second cache for performance:

- `@instances_cache` - Cached instances grouped by type
- `@cache_timestamp` - Cache creation time
- Automatically invalidated on save operations
- Manual invalidation via `invalidate_cache`

## Migration from Old Code

### Key Changes

| Old                                   | New                                                | Reason                       |
| ------------------------------------- | -------------------------------------------------- | ---------------------------- |
| `pro_mob_*` (in `dynamic_attributes`) | Simple keys in `projeta_plus_furniture` dictionary | English naming + namespacing |
| `FM_Extensions::Exportar`             | `ProjetaPlus::Modules::ProFurnitureAttributes`     | Consistent namespace         |
| Hardcoded strings                     | `ProjetaPlus::Localization.t()`                    | Internationalization         |
| Mixed concerns                        | Separated modules                                  | Better organization          |
| Portuguese variables                  | English variables                                  | Code standardization         |

### Attribute Mapping

| Old Dictionary + Attribute                  | New Dictionary + Attribute               |
| ------------------------------------------- | ---------------------------------------- |
| `dynamic_attributes["pro_mob_nome"]`        | `projeta_plus_furniture["name"]`         |
| `dynamic_attributes["pro_mob_cor"]`         | `projeta_plus_furniture["color"]`        |
| `dynamic_attributes["pro_mob_marca"]`       | `projeta_plus_furniture["brand"]`        |
| `dynamic_attributes["pro_mob_tipo"]`        | `projeta_plus_furniture["type"]`         |
| `dynamic_attributes["pro_mob_dimensao"]`    | `projeta_plus_furniture["dimension"]`    |
| `dynamic_attributes["pro_mob_ambiente"]`    | `projeta_plus_furniture["environment"]`  |
| `dynamic_attributes["pro_mob_valor"]`       | `projeta_plus_furniture["value"]`        |
| `dynamic_attributes["pro_mob_link"]`        | `projeta_plus_furniture["link"]`         |
| `dynamic_attributes["pro_mob_observacoes"]` | `projeta_plus_furniture["observations"]` |
| `dynamic_attributes["pro_mob_cod"]`         | `projeta_plus_furniture["code"]`         |

## Usage Examples

### Save Furniture Attributes (Frontend)

```javascript
const data = {
  name: 'Mesa de Jantar',
  color: 'Branco',
  brand: 'Tok&Stok',
  type: 'Furniture',
  width: '120',
  depth: '80',
  height: '75',
  environment: 'Sala de Jantar',
  value: 'R$ 1.500,00',
};

const result = await sketchup.save_furniture_attributes(JSON.stringify(data));
```

### Resize Component (Frontend)

```javascript
// Proportional resize
await sketchup.resize_proportional(1.5); // 150% of original size

// Independent resize
await sketchup.resize_independent(150, 100, 80); // cm
```

### Export Reports (Frontend)

```javascript
// Export single category to CSV
await sketchup.export_furniture_category_csv('Furniture');

// Export multiple categories to XLSX
const categories = ['Furniture', 'Appliances'];
await sketchup.export_furniture_xlsx(JSON.stringify(categories));
```

## Future Enhancements

Potential improvements for future versions:

1. **Bulk Operations** - Apply changes to multiple components at once
2. **Templates** - Save/load furniture attribute templates
3. **Import** - Import furniture data from CSV/XLSX
4. **3D Visualization** - Real-time dimension overlay in viewport
5. **History** - Track attribute changes over time
6. **Search/Filter** - Advanced filtering in reports
7. **Custom Fields** - User-defined attributes
8. **Cost Calculator** - Automatic cost totaling and budgeting

## Testing Checklist

- [ ] Create new furniture component
- [ ] Set all attributes
- [ ] Resize proportionally
- [ ] Resize independently
- [ ] Generate reports
- [ ] Export to CSV
- [ ] Export to XLSX
- [ ] Isolate component
- [ ] Test all furniture types
- [ ] Verify localization (EN, PT-BR, ES)
- [ ] Test cache invalidation
- [ ] Verify dimension calculations
- [ ] Test name generation and clipboard

## Notes

- All dimension values are stored in centimeters internally
- Components are stored in the definition, shared across instances
- The module respects SketchUp's coordinate system (width=X, depth=Y, height=Z)
- Excel export requires WIN32OLE (Windows only)
- CSV export works on all platforms
