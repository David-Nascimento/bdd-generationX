require 'fileutils'

module Bddgenx
  class Generator
    TIPOS_ISTQB = {
      "SUCCESS"     => "Teste Positivo",
      "FAILURE"     => "Teste Negativo",
      "ERROR"       => "Teste de Erro",
      "EXCEPTION"   => "Teste de Exceção",
      "VALIDATION"  => "Teste de Validação",
      "PERMISSION"  => "Teste de Permissão",
      "EDGE_CASE"   => "Teste de Limite",
      "PERFORMANCE" => "Teste de Desempenho"
    }.freeze

    def self.gerar_feature(historia)
      idioma = historia[:idioma]
      palavras = {
        contexto:  idioma == 'en' ? 'Background'       : 'Contexto',
        cenario:   idioma == 'en' ? 'Scenario'         : 'Cenário',
        esquema:   idioma == 'en' ? 'Scenario Outline' : 'Esquema do Cenário',
        exemplos:  idioma == 'en' ? 'Examples'         : 'Exemplos',
        regra:     idioma == 'en' ? 'Rule'             : 'Regra'
      }

      nome_base = historia[:quero].gsub(/[^a-z0-9]/i, '_').downcase
      caminho   = "features/#{nome_base}.feature"

      conteudo = <<~GHERKIN
        # language: #{idioma}
        Funcionalidade: #{historia[:quero].sub(/^Quero\s*/, '')}

          #{historia[:como]}
          #{historia[:quero]}
          #{historia[:para]}

      GHERKIN

      historia[:grupos].each_with_index do |grupo, idx|
        tipo     = grupo[:tipo]
        tag      = grupo[:tag]
        passos   = grupo[:passos]
        exemplos = grupo[:exemplos]

        next if passos.empty?

        linha_tag = ["@#{tipo.downcase}", ("@#{tag}" if tag)].compact.join(' ')
        possui_parametros = passos.any? { |p| p.include?('<') } && exemplos.any?

        if possui_parametros
          conteudo << "    #{linha_tag}\n"
          conteudo << "    #{palavras[:esquema]}: Exemplo #{idx + 1}\n"
          passos.each { |p| conteudo << "      #{p}\n" }
          conteudo << "\n      #{palavras[:exemplos]}:\n"
          exemplos.each { |linha| conteudo << "        #{linha}\n" }
          conteudo << "\n"
        else
          nome_teste = TIPOS_ISTQB[tipo] || palavras[:cenario]
          contexto   = passos.first.gsub(/^(Dado|Quando|Então|E|Mas)\s+/, '').strip
          resultado  = passos.last .gsub(/^(Dado|Quando|Então|E|Mas)\s+/, '').strip
          nome_ceno  = "#{nome_teste} - #{contexto} - #{resultado}"

          conteudo << "    #{linha_tag}\n"
          conteudo << "    #{palavras[:cenario]}: #{nome_ceno}\n"
          passos.each { |p| conteudo << "      #{p}\n" }
          conteudo << "\n"
        end
      end

      [caminho, conteudo]
    end

    def self.salvar_feature(caminho, conteudo)
      FileUtils.mkdir_p(File.dirname(caminho))
      File.write(caminho, conteudo)
      puts "✅ Arquivo .feature gerado: #{caminho}"
      true
    end
  end
end
