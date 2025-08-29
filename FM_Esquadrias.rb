require 'sketchup.rb'
require 'extensions.rb'

module FM_Extensions
  module FM_Esquadrias

    # Load the extension.
    extension = SketchupExtension.new(
      'FM Esquadrias', 
      File.join(__dir__, 'FM_Esquadrias', 'fm_esquadrias_file.rb')
    )
    extension.description = 'Ferramenta para criar anotações em esquadrias automaticamente em planta.'
    extension.version = '1.0.0' 
    extension.creator = 'Francieli Madeira'
    extension.copyright = '© Francieli Madeira, 2024'

    # Register the extension with SketchUp.
    Sketchup.register_extension(extension, true)

  end # FM_PontosTecnicos
end # FM_Extensions
