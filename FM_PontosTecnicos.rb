# encoding: UTF-8

require 'sketchup.rb'
require 'extensions.rb'

module FM_Extensions
  module FM_PontosTecnicos

    # Load the extension.
    extension = SketchupExtension.new(
      'FM Pontos Técnicos', 
      File.join(__dir__, 'FM_PontosTecnicos', 'fm_pontostecnicos_file.rb')
    )
    extension.description = 'Blocos Dinâmicos de Pontos Técnicos.'
    extension.version = '1.0.0'
    extension.creator = 'Francieli Madeira'
    extension.copyright = '© Francieli Madeira, 2024'

    # Register the extension with SketchUp.
    Sketchup.register_extension(extension, true)

  end # FM_PontosTecnicos
end # FM_Extensions
