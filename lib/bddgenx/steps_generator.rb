require 'fileutils'

module StepsGenerator
  PADROES = {
    'pt' => %w[Dado Quando Então E],
    'en' => %w[Given When Then And]
  }

  TIPOS_BLOCOS = %w[
    CONTEXT SUCCESS FAILURE ERROR EXCEPTION
    VALIDATION PERMISSION EDGE_CASE PERFORMANCE
    EXAMPLES REGRA RULE
  ]

  def self.gerar_passos(historia, nome_arquivo_feature)
    idioma = historia[:idioma] || 'pt'
    conectores = PADROES[idioma]
    passos_gerados = []

    # Detectar parâmetros e tipos a partir do bloco EXAMPLES
    exemplos = extrair_exemplos(historia[:blocos]["EXAMPLES"])

    TIPOS_BLOCOS.each do |tipo|
      blocos = tipo == "REGRA" || tipo == "RULE" ? historia[:regras] : historia[:blocos][tipo]
      next unless blocos.is_a?(Array)

      is_outline = tipo == "SUCCESS" && historia[:blocos]["EXAMPLES"]&.any?

      blocos.each do |linha|
        conector = conectores.find { |c| linha.strip.start_with?(c) }
        next unless conector

        corpo = linha.strip.sub(/^#{conector}/, '').strip

        # Detecta se é um passo de Scenario Outline (com exemplos)
        is_outline = tipo == "SUCCESS" && historia[:blocos]["EXAMPLES"]&.any?

        # Sanitiza aspas se existirem
        corpo_sanitizado = corpo.gsub(/"(<[^>]+>)"/, '\1')

        if is_outline
          corpo_parametrizado = corpo_sanitizado.gsub(/<([^>]+)>/) do
            nome = $1.strip
            tipo_param = exemplos ? detectar_tipo_param(nome, exemplos) : 'string'
            "{#{tipo_param}}"
          end

          # extrair parâmetros para do |...|
          parametros = corpo.scan(/<([^>]+)>/).flatten.map { |p| p.strip.gsub(' ', '_') }
          param_list = parametros.join(', ')

        else
          corpo_parametrizado = corpo
          parametros = []
          param_list = ""
        end

        passos_gerados << {
          conector: conector,
          raw: corpo,
          param: corpo_parametrizado,
          args: param_list,
          tipo: tipo
        } unless passos_gerados.any? { |p| p[:param] == corpo_parametrizado }
      end
    end


    if passos_gerados.empty?
      puts "⚠️  Nenhum passo detectado em: #{nome_arquivo_feature} (arquivo não gerado)"
      return false
    end

    nome_base = File.basename(nome_arquivo_feature, '.feature')
    caminho = "steps/#{nome_base}_steps.rb"
    FileUtils.mkdir_p(File.dirname(caminho))

    comentario = "# Step definitions para #{File.basename(nome_arquivo_feature)}"
    comentario += idioma == 'en' ? " (English)" : " (Português)"
    conteudo = "#{comentario}\n\n"

    passos_gerados.each do |passo|
    # Extrai nomes dos parâmetros entre < >
    parametros = passo[:raw].scan(/<([^>]+)>/).flatten.map(&:strip)
    param_list = parametros.map { |p| p.gsub(' ', '_') }.join(', ')

    conteudo += <<~STEP
      #{passo[:conector]}('#{passo[:param]}') do#{param_list.empty? ? '' : " |#{param_list}|" }
        pending '#{idioma == 'en' ? 'Implement step' : 'Implementar passo'}: #{passo[:raw]}'
      end

    STEP
    end

    FileUtils.mkdir_p("steps")
    File.write(caminho, conteudo)
    puts "✅ Step definitions gerados: #{caminho}"
    true
  end

  def self.substituir_parametros(texto, exemplos)
    texto.gsub(/<([^>]+)>/) do |_match|
      nome = $1.strip
      tipo = detectar_tipo_param(nome, exemplos)
      "{#{tipo}}"
    end
  end

  def self.detectar_tipo_param(nome_coluna, exemplos)
    return 'string' unless exemplos && exemplos[:cabecalho].include?(nome_coluna)

    idx = exemplos[:cabecalho].index(nome_coluna)
    valores = exemplos[:linhas].map { |l| l[idx] }

    if valores.all? { |v| v.match?(/^\d+$/) }
      'int'
    elsif valores.all? { |v| v.match?(/^\d+\.\d+$/) }
      'float'
    else
      'string'
    end
  end

  def self.extrair_exemplos(bloco)
    return nil unless bloco&.any?

    linhas = bloco.map(&:strip)
    cabecalho = linhas.first.gsub('|', '').split.map(&:strip)
    dados = linhas[1..].map { |linha| linha.gsub('|', '').split.map(&:strip) }

    { cabecalho: cabecalho, linhas: dados }
  end
end


