module Bddgenx
  # Caminho absoluto para o arquivo VERSION, que fica 3 níveis acima deste arquivo:
  # lib/bddgenx/version.rb → lib/bddgenx → lib → raiz do projeto
  VERSION_FILE = File.expand_path("../../../VERSION", __FILE__)

  # Lê o conteúdo do arquivo VERSION para definir a constante VERSION
  # Se o arquivo não existir, exibe um aviso e define o valor padrão "0.0.0"
  VERSION = if File.exist?(VERSION_FILE)
              File.read(VERSION_FILE).strip
            else
              warn "WARNING: VERSION file not found, defaulting to 0.0.0"
              "0.0.0"
            end
end
