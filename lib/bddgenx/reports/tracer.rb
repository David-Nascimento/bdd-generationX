# encoding: utf-8
#
# Este arquivo define a classe `Tracer`, responsável por gerar arquivos de rastreabilidade
# (CSV) a partir das features geradas automaticamente pela gem BDDGenX.
#
# Para cada feature processada, o `Tracer` extrai os cenários da própria feature `.feature`
# e associa cada passo definido na história original com o bloco Gherkin correspondente.
# O objetivo é fornecer visibilidade e rastreabilidade completa entre requisitos e testes.

require 'csv'
require 'fileutils'

module Bddgenx
  # Classe responsável por rastrear os artefatos gerados pela gem
  # e exportá-los em arquivos CSV, um por funcionalidade.
  #
  # Para cada grupo de passos (do `.txt`), associa os dados com o
  # cenário equivalente gerado no arquivo `.feature`.
  class Tracer
    ##
    # Adiciona entradas de rastreabilidade a um CSV baseado na feature gerada.
    #
    # - Cada funcionalidade recebe um arquivo CSV próprio, salvo em:
    #   `reports/output/funcionalidade_<nome>.csv`
    #
    # - A coluna "BDD" contém o cenário completo extraído diretamente do `.feature`,
    #   preservando a sintaxe original do Gherkin (cenário, steps, tags).
    #
    # @param historia [Hash]
    #   Hash representando a história extraída do `.txt`, contendo:
    #   - :quero  → nome da funcionalidade
    #   - :grupos → lista de blocos com :tipo, :tag e :passos
    #
    # @param feature_path [String]
    #   Caminho do arquivo `.feature` já gerado no sistema
    #
    # @return [void]
    def self.adicionar_entrada(historia, feature_path)
      FileUtils.mkdir_p('reports/output')

      nome_funcionalidade = historia[:quero].gsub(/^Quero\s*/, '').strip
      nome_funcionalidade_sanitizado = nome_funcionalidade.downcase.gsub(/[^a-z0-9]+/, '_')
      arquivo_csv = "reports/output/funcionalidade_#{nome_funcionalidade_sanitizado}.csv"

      cabecalho = ['Funcionalidade', 'Tipo', 'Tag', 'Cenário', 'Passo', 'Origem', 'BDD']
      linhas = []

      # Leitura real da feature gerada
      blocos_gherkin = extrair_cenarios_gherkin(feature_path)

      historia[:grupos].each_with_index do |grupo, idx|
        tipo  = grupo[:tipo]
        tag   = grupo[:tag] || '-'
        passos = grupo[:passos] || []
        nome_cenario = "Cenário #{idx + 1}"

        # Bloco Gherkin real do cenário gerado
        gherkin_bloco = blocos_gherkin[idx] || ''

        passos.each do |passo|
          linhas << [
            nome_funcionalidade,
            tipo,
            tag,
            nome_cenario,
            passo,
            File.basename(feature_path),
            gherkin_bloco
          ]
        end
      end

      escrever_csv(arquivo_csv, cabecalho, linhas)
    end

    ##
    # Escreve ou anexa dados em um arquivo CSV.
    # - Cria o cabeçalho caso seja a primeira escrita.
    # - Evita duplicações com base na combinação "Passo + Origem".
    #
    # @param caminho [String] Caminho completo do arquivo CSV a ser salvo
    # @param cabecalho [Array<String>] Títulos das colunas do CSV
    # @param novas_linhas [Array<Array>] Linhas de conteúdo a serem gravadas
    #
    # @return [void]
    def self.escrever_csv(caminho, cabecalho, novas_linhas)
      novo_arquivo = !File.exist?(caminho)

      existentes = []
      if File.exist?(caminho)
        existentes = CSV.read(caminho, col_sep: ';', headers: true).map do |row|
          [row['Passo'], row['Origem']]
        end
      end

      CSV.open(caminho, 'a+', col_sep: ';', force_quotes: true) do |csv|
        csv << cabecalho if novo_arquivo

        novas_linhas.each do |linha|
          passo, origem = linha[4], linha[5]
          next if existentes.include?([passo, origem])
          csv << linha
        end
      end
    end

    ##
    # Extrai todos os cenários completos do arquivo `.feature` gerado,
    # preservando a estrutura Gherkin original (cenários, tags, steps).
    #
    # Um novo bloco é iniciado quando uma das palavras-chave de título
    # de cenário é encontrada.
    #
    # @param feature_path [String] Caminho completo do arquivo `.feature`
    # @return [Array<String>] Lista de blocos Gherkin, um por cenário
    def self.extrair_cenarios_gherkin(feature_path)
      return [] unless File.exist?(feature_path)

      content = File.read(feature_path)
      linhas = content.lines

      blocos = []
      bloco_atual = []
      capturando = false

      linhas.each_with_index do |linha, i|
        if linha.strip =~ /^(Scenario|Scenario Outline|Cenário|Esquema do Cenário):/i
          # Novo cenário → salva anterior
          blocos << bloco_atual.join if bloco_atual.any?
          bloco_atual = [linha]
          capturando = true
        elsif capturando
          bloco_atual << linha
        end
      end

      blocos << bloco_atual.join if bloco_atual.any?
      blocos
    end
  end
end
