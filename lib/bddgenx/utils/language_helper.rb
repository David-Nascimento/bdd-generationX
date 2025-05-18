module Bddgenx
  module Utils
    # Palavras-chave do Gherkin em Português
    GHERKIN_KEYS_PT = %w[Dado Quando Então E Mas].freeze

    # Palavras-chave do Gherkin em Inglês
    GHERKIN_KEYS_EN = %w[Given When Then And But].freeze

    # Mapeamento PT → EN
    GHERKIN_MAP_PT_EN = GHERKIN_KEYS_PT.zip(GHERKIN_KEYS_EN).to_h

    # Mapeamento EN → PT
    GHERKIN_MAP_EN_PT = GHERKIN_KEYS_EN.zip(GHERKIN_KEYS_PT).to_h

    # Todas as palavras-chave reconhecidas
    ALL_KEYS = GHERKIN_KEYS_PT + GHERKIN_KEYS_EN

    ##
    # Extrai o idioma do arquivo .txt, a partir da linha "# language:".
    # @param txt_file [String] Caminho do arquivo .txt
    # @return [String] O idioma extraído ou 'pt' como padrão
    def self.obter_idioma_do_arquivo(caminho_arquivo)
      return 'pt' unless File.exist?(caminho_arquivo)

      File.foreach(caminho_arquivo) do |linha|
        if linha =~ /^#\s*language:\s*(\w{2})/i
          return $1.downcase
        end
      end

      'pt' # idioma padrão caso não encontre
    end

    ##
    # Detecta o idioma a partir de um texto (como conteúdo de arquivo ou string).
    # @param texto [String] O texto onde o idioma será detectado
    # @return [String] O idioma detectado ('pt' por padrão)
    def self.detecta_idioma_de_texto(texto)
      if texto =~ /^#\s*language:\s*(\w{2})/i
        return $1.downcase
      end
      'pt' # Idioma padrão se o idioma não for detectado
    end
  end
end
