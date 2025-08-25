require 'sketchup.rb'
require 'extensions.rb'

module FM_Extensions
  module FM_Anotacoes

    # Load the extension.
    extension = SketchupExtension.new(
      'FM Anotações', 
      File.join(__dir__, 'FM_Anotacoes', 'fm_anotacoes_file.rb')
    )
    extension.description = 'Ferramenta para criar anotações automaticamente em planta do nome do ambiente e planos de corte.'
    extension.version = '1.0.0' 
    extension.creator = 'Francieli Madeira'
    extension.copyright = '© Francieli Madeira, 2024'

    # Register the extension with SketchUp.
    Sketchup.register_extension(extension, true)

  end # FM_PontosTecnicos
end # FM_Extensions
