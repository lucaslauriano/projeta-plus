require 'sketchup.rb'
require 'extensions.rb'

module FM_Extensions
  module FM_RevestimentosRodapes

    # Load the extension.
    extension = SketchupExtension.new(
      'FM Revestimentos e Rodapes', 
      File.join(__dir__, 'FM_RevestimentosRodapes', 'fm_revestimentosrodapes_file.rb')
    )
    extension.description = 'Blocos Dinâmicos e Quantitativo de Revestimentos e Rodapés.'
    extension.version = '1.0.0' 
    extension.creator = 'Francieli Madeira'
    extension.copyright = '© Francieli Madeira, 2024'

    # Register the extension with SketchUp.
    Sketchup.register_extension(extension, true)

  end # FM_RevestimentosRodapes
end # FM_Extensions
