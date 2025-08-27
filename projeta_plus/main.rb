require "sketchup.rb"

# Verifica se o módulo ProjetaPlus e sua constante PATH já foram definidos pelo arquivo principal.
# (Em uso normal com o Extension Manager, eles já estarão definidos).
unless defined?(ProjetaPlus) && defined?(ProjetaPlus::PATH)
  module ProjetaPlus
    PATH = File.dirname(__FILE__).freeze # Fallback para PATH, caso seja carregado diretamente
  end
end

# Carrega 'commands.rb' ANTES de 'core.rb', pois 'core.rb' depende de 'commands.rb'.
require File.join(ProjetaPlus::PATH, 'projeta_plus', 'commands.rb')
require File.join(ProjetaPlus::PATH, 'projeta_plus', 'core.rb')


puts "PROJETA PLUS main.rb loaded. All components prepared for activation."