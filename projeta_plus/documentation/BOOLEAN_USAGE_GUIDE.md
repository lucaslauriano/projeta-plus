# Boolean Usage Guide

## Frontend to Backend Communication

### Sending Data to Backend (JavaScript to Ruby)

```javascript
// ✅ CORRECT - Send as boolean
const roomData = {
  enviroment_name: 'Sala de Estar',
  floor_height: '0.00',
  show_ceilling_height: true, // Boolean
  ceilling_height: '2.60',
  show_level: false, // Boolean
  level: '0.00',
};

// ✅ ALSO CORRECT - Send as string (will be converted)
const roomDataFromForm = {
  enviroment_name: 'Cozinha',
  floor_height: '0.00',
  show_ceilling_height: 'true', // String - will be converted to boolean
  ceilling_height: '2.60',
  show_level: 'false', // String - will be converted to boolean
  level: '0.00',
};

// ✅ PORTUGUESE SUPPORT - Send as Portuguese strings
const roomDataPortuguese = {
  enviroment_name: 'Quarto',
  floor_height: '0.00',
  show_ceilling_height: 'sim', // Will be converted to true
  ceilling_height: '2.60',
  show_level: 'não', // Will be converted to false
  level: '0.00',
};
```

### Receiving Data from Backend (Ruby to JavaScript)

```javascript
// Backend will send boolean values in JSON
window.handleRoomDefaults = function (defaults) {
  console.log(defaults.show_ceilling_height); // true or false (boolean)
  console.log(defaults.show_level); // true or false (boolean)

  // Use directly in your form
  document.getElementById('showCeiling').checked =
    defaults.show_ceilling_height;
  document.getElementById('showLevel').checked = defaults.show_level;
};
```

## Backend Boolean Conversion

The `convert_to_boolean` method supports multiple input formats:

### String Inputs → Boolean

- `"true"`, `"sim"`, `"yes"`, `"1"`, `"on"` → `true`
- `"false"`, `"não"`, `"no"`, `"0"`, `"off"`, `""` → `false`

### Other Inputs → Boolean

- `true`/`false` → unchanged
- Numbers: `0` → `false`, any other number → `true`
- `nil` → `false`
- Other truthy values → `true`

## Migration Notes

### Before (String-based)

```ruby
show_ceilling_height = args['show_ceilling_height'].to_s.strip.downcase == "sim"
DEFAULT_ROOM_ANNOTATION_SHOW_CEILLING_HEIGHT = "Sim"
```

### After (Boolean-based)

```ruby
show_ceilling_height = convert_to_boolean(args['show_ceilling_height'])
DEFAULT_ROOM_ANNOTATION_SHOW_CEILLING_HEIGHT = true
```

## Benefits

1. **Type Safety**: Boolean values are properly typed
2. **Internationalization**: Supports multiple languages ("sim"/"não", "yes"/"no")
3. **Flexibility**: Accepts multiple input formats
4. **Consistency**: Frontend receives proper boolean JSON values
5. **Future-proof**: Easy to extend for other boolean fields

## Frontend Form Integration

```html
<!-- Checkbox inputs work directly -->
<input type="checkbox" id="showCeiling" name="show_ceilling_height" />
<input type="checkbox" id="showLevel" name="show_level" />

<script>
  // When loading defaults
  window.handleRoomDefaults = function (defaults) {
    document.getElementById('showCeiling').checked =
      defaults.show_ceilling_height;
    document.getElementById('showLevel').checked = defaults.show_level;
  };

  // When submitting form
  function submitRoomAnnotation() {
    const formData = {
      enviroment_name: document.getElementById('envName').value,
      show_ceilling_height: document.getElementById('showCeiling').checked, // Boolean
      show_level: document.getElementById('showLevel').checked, // Boolean
      // ... other fields
    };

    // Send to backend
    sketchup.startRoomAnnotation(JSON.stringify(formData));
  }
</script>
```
