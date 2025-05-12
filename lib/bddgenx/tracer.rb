require 'csv'
require 'fileutils'

module Bddgenx
  class Tracer
    def self.adicionar_entrada(historia, nome_arquivo_feature)
      FileUtils.mkdir_p('output')
      arquivo_csv = 'output/rastreabilidade.csv'

      cabecalho = ['Funcionalidade', 'Tipo', 'Tag', 'Cenário', 'Passo', 'Origem']

      linhas = []

      historia[:grupos].each_with_index do |grupo, idx|
        tipo = grupo[:tipo]
        tag  = grupo[:tag]
        passos = grupo[:passos]

        nome_funcionalidade = historia[:quero].gsub(/^Quero\s*/, '').strip
        nome_cenario = "Cenário #{idx + 1}"

        passos.each do |passo|
          linhas << [
            nome_funcionalidade,
            tipo,
            tag || '-',
            nome_cenario,
            passo,
            File.basename(nome_arquivo_feature)
          ]
        end
      end

      escrever_csv(arquivo_csv, cabecalho, linhas)
    end

    def self.escrever_csv(caminho, cabecalho, linhas)
      novo_arquivo = !File.exist?(caminho)

      CSV.open(caminho, 'a+', col_sep: ';', force_quotes: true) do |csv|
        csv << cabecalho if novo_arquivo
        linhas.each { |linha| csv << linha }
      end
    end
  end
end
