require 'sketchup.rb'
require 'extensions.rb'

module FM_Extensions
  module FM_Mobiliario

    # Load the extension.
    extension = SketchupExtension.new(
      'FM Mobiliário', 
      File.join(__dir__, 'FM_Mobiliario', 'fm_mobiliario_file.rb')
    )
    extension.description = 'Dimensionamento e Quantitativo de Mobiliário, Eletros e Louças e Metais.'
    extension.version = '1.0.0' 
    extension.creator = 'Francieli Madeira'
    extension.copyright = '© Francieli Madeira, 2024'

    # Register the extension with SketchUp.
    Sketchup.register_extension(extension, true)

  end # FM_Mobiliario
end # FM_Extensions
