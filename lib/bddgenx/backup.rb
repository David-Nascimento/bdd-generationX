require 'fileutils'
require 'time'

module Bddgenx
  class Backup
    def self.salvar_versao_antiga(caminho)
      return unless File.exist?(caminho)

      FileUtils.mkdir_p("backup")
      base = File.basename(caminho, ".feature")
      timestamp = Time.now.strftime("%Y%m%d_%H%M%S")
      destino = "backup/#{base}_#{timestamp}.feature"

      FileUtils.cp(caminho, destino)
      puts "📦 Backup criado: #{destino}"
    end
  end
end
