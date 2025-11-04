# encoding: UTF-8
require 'sketchup.rb'
require_relative 'pro_settings.rb'

module ProjetaPlus
  module Modules
    module ProSettingsUtils
      
      def self.get_scale
        if defined?(ProjetaPlus::Modules::ProSettings)
          numerator = ProjetaPlus::Modules::ProSettings.read("scale_numerator", 1).to_f
          denominator = ProjetaPlus::Modules::ProSettings.read("scale_denominator", 25).to_f
          denominator > 0 ? denominator / numerator : 25.0
        else
          25.0
        end
      end

      def self.get_font
        if defined?(ProjetaPlus::Modules::ProSettings)
          ProjetaPlus::Modules::ProSettings.read("font", "Century Gothic")
        else
          "Century Gothic"
        end
      end

      def self.get_floor_level
        if defined?(ProjetaPlus::Modules::ProSettings)
          floor_level = ProjetaPlus::Modules::ProSettings.read("floor_level", ProjetaPlus::Modules::ProSettings::DEFAULT_FLOOR_LEVEL).to_f
          format('%.2f', floor_level).gsub('.', ',')
        else
          "0,00"
        end
      end

      def self.get_cut_height_cm
        if defined?(ProjetaPlus::Modules::ProSettings)
          cut_height_m = ProjetaPlus::Modules::ProSettings.read("cut_height", ProjetaPlus::Modules::ProSettings::DEFAULT_CUT_HEIGHT).to_f
          (cut_height_m * 100).to_s 
        else
          "145"
        end
      end

      def self.get_text_color
        if defined?(ProjetaPlus::Modules::ProSettings)
          ProjetaPlus::Modules::ProSettings.read("text_color", ProjetaPlus::Modules::ProSettings::DEFAULT_TEXT_COLOR)
        else
          "black"
        end
      end

    end # module ProSettingsUtils
  end # module Modules
end # module ProjetaPlus
