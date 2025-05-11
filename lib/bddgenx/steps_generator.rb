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

    grupos_examples = dividir_examples(historia[:blocos]["EXAMPLES"]) if historia[:blocos]["EXAMPLES"]&.any?

    TIPOS_BLOCOS.each do |tipo|
      blocos = tipo == "REGRA" || tipo == "RULE" ? historia[:regras] : historia[:blocos][tipo]
      next unless blocos.is_a?(Array)

      passos = blocos.dup

      passos.each do |linha|
        conector = conectores.find { |c| linha.strip.start_with?(c) }
        next unless conector

        corpo = linha.strip.sub(/^#{conector}/, '').strip

        # Sanitiza aspas duplas envolvendo parâmetros, ex: "<nome>" -> <nome>
        corpo_sanitizado = corpo.gsub(/"(<[^>]+>)"/, '\1')

        # Verifica se este passo pertence a algum grupo de exemplos
        grupo_exemplo_compat = nil

        if tipo == "SUCCESS" && grupos_examples
          grupos_examples.each do |grupo|
            cabecalho = grupo.first.gsub('|', '').split.map(&:strip)
            if cabecalho.any? { |col| corpo.include?("<#{col}>") }
              grupo_exemplo_compat = {
                cabecalho: cabecalho,
                linhas: grupo[1..].map { |linha| linha.split('|').reject(&:empty?).map(&:strip) }
              }
              break
            end
          end
        end

        if grupo_exemplo_compat
          # Substitui cada <param> por {tipo} dinamicamente
          corpo_parametrizado = corpo_sanitizado.gsub(/<([^>]+)>/) do
            nome = $1.strip
            tipo_param = detectar_tipo_param(nome, grupo_exemplo_compat)
            "{#{tipo_param}}"
          end

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
      conteudo += <<~STEP
      #{passo[:conector]}('#{passo[:param]}') do#{passo[:args].empty? ? '' : " |#{passo[:args]}|"}
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
    valores = exemplos[:linhas].map { |linha| linha[idx].to_s.strip }

    return 'boolean' if valores.all? { |v| %w[true false].include?(v.downcase) }
    return 'int'     if valores.all? { |v| v.match?(/^\d+$/) }
    return 'float'   if valores.all? { |v| v.match?(/^\d+\.\d+$/) }

    'string'
  end

  def self.dividir_examples(tabela_bruta)
    grupos = []
    grupo_atual = []

    tabela_bruta.each do |linha|
      if linha.strip =~ /^\|\s*[\w\s]+\|/ && grupo_atual.any? && linha.strip == linha.strip.squeeze(" ")
        grupos << grupo_atual
        grupo_atual = [linha]
      else
        grupo_atual << linha
      end
    end

    grupos << grupo_atual unless grupo_atual.empty?
    grupos
  end


  def self.extrair_exemplos(bloco)
    return nil unless bloco&.any?

    linhas = bloco.map(&:strip)
    cabecalho = linhas.first.gsub('|', '').split.map(&:strip)
    dados = linhas[1..].map { |linha| linha.gsub('|', '').split.map(&:strip) }

    { cabecalho: cabecalho, linhas: dados }
  end
end


