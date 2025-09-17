# encoding: UTF-8
require 'sketchup.rb'

module ProjetaPlus
  module Settings
    # Namespace for SketchUp's preference storage for global settings
    PLUGIN_ID = "ProjetaPlus_GlobalSettings".freeze

    # --- Configuration Options Definitions (with frontend hints) ---

    def self.get_available_fonts
      [
        "Arial",
        "Arial Narrow",
        "Century Gothic",
        "Helvetica",
        "Times New Roman",
        "Verdana"
      ]
    end

    def self.get_measurement_units
      [
        "Centímetros",
        "Metros",
        "Polegadas" # Inches
      ]
    end

    def self.get_area_units
      [
        "Centímetros",
        "Metros",
        "Polegadas" # Inches
      ]
    end

    # --- NOVO: Configuração de Idioma ---
    def self.get_available_languages
      [
        { code: "en", name: "English" },
        { code: "pt-BR", name: "Português (Brasil)" },
        { code: "es", name: "Español" }
      ]
    end

    # Helper method to get just the language codes
    def self.get_available_language_codes
      get_available_languages.map { |lang| lang[:code] }
    end

    # Helper method to get language name by code
    def self.get_language_name_by_code(code)
      language = get_available_languages.find { |lang| lang[:code] == code }
      language ? language[:name] : code
    end
    # --- FIM NOVO ---

    def self.get_sketchup_model_display_units
      model = Sketchup.active_model
      length_unit_id = model.options['UnitsOptions']['LengthUnit']
      
      case length_unit_id
      when 0, 1
        return { length: "Polegadas", area: "Polegadas" }
      when 2
        return { length: "Centímetros", area: "Centímetros" }
      when 3
        return { length: "Centímetros", area: "Centímetros" }
      when 4
        return { length: "Metros", area: "Metros" }
      else
        return { length: "Metros", area: "Metros" }
      end
    end

    # --- Default Values for Global Settings ---
    DEFAULT_FONT = "Century Gothic".freeze
    DEFAULT_SCALE_NUMERATOR = 1
    DEFAULT_SCALE_DENOMINATOR = 50
    DEFAULT_FLOOR_LEVEL = 0.0
    DEFAULT_CUT_HEIGHT = 1.45
    DEFAULT_HEADROOM_HEIGHT = 2.50
    DEFAULT_STYLES_FOLDER = "".freeze
    DEFAULT_SHEETS_FOLDER = "".freeze
    # --- NOVO: Idioma Padrão ---
    DEFAULT_LANGUAGE = "en".freeze
    # --- FIM NOVO ---

    # Reads a specific setting from SketchUp's preferences.
    # @param key [String] The key of the setting (e.g., "Font").
    # @param default_value [Object] The value to return if the setting is not found.
    # @return [Object] The stored setting or the default value.
    def self.read(key, default_value)
      Sketchup.read_default(PLUGIN_ID, key, default_value)
    end

    # Writes a specific setting to SketchUp's preferences.
    # @param key [String] The key of the setting.
    # @param value [Object] The value to store.
    def self.write(key, value)
      Sketchup.write_default(PLUGIN_ID, key, value)
    end

    # Retrieves all current settings, applying SketchUp's model units as initial defaults.
    # @return [Hash] A hash containing all settings and their current values.
    def self.get_all_settings
      sketchup_units = get_sketchup_model_display_units

      {
        'font' => read("Font", DEFAULT_FONT),
        'measurement_unit' => read("MeasurementUnit", sketchup_units[:length]),
        'area_unit' => read("AreaUnit", sketchup_units[:area]),
        'scale_numerator' => read("ScaleNumerator", DEFAULT_SCALE_NUMERATOR),
        'scale_denominator' => read("ScaleDenominator", DEFAULT_SCALE_DENOMINATOR),
        'floor_level' => read("FloorLevel", DEFAULT_FLOOR_LEVEL),
        'cut_height' => read("CutHeight", DEFAULT_CUT_HEIGHT),
        'headroom_height' => read("HeadroomHeight", DEFAULT_HEADROOM_HEIGHT),
        'styles_folder' => read("StylesFolder", DEFAULT_STYLES_FOLDER),
        'sheets_folder' => read("SheetsFolder", DEFAULT_SHEETS_FOLDER),
        # --- NOVO: Adiciona a configuração de idioma ---
        'language' => read("Language", DEFAULT_LANGUAGE),
        # --- FIM NOVO ---
        'frontend_options' => {
          'fonts' => get_available_fonts,
          'measurement_units' => get_measurement_units,
          'area_units' => get_area_units,
          # --- NOVO: Adiciona opções de idioma para o frontend ---
          'languages' => get_available_languages
          # --- FIM NOVO ---
        }
      }
    end

    # Updates a specific setting.
    def self.update_setting(args)
      key = args['key'].to_s
      value = args['value']

      if key.empty?
        return { success: false, message: "Invalid arguments for update_setting: 'key' is required." }
      end

      case key
      when 'scale_numerator', 'scale_denominator', 'floor_level', 'cut_height', 'headroom_height'
        value = value.to_f
        if (key == 'scale_numerator' || key == 'scale_denominator') && value <= 0
          return { success: false, message: "Scale values must be positive." }
        end
      when 'language'
        # Basic validation: ensure the selected language code is in the list of available languages
        unless get_available_languages.map { |lang| lang[:code] }.include?(value)
          return { success: false, message: "Invalid language code provided." }
        end
      end

      write(key, value)
      
      # Special handling for language changes - update the active localization and toolbar
      if key == 'language'
        ProjetaPlus::Localization.set_language(value)
        # Update the language button in the toolbar
        if defined?(ProjetaPlus::Commands) && ProjetaPlus::Commands.respond_to?(:update_language_button_text)
          ProjetaPlus::Commands.update_language_button_text
        end
      end
      { success: true, message: "Setting '#{key}' updated successfully to '#{value}'.", updated_value: value, setting_key: key }
    rescue StandardError => e
      { success: false, message: "Error updating setting '#{key}': #{e.message}" }
    end

    # Opens a native SketchUp folder selection dialog.
    def self.select_folder_path(args)
      setting_key = args['setting_key'].to_s
      dialog_title = args['dialog_title'] || "Select Folder"

      unless setting_key && !setting_key.empty?
        return { success: false, message: "Missing 'setting_key' for folder selection." }
      end

      selected_folder = UI.select_folder(title: dialog_title, select_directories: true)

      if selected_folder
        write(setting_key, selected_folder)
        { success: true, message: "Folder for '#{setting_key}' selected.", path: selected_folder, setting_key: setting_key }
      else
        { success: false, message: "Folder selection cancelled for '#{setting_key}'." }
      end
    rescue StandardError => e
      { success: false, message: "Error selecting folder for '#{setting_key}': #{e.message}" }
    end

  end # module Settings
end # module ProjetaPlus