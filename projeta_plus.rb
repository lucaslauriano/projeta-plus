require "sketchup.rb"
require "extensions.rb"

module ProjetaPlus
  VERSION = "2.0.0".freeze
  PATH = File.dirname(__FILE__).freeze

  extension = SketchupExtension.new("PROJETA PLUS", File.join(PATH, 'projeta_plus', 'main.rb'))
  extension.description = "Ferramenta completa para anotações arquitetônicas, ambientes, iluminação e gestão de projetos no SketchUp."
  extension.version = VERSION
  extension.copyright = "© 2025 Francieli Madeira & Lucas Lauriano"
  extension.creator = "Francieli Madeira & Lucas Lauriano"
  
  # Adicionar metadados adicionais
  Sketchup.register_extension(extension, true)

  puts "PROJETA PLUS v#{VERSION} carregado com sucesso!"
end