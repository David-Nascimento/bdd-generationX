# lib/bddgenx/tracer.rb
# encoding: utf-8
#
# Este arquivo define a classe Tracer, responsável por gerar e manter
# informações de rastreabilidade de cenários e passos em um arquivo CSV.
# Útil para auditoria e análise de cobertura de cenários gerados.
module Bddgenx
  # Classe para adicionar registros de rastreabilidade a um relatório CSV.
  class Tracer
    # Adiciona entradas de rastreabilidade para cada passo de cada grupo
    # da história em um arquivo CSV localizado em 'reports/output/rastreabilidade.csv'.
    #
    # @param historia [Hash]
    #   Objeto de história contendo :quero (título da funcionalidade) e :grupos,
    #   onde cada grupo possui :tipo, :tag, e :passos (Array<String>)
    # @param nome_arquivo_feature [String]
    #   Nome do arquivo .feature de onde os passos foram gerados
    # @return [void]
    def self.adicionar_entrada(historia, nome_arquivo_feature)
      # Garante existência do diretório de saída
      FileUtils.mkdir_p('reports/output')
      arquivo_csv = 'reports/output/rastreabilidade.csv'

      # Cabeçalho padrão do CSV: identifica colunas
      cabecalho = ['Funcionalidade', 'Tipo', 'Tag', 'Cenário', 'Passo', 'Origem']

      linhas = []

      # Itera sobre grupos de passos para compor linhas de rastreabilidade
      historia[:grupos].each_with_index do |grupo, idx|
        tipo  = grupo[:tipo]
        tag   = grupo[:tag]
        passos = grupo[:passos] || []

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

      # Escreve ou anexa as linhas geradas ao CSV
      escrever_csv(arquivo_csv, cabecalho, linhas)
    end

    # Escreve ou anexa registros em um arquivo CSV, criando cabeçalho se necessário.
    #
    # @param caminho [String] Caminho completo para o arquivo CSV de rastreabilidade
    # @param cabecalho [Array<String>] Array de títulos das colunas a serem escritos
    # @param linhas [Array<Array<String>>] Dados a serem gravados no CSV (cada sub-array é uma linha)
    # @return [void]
    def self.escrever_csv(caminho, cabecalho, linhas)
      # Verifica se é um novo arquivo para incluir o cabeçalho
      novo_arquivo = !File.exist?(caminho)

      CSV.open(caminho, 'a+', col_sep: ';', force_quotes: true) do |csv|
        csv << cabecalho if novo_arquivo
        linhas.each { |linha| csv << linha }
      end
    end
  end
end
