require 'fileutils'

module Bddgenx
  module Verificador
    # Impede sobrescrita de arquivos existentes
    def self.gerar_arquivo_se_novo(caminho, novo_conteudo)
      if File.exist?(caminho)
        conteudo_atual = File.read(caminho, encoding: 'utf-8').strip
        return false if conteudo_atual == novo_conteudo.strip

        puts "⚠️  Arquivo já existe: #{caminho} — não será sobrescrito."
        return false
      end

      FileUtils.mkdir_p(File.dirname(caminho))
      File.write(caminho, novo_conteudo)
      true
    end
  end
end
