# lib/bddgenx/steps_generator.rb
# encoding: utf-8
#
# Este arquivo define a classe StepsGenerator, responsável por gerar
# definições de passos do Cucumber a partir de arquivos .feature.
# Suporta palavras-chave Gherkin em Português e Inglês e parametriza
# strings e números conforme necessário.

module Bddgenx
  class StepsGenerator
    # Palavras-chave Gherkin em Português
    GHERKIN_KEYS_PT = %w[Dado Quando Então E Mas].freeze

    # Palavras-chave Gherkin em Inglês
    GHERKIN_KEYS_EN = %w[Given When Then And But].freeze

    # Conjunto de todas as palavras-chave suportadas
    ALL_KEYS = GHERKIN_KEYS_PT + GHERKIN_KEYS_EN

    ##
    # Transforma uma string em estilo camelCase.
    #
    # @param str [String] A string a ser transformada.
    # @return [String] A string convertida para camelCase.
    #
    def self.camelize(str)
      partes = str.strip.split(/[^a-zA-Z0-9]+/)
      partes.map.with_index { |palavra, i| i.zero? ? palavra.downcase : palavra.capitalize }.join
    end

    ##
    # Gera arquivos de passos do Cucumber a partir de um arquivo .feature.
    #
    # O método lê o arquivo, detecta o idioma, extrai os passos,
    # parametriza as variáveis (números e strings), e escreve os métodos
    # em um novo arquivo no diretório `steps/`.
    #
    # @param feature_path [String] Caminho para o arquivo .feature.
    # @return [Boolean] Retorna true se os passos forem gerados com sucesso, false se não houver passos.
    # @raise [ArgumentError] Se o caminho fornecido não for uma String.
    #
    def self.gerar_passos(feature_path)
      raise ArgumentError, "Caminho esperado como String, recebeu #{feature_path.class}" unless feature_path.is_a?(String)

      linhas = File.readlines(feature_path)

      # Detecta o idioma com base na diretiva "# language:"
      lang = if (m = linhas.find { |l| l =~ /^#\s*language:\s*(\w+)/i })
               m[/^#\s*language:\s*(\w+)/i, 1].downcase
             else
               'pt'
             end

      pt_para_en = GHERKIN_KEYS_PT.zip(GHERKIN_KEYS_EN).to_h
      en_para_pt = GHERKIN_KEYS_EN.zip(GHERKIN_KEYS_PT).to_h

      # Seleciona apenas linhas que começam com palavras-chave Gherkin
      linhas_passos = linhas.map(&:strip).select do |linha|
        ALL_KEYS.any? { |chave| linha.start_with?(chave + ' ') }
      end

      return false if linhas_passos.empty?

      dir_saida = File.join(File.dirname(feature_path), 'steps')
      FileUtils.mkdir_p(dir_saida)
      arquivo_saida = File.join(dir_saida, "#{File.basename(feature_path, '.feature')}_steps.rb")

      conteudo = +"# encoding: utf-8\n"
      conteudo << "# Definições de passos geradas automaticamente para #{File.basename(feature_path)}\n\n"

      passos_unicos = Set.new

      linhas_passos.each do |linha|
        palavra_original, restante = linha.split(' ', 2)

        # Tradução de palavras-chave se necessário
        chave = case lang
                when 'en' then pt_para_en[palavra_original] || palavra_original
                else           en_para_pt[palavra_original] || palavra_original
                end

        texto_bruto = restante.dup
        scanner = ::StringScanner.new(restante)
        padrao = ''
        tokens = []

        # Analisa e parametriza o conteúdo dos passos
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

        padrao_seguro = padrao.gsub('"', '\\"')

        # Impede criação de métodos duplicados
        next if passos_unicos.include?(padrao_seguro)

        passos_unicos << padrao_seguro

        assinatura = "#{chave}(\"#{padrao_seguro}\")"
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

      File.write(arquivo_saida, conteudo)
      puts "✅ Steps gerados: #{arquivo_saida}"
      true
    end
  end
end
