require 'csv'
require 'fileutils'

module Tracer
  ARQUIVO = 'output/rastreabilidade.csv'

  def self.adicionar_entrada(historia, caminho_arquivo)
    FileUtils.mkdir_p("output")

    CSV.open(ARQUIVO, File.exist?(ARQUIVO) ? 'a' : 'w', col_sep: ';') do |csv|
      unless File.exist?(ARQUIVO)
        csv << ["Funcionalidade", "Tipo de Teste", "Nome do Cenário", "Arquivo .feature"]
      end

      historia[:blocos].each do |tipo, passos|
        next if tipo == "CONTEXT" || tipo == "EXAMPLES" || passos.empty?

        tipo_istqb = tipo.capitalize.gsub('_', ' ').capitalize
        contexto = passos.first&.gsub(/^(Dado que|Quando|Então|E)/, '')&.strip || "Condição"
        resultado = passos.last&.gsub(/^(Então|E)/, '')&.strip || "Resultado"
        nome_cenario = "#{tipo_istqb} - #{contexto} - #{resultado}"

        csv << [
          historia[:quero].sub(/^Quero/, '').strip,
          tipo_istqb,
          nome_cenario,
          caminho_arquivo
        ]
      end
    end
  end
end
