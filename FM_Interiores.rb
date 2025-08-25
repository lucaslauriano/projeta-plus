require 'sketchup.rb'
require 'extensions.rb'

module FM_Extensions
  module FM_Interiores

    # Load the extension.
    extension = SketchupExtension.new(
      'FM Interiores', 
      File.join(__dir__, 'FM_Interiores', 'fm_interiores_file.rb')
    )
    extension.description = 'Botões Gerais para Desenvolver um Projeto de Interiores.'
    extension.version = '1.0.0' 
    extension.creator = 'Francieli Madeira'
    extension.copyright = '© Francieli Madeira, 2024'

    # Register the extension with SketchUp.
    Sketchup.register_extension(extension, true)

  end # FM_Interiores
end # FM_Extensions
