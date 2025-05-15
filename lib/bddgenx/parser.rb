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

      # Detecta idioma: aceita "# lang: en" ou "# language: en"
      primeira = linhas.first.to_s.downcase
      if primeira =~ /^#\s*lang(?:uage)?\s*:\s*en/
        idioma = 'en'
        linhas.shift
      else
        idioma = 'pt'
        # se quiser suportar "# language: pt" também:
        linhas.shift if primeira =~ /^#\s*lang(?:uage)?\s*:\s*pt/
      end

      # Cabeçalho Gherkin (case-insensitive): Como, Eu Como ou As a
      como = nil
      linhas.each_with_index do |l, i|
        if l =~ /^\s*(?:como|eu como|as a)\b/i || l =~ /^\s*(?:COMO|EU COMO|AS A)\b/i
          como = l
          linhas = linhas[(i+1)..]
          break
        end
      end

      # 'Quero' ou 'Eu Quero'
      quero = nil
      linhas.each_with_index do |l, i|
        if l =~ /^\s*(?:quero|eu quero|quero que)\b/i || l =~ /^\s*(?:QUERO|EU QUERO|QUERO QUE)\b/i
          quero = l
          linhas = linhas[(i+1)..]
          break
        end
      end

      # 'Para', 'Para Eu' ou 'Para Que'
      para = nil
      linhas.each_with_index do |l, i|
        if l =~ /^\s*(?:para|para eu|para que)\b/i || l =~ /^\s*(?:PRA|PARA EU|PARA QUE)\b/i
          para = l
          linhas = linhas[(i+1)..]
          break
        end
      end

      historia = { como: como, quero: quero, para: para, idioma: idioma, grupos: [] }
      exemplos_mode = false

      linhas.each do |linha|
        # Início de bloco de exemplos
        if linha =~ /^\[EXAMPLES\](?:@(\w+))?$/i
          exemplos_mode = true
          historia[:grupos].last[:exemplos] = []
          next
        end

        # Início de bloco de tipo (SUCCESS, FAILURE etc.)
        if linha =~ /^\[(#{TIPOS_BLOCOS.join('|')})\](?:@(\w+))?$/i
          exemplos_mode = false
          tipo = $1.upcase
          tag  = $2
          historia[:grupos] << { tipo: tipo, tag: tag, passos: [], exemplos: [] }
          next
        end

        # Atribui linhas ao último grupo existente
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
