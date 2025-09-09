require "sketchup.rb"
require "extensions.rb"

module ProjetaPlus
  VERSION = "1.0.0".freeze

  PATH = File.dirname(__FILE__).freeze

  extension = SketchupExtension.new("PROJETA PLUS", File.join(PATH, 'projeta_plus', 'main.rb'))
  extension.description = "Projeta+ - A plugin  library "
  extension.version = VERSION
  extension.copyright = "My Awesome Company © 2025"
  extension.creator = "Lucas" # Seu nome como criador

  Sketchup.register_extension(extension, true)

  puts "PROJETA PLUS v#{VERSION} registered and awaiting activation!"
end