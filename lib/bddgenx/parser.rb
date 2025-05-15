module Bddgenx
  # Tipos de blocos GUARDADOS, incluindo português EXEMPLO/EXEMPLOS
  TIPOS_BLOCOS = %w[
    CONTEXT SUCCESS FAILURE ERROR EXCEPTION
    VALIDATION PERMISSION EDGE_CASE PERFORMANCE
    EXEMPLO EXEMPLOS RULE
  ].freeze

  class Parser
    # Lê arquivo de história (.txt) e retorna hash com atributos e grupos
    def self.ler_historia(caminho_arquivo)
      # Lê todas as linhas, mantendo vazias
      linhas = File.readlines(caminho_arquivo, encoding: 'utf-8').map(&:rstrip)

      # Detecta idioma: aceita "# lang: en" ou "# language: en"
      idioma = 'pt'
      if linhas.first =~ /^#\s*lang(?:uage)?\s*:\s*(\w+)/i
        idioma = Regexp.last_match(1).downcase
        linhas.shift
      end

      # Extrai Cabeçalho Como/Quero/Para
      como, quero, para = nil, nil, nil
      linhas.reject! do |l|
        if l =~ /^\s*(?:como|eu como|as a)/i && como.nil?
          como = l
          true
        elsif l =~ /^\s*(?:quero|eu quero|quero que)/i && quero.nil?
          quero = l
          true
        elsif l =~ /^\s*(?:para|para eu|para que)/i && para.nil?
          para = l
          true
        else
          false
        end
      end

      historia = { como: como, quero: quero, para: para, idioma: idioma, grupos: [] }
      exemplos_mode = false

      linhas.each do |linha|
        # Início de bloco de exemplos: [EXEMPLO] ou [EXEMPLOS] ou [EXAMPLES]
        if linha =~ /^\[(?:EXEMPLO|EXEMPLOS|EXAMPLES)\](?:@(\w+))?$/i
          exemplos_mode = true
          # inicia array se for o primeiro exemplo
          historia[:grupos].last[:exemplos] = []
          next
        end

        # Início de bloco de tipo (SUCCESS, FAILURE, REGRA etc.)
        if linha =~ /^\[(#{TIPOS_BLOCOS.join('|')})\](?:@(\w+))?$/i
          exemplos_mode = false
          tipo = Regexp.last_match(1).upcase
          tag  = Regexp.last_match(2)
          historia[:grupos] << { tipo: tipo, tag: tag, passos: [], exemplos: [] }
          next
        end

        # Atribui linhas ao último grupo
        next if historia[:grupos].empty?
        bloco = historia[:grupos].last
        if exemplos_mode
          bloco[:exemplos] << linha
        else
          bloco[:passos]   << linha
        end
      end

      historia
    end
  end
end
