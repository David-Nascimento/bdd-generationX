# lib/bddgenx/steps_generator.rb
# encoding: utf-8
#
# Classe responsável por gerar automaticamente os arquivos de definição
# de passos do Cucumber a partir de arquivos `.feature`.
# Suporta palavras-chave do Gherkin tanto em Português quanto em Inglês,
# além de identificar parâmetros dinamicamente (strings e números).

module Bddgenx
  class StepsGenerator
    # Palavras-chave Gherkin em Português
    GHERKIN_KEYS_PT = %w[Dado Quando Então E Mas].freeze

    # Palavras-chave Gherkin em Inglês
    GHERKIN_KEYS_EN = %w[Given When Then And But].freeze

    # Conjunto de todas as palavras-chave reconhecidas
    ALL_KEYS = GHERKIN_KEYS_PT + GHERKIN_KEYS_EN

    ##
    # Transforma uma string em camelCase (sem alterar acentuação).
    #
    # @param str [String] A string de entrada
    # @return [String] A string convertida para estilo camelCase
    def self.camelize(str)
      partes = str.strip.split(/[^a-zA-Z0-9]+/)
      partes.map.with_index { |palavra, i| i.zero? ? palavra.downcase : palavra.capitalize }.join
    end

    ##
    # Gera um arquivo de definição de passos do Cucumber com base em um `.feature`.
    # Detecta automaticamente o idioma e converte os passos em métodos com placeholders.
    #
    # @param feature_path [String] Caminho para o arquivo `.feature`
    # @return [Boolean] Retorna true se os steps foram gerados, false se nenhum foi encontrado
    # @raise [ArgumentError] Se o parâmetro não for uma String
    def self.gerar_passos(feature_path)
      raise ArgumentError, I18n.t('errors.invalid_path', path: feature_path.class) unless feature_path.is_a?(String)

      linhas = File.readlines(feature_path)

      # Detecta o idioma a partir da linha `# language:`
      lang = if (m = linhas.find { |l| l =~ /^#\s*language:\s*(\w+)/i })
               m[/^#\s*language:\s*(\w+)/i, 1].downcase
             else
               'pt'
             end

      # Define o locale do I18n conforme idioma detectado
      I18n.locale = lang.to_sym rescue :pt

      pt_para_en = GHERKIN_KEYS_PT.zip(GHERKIN_KEYS_EN).to_h
      en_para_pt = GHERKIN_KEYS_EN.zip(GHERKIN_KEYS_PT).to_h

      # Seleciona apenas as linhas que representam passos
      linhas_passos = linhas.map(&:strip).select do |linha|
        ALL_KEYS.any? { |chave| linha.start_with?(chave + ' ') }
      end

      return false if linhas_passos.empty?

      # Cria diretório `steps` no mesmo nível do `.feature`
      dir_saida = File.join(File.dirname(feature_path), 'steps')
      FileUtils.mkdir_p(dir_saida)

      arquivo_saida = File.join(dir_saida, "#{File.basename(feature_path, '.feature')}_steps.rb")

      # Cabeçalho do arquivo gerado
      conteudo = +"# encoding: utf-8\n"
      conteudo << "# #{I18n.t('steps.header', file: File.basename(feature_path))}\n\n"

      passos_unicos = Set.new

      linhas_passos.each do |linha|
        palavra_original, restante = linha.split(' ', 2)

        # Tradução da palavra-chave inicial
        chave = case lang
                when 'en' then pt_para_en[palavra_original] || palavra_original
                else           en_para_pt[palavra_original] || palavra_original
                end

        texto_bruto = restante.dup
        scanner = ::StringScanner.new(restante)
        padrao = ''
        tokens = []

        # Analisa e parametriza variáveis
        until scanner.eos?
          if scanner.check(/"<([^>]+)>"/)
            scanner.scan(/"<([^>]+)>"/)
            tokens << scanner[1]
            padrao << '{string}'
          elsif scanner.check(/<([^>]+)>/)
            scanner.scan(/<([^>]+)>/)
            tokens << scanner[1]
            padrao << '{int}'
          elsif scanner.check(/"([^"]+)"/)
            scanner.scan(/"([^"]+)"/)
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

        # Evita duplicatas de métodos
        next if passos_unicos.include?(padrao_seguro)
        passos_unicos << padrao_seguro

        # Monta assinatura do step
        assinatura = "#{chave}(\"#{padrao_seguro}\")"
        if tokens.any?
          argumentos = tokens.each_index.map { |i| "arg#{i+1}" }.join(', ')
          assinatura << " do |#{argumentos}|"
        else
          assinatura << ' do'
        end

        conteudo << "#{assinatura}\n"
        conteudo << "  pending '#{I18n.t('steps.pending', text: texto_bruto)}'\n"
        conteudo << "end\n\n"
      end

      # Escreve o arquivo final
      File.write(arquivo_saida, conteudo)
      puts I18n.t('steps.generated', path: arquivo_saida)
      true
    end
  end
end
