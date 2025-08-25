require "sketchup.rb"
require "extensions.rb"

# Define o módulo principal para o plugin para encapsular todo o código e evitar conflitos.
module ProjetaPlus
  # Define a versão do plugin.
  VERSION = "1.0.0".freeze

  # Obtém o caminho para o diretório atual onde este arquivo reside.
  # Isso é crucial para carregar outros arquivos relativos à raiz do plugin.
  PATH = File.dirname(__FILE__).freeze

  # Define o objeto de extensão para o Gerenciador de Extensões do SketchUp.
  # O segundo argumento deve apontar para o script principal que o SketchUp carregará
  # quando a extensão for habilitada. Este será um novo arquivo: 'main.rb'.
  extension = SketchupExtension.new("PROJETA PLUS", File.join(PATH, 'projeta_plus', 'main.rb'))
  extension.description = "A sample SketchUp plugin with a toolbar and five buttons."
  extension.version = VERSION
  extension.copyright = "My Awesome Company © 2025"
  extension.creator = "Lucas" # Seu nome como criador

  # Registra a extensão no SketchUp.
  # O argumento `true` garante que ela seja visível no Gerenciador de Extensões.
  Sketchup.register_extension(extension, true)

  # Adiciona uma mensagem ao Console Ruby indicando que o plugin foi registrado.
  puts "PROJETA PLUS v#{VERSION} registered and awaiting activation!"
end