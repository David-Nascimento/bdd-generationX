# lib/bddgenx/generator.rb
# encoding: utf-8
#
# Classe responsável pela geração de arquivos `.feature` no formato Gherkin
# a partir de arquivos de entrada de histórias ou estruturas hash.
# Suporta palavras-chave Gherkin em Português e Inglês, além de integração com IA
# (ChatGPT ou Gemini) para geração automática de cenários.

module Bddgenx
  class Generator
    # Palavras-chave do Gherkin em Português
    GHERKIN_KEYS_PT = %w[Dado Quando Então E Mas].freeze

    # Palavras-chave do Gherkin em Inglês
    GHERKIN_KEYS_EN = %w[Given When Then And But].freeze

    # Mapeamento PT → EN
    GHERKIN_MAP_PT_EN = GHERKIN_KEYS_PT.zip(GHERKIN_KEYS_EN).to_h

    # Mapeamento EN → PT
    GHERKIN_MAP_EN_PT = GHERKIN_KEYS_EN.zip(GHERKIN_KEYS_PT).to_h

    # Todas as palavras-chave reconhecidas pelos parsers
    ALL_KEYS = GHERKIN_KEYS_PT + GHERKIN_KEYS_EN

    ##
    # Função para extrair o idioma do arquivo .txt
    # @param txt_file [String] Caminho do arquivo .txt
    # @return [String] O idioma extraído ou 'pt' como padrão
    def self.obter_idioma_do_arquivo(txt_file)
      idioma = nil
      File.foreach(txt_file) do |line|
        if line.strip.start_with?('# language:')
          idioma = line.strip.split(':').last.strip.downcase
          break
        end
      end
      idioma || 'pt'  # Retorna 'pt' como padrão caso o idioma não seja encontrado
    end

    ##
    # Gera o conteúdo de um arquivo `.feature` baseado na história fornecida.
    # Pode operar em três modos:
    # - :static (sem IA)
    # - :chatgpt (usando OpenAI)
    # - :gemini (usando Google Gemini)
    #
    # @param input [String, Hash] Caminho para um `.txt` ou estrutura de história já processada
    # @param override_path [String, nil] Caminho alternativo de saída
    # @return [Array<String, String>] Caminho e conteúdo do `.feature`
    def self.gerar_feature(input, override_path = nil)
      modo = ENV['BDD_MODE']&.to_sym || :static

      if input.is_a?(String) && input.end_with?('.txt') && [:gemini, :chatgpt].include?(modo)
        # Geração com IA
        raw_txt = File.read(input)
        historia = {
          idioma: 'pt', # Idioma inicial, caso não seja detectado no arquivo
          quero: File.basename(input, '.txt').tr('_', ' ').capitalize,
          como: '',
          para: '',
          grupos: []
        }

        texto_gerado = if modo == :gemini
                         GeminiCliente.gerar_cenarios(raw_txt)
                       else
                         ChatGPTCliente.gerar_cenarios(raw_txt)
                       end

        historia[:grupos] << {
          tipo: 'gerado',
          tag: 'ia',
          passos: GherkinCleaner.limpar(texto_gerado).lines.map(&:strip).reject(&:empty?)
        }
      else
        # Geração estática
        historia = input.is_a?(String) ? Parser.ler_historia(input) : input
      end

      # Atribui o idioma corretamente antes da geração do conteúdo
      idioma = historia[:idioma] || obter_idioma_do_arquivo(input) # Uso da função para pegar o idioma do arquivo
      cont = 1

      # Cria nome-base do arquivo .feature
      nome_base = historia[:quero]
                    .gsub(/[^a-z0-9]/i, '_')
                    .downcase
                    .split('_')
                    .reject(&:empty?)
                    .first(5)
                    .join('_')

      caminho = override_path || "features/#{nome_base}.feature"

      # Palavras-chave localizadas
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

      # Controle para não repetir passos
      passos_unicos = Set.new
      pt_map = GHERKIN_MAP_PT_EN
      en_map = GHERKIN_MAP_EN_PT
      detect = ALL_KEYS

      historia[:grupos].each do |grupo|
        passos   = grupo[:passos]   || []
        exemplos = grupo[:exemplos] || []
        next if passos.empty?

        tag_line = ["@#{grupo[:tipo].downcase}", ("@#{grupo[:tag]}" if grupo[:tag])].compact.join(' ')
        conteudo << "    #{tag_line}\n"

        if exemplos.any?
          conteudo << "    #{palavras[:esquema]}: Exemplo #{cont}\n"
          cont += 1
        else
          conteudo << "    #{palavras[:cenario]}: #{grupo[:tipo].capitalize}\n"
        end

        passos.each do |p|
          parts = p.strip.split(' ', 2)
          con_in = detect.find { |k| k.casecmp(parts[0]) == 0 } || parts[0]
          text = parts[1] || ''
          out_conn = idioma == 'en' ? pt_map[con_in] || con_in : en_map[con_in] || con_in
          linha_step = "      #{out_conn} #{text}"

          next if passos_unicos.include?(linha_step)

          passos_unicos << linha_step
          conteudo << "#{linha_step}\n"
        end

        if exemplos.any?
          conteudo << "\n      #{palavras[:exemplos]}:\n"
          exemplos.select { |l| l.strip.start_with?('|') }.each do |line|
            cleaned = line.strip.gsub(/^"|"$/, '')
            conteudo << "        #{cleaned}\n"
          end
        end

        conteudo << "\n"
      end

      [caminho, conteudo]
    end

    ##
    # Retorna o caminho padrão do arquivo `.feature` baseado no nome do `.txt`.
    #
    # @param arquivo_txt [String] Caminho do arquivo .txt
    # @return [String] Caminho final da feature gerada
    def self.path_para_feature(arquivo_txt)
      nome = File.basename(arquivo_txt, '.txt')
      File.join('features', "#{nome}.feature")
    end

    ##
    # Salva o conteúdo do arquivo `.feature` no disco.
    # Cria diretórios intermediários, se necessário.
    #
    # @param caminho [String] Caminho completo do arquivo
    # @param conteudo [String] Conteúdo da feature a ser salva
    # @return [void]
    def self.salvar_feature(caminho, conteudo)
      FileUtils.mkdir_p(File.dirname(caminho))
      File.write(caminho, conteudo)
      puts I18n.t('messages.feature_created', caminho: caminho)
    end
  end
end


