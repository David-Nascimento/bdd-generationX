require 'fileutils'

module Generator
  TIPOS_ISTQB = {
    "SUCCESS"     => "Teste Positivo",
    "FAILURE"     => "Teste Negativo",
    "ERROR"       => "Teste de Erro",
    "EXCEPTION"   => "Teste de Exceção",
    "VALIDATION"  => "Teste de Validação",
    "PERMISSION"  => "Teste de Permissão",
    "EDGE_CASE"   => "Teste de Limite",
    "PERFORMANCE" => "Teste de Desempenho"
  }

  TIPOS_CENARIO = %w[
    SUCCESS FAILURE ERROR EXCEPTION
    VALIDATION PERMISSION EDGE_CASE PERFORMANCE
  ]


  def self.gerar_feature(historia)
    idioma = historia[:idioma] || 'pt'

    # Define os conectores de acordo com o idioma   
    palavras = {
      contexto: idioma == 'en' ? 'Background' : 'Contexto',
      cenario: idioma == 'en' ? 'Scenario' : 'Cenário',
      esquema: idioma == 'en' ? 'Scenario Outline' : 'Esquema do Cenário',
      exemplos: idioma == 'en' ? 'Examples' : 'Exemplos',
      regra: idioma == 'en' ? 'Rule' : 'Regra'
    }

    nome_base = historia[:quero].gsub(/[^a-zA-Z0-9]/, '_').downcase
    caminho = "features/#{nome_base}.feature"

    conteudo = <<~HEADER
      # language: #{idioma}
      Funcionalidade: #{historia[:quero].sub(/^Quero/, '').strip}

        #{historia[:como]}
        #{historia[:quero]}
        #{historia[:para]}

    HEADER

    # Regras
    if historia[:regras]&.any?
      conteudo += "    #{palavras[:regra]}: #{historia[:regras].first}\n"
      historia[:regras][1..].each do |linha|
        conteudo += "      #{linha}\n"
      end
      conteudo += "\n"
    end


    # Contexto
    if historia[:blocos]["CONTEXT"]&.any?
      conteudo += "    #{palavras[:contexto]}:\n"
      historia[:blocos]["CONTEXT"].each { |p| conteudo += "      #{p}\n" }
      conteudo += "\n"
    end

    # Cenários
    TIPOS_CENARIO.each do |tipo|
      passos = historia[:blocos][tipo]
      passos = passos&.reject { |l| l.strip.empty? } || []
      next if passos.empty?

      # Ignora geração duplicada se for um SUCCESS parametrizado com EXAMPLES
      if tipo == "SUCCESS" && historia[:blocos]["EXAMPLES"]&.any?
        possui_parametros = passos.any? { |p| p.include?('<') }
        next if possui_parametros
      end

      nome_teste = TIPOS_ISTQB[tipo] || palavras[:cenario]
      contexto = passos.first&.gsub(/^(Dado que|Given|Quando|When|Então|Then|E|And)/, '')&.strip || "Condição"
      resultado = passos.last&.gsub(/^(Então|Then|E|And)/, '')&.strip || "Resultado"
      nome_cenario = "#{nome_teste} - #{contexto} - #{resultado}"

      conteudo += "    @#{tipo.downcase}\n"
      conteudo += "    #{palavras[:cenario]}: #{nome_cenario}\n"
      passos.each { |p| conteudo += "      #{p}\n" }
      conteudo += "\n"
    end

    # Esquema do Cenário com Exemplos
    if historia[:blocos]["EXAMPLES"]&.any?
      exemplo_bruto = historia[:blocos]["EXAMPLES"]
      grupos = dividir_examples(exemplo_bruto)

      grupos.each_with_index do |tabela, i|
        cabecalho = tabela.first.gsub('|', '').split.map(&:strip)
        linhas = tabela[1..].map { |linha| linha.split('|').reject(&:empty?).map(&:strip) }

        exemplos = { cabecalho: cabecalho, linhas: linhas }

        passos_outline = historia[:blocos]["SUCCESS"].select do |linha|
          cabecalho.any? { |coluna| linha.include?("<#{coluna}>") }
        end

        next if passos_outline.empty?

        conteudo += "\n"
        conteudo += idioma == 'en' ? "    Scenario Outline: Example #{i + 1}\n" : "    Esquema do Cenário: Exemplo #{i + 1}\n"

        passos_outline.each do |passo|
          conteudo += "      #{passo}\n"
        end

        conteudo += "\n"
        conteudo += idioma == 'en' ? "      Examples:\n" : "      Exemplos:\n"
        conteudo += "        #{tabela.first}\n"
        tabela[1..].each { |linha| conteudo += "        #{linha}\n" }
      end
    end

    [caminho, conteudo]
  end

  # Salva o arquivo .feature gerado
  # Retorna true se o arquivo foi salvo com sucesso, false caso contrário
  def self.salvar_feature(caminho, conteudo)
    if conteudo.strip.empty?
      puts "⚠️  Nenhum conteúdo gerado para: #{caminho} (ignorado)"
      return false
    end

    File.write(caminho, conteudo)
    puts "✅ Arquivo .feature gerado: #{caminho}"
    true
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

end
