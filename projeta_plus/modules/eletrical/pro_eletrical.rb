# encoding: UTF-8
require 'sketchup.rb'
require 'json'
require_relative '../pro_blocks.rb'

module ProjetaPlus
  module Modules
    module Electrical

      PLUGIN_PATH = File.dirname(__FILE__)
      COMPONENTS_PATH = File.join(File.dirname(File.dirname(PLUGIN_PATH)), 'components', 'eletrical')

      def self.get_blocks_structure
        BlocksManager.get_blocks_structure(COMPONENTS_PATH)
      end

      def self.import_block(block_path)
        BlocksManager.import_block(block_path, COMPONENTS_PATH)
      end

      def self.open_blocks_folder
        BlocksManager.open_blocks_folder(COMPONENTS_PATH)
      end

    end
  end
end

