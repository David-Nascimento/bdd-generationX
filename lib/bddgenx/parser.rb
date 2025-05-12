module Bddgenx
  TIPOS_BLOCOS = %w[
    CONTEXT SUCCESS FAILURE ERROR EXCEPTION
    VALIDATION PERMISSION EDGE_CASE PERFORMANCE
    EXAMPLES REGRA RULE
  ].freeze
  class Parser
    def self.ler_historia(caminho_arquivo)
      linhas = File.readlines(caminho_arquivo, encoding: 'utf-8').map(&:strip).reject(&:empty?)

      # Detecta idioma
      idioma = linhas.first.downcase.include?('# lang: en') ? 'en' : 'pt'
      linhas.shift if linhas.first.downcase.start_with?('#')

      # Ignora linhas que sejam blocos ou comentários até encontrar Como/Quero/Para
      cabecalho = []
      until linhas.empty?
        linha = linhas.shift
        break if linha.start_with?("Como", "As")  # início da história em pt ou en
      end
      como = linha
      quero = linhas.shift
      para = linhas.shift

      historia = {
        como: como,
        quero: quero,
        para: para,
        blocos: Hash.new { |h, k| h[k] = [] },
        regras: [],
        arquivo_origem: caminho_arquivo,
        idioma: idioma
      }

      tipo_atual = nil

      linhas.each do |linha|
        if linha.match?(/^\[(#{TIPOS_BLOCOS.join('|')})\]$/)
          tipo_atual = linha.gsub(/[\[\]]/, '')
          next
        end

        if %w[REGRA RULE].include?(tipo_atual)
          historia[:regras] << linha
        else
          historia[:blocos][tipo_atual] << linha if tipo_atual
        end
      end

      historia
    end
  end
end
