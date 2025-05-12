module Bddgenx
  TIPOS_BLOCOS = %w[
    CONTEXT SUCCESS FAILURE ERROR EXCEPTION
    VALIDATION PERMISSION EDGE_CASE PERFORMANCE
    EXAMPLES REGRA RULE
  ].freeze

  class Parser
    def self.ler_historia(caminho_arquivo)
      linhas = File.readlines(caminho_arquivo, encoding: 'utf-8')
                   .map(&:strip)
                   .reject(&:empty?)

      # idioma
      idioma = linhas.first.downcase.include?('# lang: en') ? 'en' : 'pt'
      linhas.shift if linhas.first.downcase.start_with?('# lang:')

      # cabeçalho Gherkin: Como / Quero / Para
      until linhas.empty?
        linha = linhas.shift
        break if linha =~ /^(Como |As a )/
      end
      como  = linha
      quero = linhas.shift
      para  = linhas.shift

      historia = {
        como:     como,
        quero:    quero,
        para:     para,
        idioma:   idioma,
        grupos:   []   # cada bloco ([TIPO]@tag) será um grupo
      }

      exemplos_mode = false
      tipo_atual    = nil
      tag_atual     = nil

      linhas.each do |linha|
        # início de bloco EXAMPLES: modo exemplos para último grupo
        if linha =~ /^\[EXAMPLES\](?:@(\w+))?$/
          exemplos_mode = true
          raise "Formato inválido: EXAMPLES sem bloco anterior" if historia[:grupos].empty?
          historia[:grupos].last[:exemplos] = []
          next
        end

        # início de um novo bloco (exceto EXAMPLES)
        if linha =~ /^\[(#{TIPOS_BLOCOS.join('|')})\](?:@(\w+))?$/
          exemplos_mode = false
          tipo_atual = $1
          tag_atual  = $2
          historia[:grupos] << {
            tipo:     tipo_atual,
            tag:      tag_atual,
            passos:   [],
            exemplos: []
          }
          next
        end

        # atribuir linhas ao bloco atual
        next if historia[:grupos].empty?
        atual = historia[:grupos].last

        if exemplos_mode
          atual[:exemplos] << linha
        else
          atual[:passos]   << linha
        end
      end

      historia
    end
  end
end
