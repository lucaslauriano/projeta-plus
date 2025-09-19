# encoding: UTF-8
require 'sketchup.rb'
require_relative 'pro_settings.rb'

module ProjetaPlus
  module Modules
    module ProSettingsUtils
      
      # Get scale factor from settings with fallback
      def self.get_scale
        if defined?(ProjetaPlus::Modules::ProSettings)
          numerator = ProjetaPlus::Modules::ProSettings.read("ScaleNumerator", 1).to_f
          denominator = ProjetaPlus::Modules::ProSettings.read("ScaleDenominator", 25).to_f
          denominator > 0 ? denominator / numerator : 25.0
        else
          25.0
        end
      end

      # Get font from settings with fallback
      def self.get_font
        if defined?(ProjetaPlus::Modules::ProSettings)
          ProjetaPlus::Modules::ProSettings.read("Font", "Century Gothic")
        else
          "Century Gothic"
        end
      end

      # Get floor level from settings with fallback, formatted as string
      def self.get_floor_level
        if defined?(ProjetaPlus::Modules::ProSettings)
          floor_level = ProjetaPlus::Modules::ProSettings.read("FloorLevel", ProjetaPlus::Modules::ProSettings::DEFAULT_FLOOR_LEVEL).to_f
          format('%.2f', floor_level).gsub('.', ',')
        else
          "0,00"
        end
      end

      # Get cut height from settings with fallback, in centimeters as string
      def self.get_cut_height_cm
        if defined?(ProjetaPlus::Modules::ProSettings)
          cut_height_m = ProjetaPlus::Modules::ProSettings.read("CutHeight", ProjetaPlus::Modules::ProSettings::DEFAULT_CUT_HEIGHT).to_f
          (cut_height_m * 100).to_s 
        else
          "145"
        end
      end

    end # module ProSettingsUtils
  end # module Modules
end # module ProjetaPlus
