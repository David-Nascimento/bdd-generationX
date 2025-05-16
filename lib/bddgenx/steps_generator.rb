# lib/bddgenx/steps_generator.rb
# encoding: utf-8
#
# Este arquivo define a classe StepsGenerator, responsável por gerar
# definições de passos do Cucumber a partir de arquivos .feature.
# Suporta palavras-chave Gherkin em Português e Inglês e parametriza
# strings e números conforme necessário.

require 'fileutils'
require 'strscan'  # Para uso de StringScanner

module Bddgenx
  # Gera arquivos de definições de passos Ruby para Cucumber
  # com base em arquivos .feature.
  class StepsGenerator
    # Palavras-chave Gherkin em Português usadas em arquivos de feature
    # @return [Array<String>]
    GHERKIN_KEYS_PT = %w[Dado Quando Então E Mas].freeze

    # Palavras-chave Gherkin em Inglês usadas em arquivos de feature
    # @return [Array<String>]
    GHERKIN_KEYS_EN = %w[Given When Then And But].freeze

    # Conjunto de todas as palavras-chave suportadas (PT + EN)
    # @return [Array<String>]
    ALL_KEYS = GHERKIN_KEYS_PT + GHERKIN_KEYS_EN

    # Converte uma string para camelCase, útil para nomes de argumentos
    #
    # @param [String] str Texto de entrada a ser convertido
    # @return [String] Versão em camelCase do texto
    def self.camelize(str)
      partes = str.strip.split(/[^a-zA-Z0-9]+/)
      partes.map.with_index { |palavra, i| i.zero? ? palavra.downcase : palavra.capitalize }.join
    end

    # Gera definições de passos a partir de um arquivo .feature
    #
    # @param [String] feature_path Caminho para o arquivo .feature
    # @raise [ArgumentError] Se feature_path não for String
    # @return [Boolean] Retorna true se passos foram gerados, false se não houver passos
    def self.gerar_passos(feature_path)
      # Valida tipo de entrada
      unless feature_path.is_a?(String)
        raise ArgumentError, "Caminho esperado como String, recebeu #{feature_path.class}"
      end

      linhas = File.readlines(feature_path)

      # Detecta idioma no cabeçalho: "# language: pt" ou "# language: en"
      lang = if (m = linhas.find { |l| l =~ /^#\s*language:\s*(\w+)/i })
               m[/^#\s*language:\s*(\w+)/i, 1].downcase
             else
               'pt'
             end

      # Mapas de tradução entre PT e EN
      pt_para_en = GHERKIN_KEYS_PT.zip(GHERKIN_KEYS_EN).to_h
      en_para_pt = GHERKIN_KEYS_EN.zip(GHERKIN_KEYS_PT).to_h

      # Seleciona linhas que começam com palavras-chave Gherkin
      linhas_passos = linhas.map(&:strip).select do |linha|
        ALL_KEYS.any? { |chave| linha.start_with?(chave + ' ') }
      end

      # Se não encontrar passos, retorna false
      return false if linhas_passos.empty?

      # Cria diretório e arquivo de saída
      dir_saida = File.join(File.dirname(feature_path), 'steps')
      FileUtils.mkdir_p(dir_saida)
      arquivo_saida = File.join(dir_saida, "#{File.basename(feature_path, '.feature')}_steps.rb")

      # Cabeçalho do arquivo gerado
      conteudo = +"# encoding: utf-8\n"
      conteudo << "# Definições de passos geradas automaticamente para #{File.basename(feature_path)}\n\n"

      linhas_passos.each do |linha|
        palavra_original, restante = linha.split(' ', 2)

        # Define palavra-chave no idioma de saída
        chave = case lang
                when 'en' then pt_para_en[palavra_original] || palavra_original
                else         en_para_pt[palavra_original] || palavra_original
                end

        texto_bruto = restante.dup
        scanner = ::StringScanner.new(restante)
        padrao = ''
        tokens = []

        until scanner.eos?
          if scanner.check(/"<([^>]+)>"/)
            scanner.scan(/"<([^>]+)>"/)
            tokens << scanner[1]
            padrao << '{string}'
          elsif scanner.check(/<([^>]+)>/)
            scanner.scan(/<([^>]+)>/)
            tokens << scanner[1]
            padrao << '{int}'
          elsif scanner.check(/"([^"<>]+)"/)
            scanner.scan(/"([^"<>]+)"/)
            tokens << scanner[1]
            padrao << '{string}'
          elsif scanner.check(/\d+(?:\.\d+)?/)
            numero = scanner.scan(/\d+(?:\.\d+)?/)
            tokens << numero
            padrao << '{int}'
          else
            padrao << scanner.getch
          end
        end

        # Escapa aspas no padrão
        padrao_seguro = padrao.gsub('"', '\\"')
        assinatura = "#{chave}(\"#{padrao_seguro}\")"

        # Adiciona parâmetros se existirem tokens
        if tokens.any?
          argumentos = tokens.each_index.map { |i| "arg#{i+1}" }.join(', ')
          assinatura << " do |#{argumentos}|"
        else
          assinatura << ' do'
        end

        conteudo << "#{assinatura}\n"
        conteudo << "  pending 'Implementar passo: #{texto_bruto}'\n"
        conteudo << "end\n\n"
      end

      # Escreve arquivo de saída
      File.write(arquivo_saida, conteudo)
      puts "✅ Steps gerados: #{arquivo_saida}"
      true
    end
  end
end
