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
      next unless passos&.any?

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
      exemplos_bruto = historia[:blocos]["EXAMPLES"]
      cabecalho = exemplos_bruto.first.gsub('|', '').split.map(&:strip)
      linhas = exemplos_bruto[1..]

      # Procura qualquer cenário que use parâmetros
      tipo_cenario = historia[:blocos].keys.find { |k| historia[:blocos][k].any? { |l| l.include?('<') } }
      passos_exemplo = tipo_cenario ? historia[:blocos][tipo_cenario].select { |l| l.include?('<') } : []

      if idioma == 'en'
        conteudo += "    Scenario Outline: Generated scenario with data\n"
      else
        conteudo += "    Esquema do Cenário: Gerado a partir de dados de exemplo\n"
      end

      passos_exemplo.each do |passo|
        conteudo += "      #{passo}\n"
      end

      conteudo += "\n"
      conteudo += idioma == 'en' ? "      Examples:\n" : "      Exemplos:\n"
      conteudo += "        #{exemplos_bruto.first}\n"
      linhas.each { |linha| conteudo += "        #{linha}\n" }
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
end
