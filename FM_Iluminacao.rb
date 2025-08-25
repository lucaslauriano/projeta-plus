require 'sketchup.rb'
require 'extensions.rb'

module FM_Extensions
  module FM_PontosIluminacao

    # Load the extension.
    extension = SketchupExtension.new(
      'FM Pontos Iluminacao', 
      File.join(__dir__, 'FM_Iluminacao', 'fm_iluminacao_file.rb') # Corrigido o nome do arquivo
    )
    extension.description = 'Blocos Dinâmicos de Pontos de Iluminação.'
    extension.version = '1.0.0'
    extension.creator = 'Francieli Madeira'
    extension.copyright = '© Francieli Madeira, 2024'

    # Register the extension with SketchUp.
    Sketchup.register_extension(extension, true)

  end # FM_PontosIluminacao
end # FM_Extensions
