# lib/bddgenx/generator.rb
# encoding: utf-8
#
# Este arquivo define a classe Generator, responsável por gerar arquivos
# .feature a partir de um hash de história ou de um arquivo de história em texto.
# Suporta Gherkin em Português e Inglês, inclusão de tags, cenários simples
# e esquemas de cenário com exemplos.

require 'fileutils'

module Bddgenx
  # Gera cenários e arquivos .feature baseados em histórias e grupos de passos.
  class Generator
    # Palavras-chave Gherkin em Português
    # @return [Array<String>]
    GHERKIN_KEYS_PT = %w[Dado Quando Então E Mas].freeze

    # Palavras-chave Gherkin em Inglês
    # @return [Array<String>]
    GHERKIN_KEYS_EN = %w[Given When Then And But].freeze

    # Mapeamento PT -> EN
    # @return [Hash{String=>String}]
    GHERKIN_MAP_PT_EN = GHERKIN_KEYS_PT.zip(GHERKIN_KEYS_EN).to_h

    # Mapeamento EN -> PT
    # @return [Hash{String=>String}]
    GHERKIN_MAP_EN_PT = GHERKIN_KEYS_EN.zip(GHERKIN_KEYS_PT).to_h

    # Conjunto de todas as palavras-chave suportadas (PT + EN)
    # @return [Array<String>]
    ALL_KEYS = GHERKIN_KEYS_PT + GHERKIN_KEYS_EN

    # Seleciona apenas as linhas que representam exemplos do cenário
    #
    # @param raw [Array<String>] Lista de linhas brutas do bloco de exemplos
    # @return [Array<String>] Linhas que começam com '|' representando a tabela de exemplos
    def self.dividir_examples(raw)
      raw.select { |l| l.strip.start_with?('|') }
    end

    # Gera conteúdo de um arquivo .feature a partir de um hash de história ou caminho para arquivo
    #
    # @param input [Hash, String]
    #   Objeto de história com chaves :idioma, :quero, :como, :para, :grupos
    #   Ou caminho para um arquivo de história que será lido via Parser.ler_historia
    # @param override_path [String, nil]
    #   Caminho de saída alternativo para o arquivo .feature
    # @raise [ArgumentError] Se Parser.ler_historia lançar erro ao ler arquivo
    # @return [Array(String, String)] Array com caminho e conteúdo gerado
    def self.gerar_feature(input, override_path = nil)
      historia = input.is_a?(String) ? Parser.ler_historia(input) : input
      idioma   = historia[:idioma] || 'pt'

      # Geração do nome base do arquivo
      nome_base = historia[:quero]
                    .gsub(/[^a-z0-9]/i, '_')
                    .downcase
                    .split('_', 3)
                    .first(3)
                    .join('_')

      caminho = if override_path.is_a?(String)
                  override_path
                else
                  "features/#{nome_base}.feature"
                end

      # Definição das palavras-chave Gherkin conforme idioma
      palavras = {
        feature:  idioma == 'en' ? 'Feature'          : 'Funcionalidade',
        contexto: idioma == 'en' ? 'Background'       : 'Contexto',
        cenario:  idioma == 'en' ? 'Scenario'         : 'Cenário',
        esquema:  idioma == 'en' ? 'Scenario Outline' : 'Esquema do Cenário',
        exemplos: idioma == 'en' ? 'Examples'         : 'Exemplos',
        regra:    idioma == 'en' ? 'Rule'             : 'Regra'
      }

      # Cabeçalho do arquivo .feature
      conteudo = <<~GHK
        # language: #{idioma}
        #{palavras[:feature]}: #{historia[:quero].sub(/^Quero\s*/i,'')}
          # #{historia[:como]}
          # #{historia[:quero]}
          # #{historia[:para]}

      GHK

      pt_map  = GHERKIN_MAP_PT_EN
      en_map  = GHERKIN_MAP_EN_PT
      detect  = ALL_KEYS

      historia[:grupos].each do |grupo|
        passos   = grupo[:passos]  || []
        exemplos = grupo[:exemplos] || []
        next if passos.empty?

        # Linha de tags para o grupo
        tag_line = ["@#{grupo[:tipo].downcase}",
                    ("@#{grupo[:tag]}" if grupo[:tag])]
                     .compact.join(' ')

        if exemplos.any?
          # Cenário com Esquema
          conteudo << "    #{tag_line}\n"
          conteudo << "    #{palavras[:esquema]}: #{historia[:quero]}\n"

          # Passos do cenário
          passos.each do |p|
            parts = p.strip.split(' ', 2)
            con_in = detect.find { |k| k.casecmp(parts[0]) == 0 } || parts[0]
            text   = parts[1] || ''
            out_conn = idioma == 'en' ? pt_map[con_in] || con_in : en_map[con_in] || con_in
            conteudo << "      #{out_conn} #{text}\n"
          end

          # Bloco de exemplos original
          conteudo << "\n      #{palavras[:exemplos]}:\n"
          exemplos.select { |l| l.strip.start_with?('|') }.each do |line|
            cleaned = line.strip.gsub(/^"|"$/, '')
            conteudo << "        #{cleaned}\n"
          end
          conteudo << "\n"
        else
          # Cenário simples
          conteudo << "    #{tag_line}\n"
          conteudo << "    #{palavras[:cenario]}: #{grupo[:tipo].capitalize}\n"
          passos.each do |p|
            parts = p.strip.split(' ', 2)
            con_in = detect.find { |k| k.casecmp(parts[0]) == 0 } || parts[0]
            text   = parts[1] || ''
            out_conn = idioma == 'en' ? pt_map[con_in] || con_in : en_map[con_in] || con_in
            conteudo << "      #{out_conn} #{text}\n"
          end
          conteudo << "\n"
        end
      end

      [caminho, conteudo]
    end

    # Salva o conteúdo gerado em arquivo .feature no disco
    #
    # @param caminho [String] Caminho completo para salvar o arquivo
    # @param conteudo [String] Conteúdo do arquivo .feature
    # @return [nil]
    def self.salvar_feature(caminho, conteudo)
      FileUtils.mkdir_p(File.dirname(caminho))
      File.write(caminho, conteudo)
      puts "✅ Arquivo .feature gerado: #{caminho}"
    end
  end
end
