# lib/bddgenx/backup.rb
# encoding: utf-8
#
# Este arquivo define a classe Backup, responsável por criar cópias de segurança
# de arquivos .feature antes de serem sobrescritos.
# As cópias são salvas em 'reports/backup' com timestamp no nome.
module Bddgenx
  # Gerencia a criação de backups de arquivos .feature
  class Backup
    # Salva uma versão antiga de um arquivo .feature em reports/backup,
    # adicionando um timestamp ao nome do arquivo.
    #
    # @param caminho [String] Caminho completo para o arquivo .feature original
    # @return [void]
    # @note Se o arquivo não existir, não faz nada
    def self.salvar_versao_antiga(caminho)
      return unless File.exist?(caminho)

      pasta     = 'reports/backup'
      FileUtils.mkdir_p(pasta)

      base      = File.basename(caminho, '.feature')
      timestamp = Time.now.strftime('%Y%m%d_%H%M%S')
      destino   = "reports/backup/#{base}_#{timestamp}.feature"

      FileUtils.cp(caminho, destino)
      puts "📦 Backup criado: #{destino}"
    end
  end
end
