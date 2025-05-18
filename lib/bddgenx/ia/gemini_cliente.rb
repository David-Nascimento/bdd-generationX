# lib/bddgenx/ia/gemini_cliente.rb

module Bddgenx
  module IA
    ##
    # Cliente para interação com a API Gemini do Google para geração
    # de conteúdo, aqui usado para criar cenários BDD no formato Gherkin.
    #
    class GeminiCliente
      GEMINI_API_URL = ENV['GEMINI_API_URL']

      ##
      # Gera cenários BDD baseados em uma história, solicitando à API Gemini
      # o retorno no formato Gherkin com palavras-chave no idioma desejado.
      #
      # @param historia [String] Texto base da história para gerar os cenários.
      # @param idioma [String] Código do idioma, 'pt' por padrão.
      # @return [String, nil] Cenários no formato Gherkin, ou nil em caso de erro.
      #
      def self.gerar_cenarios(historia, idioma = 'pt')
        api_key = Bddgenx.configuration.gemini_api_key  # para Gemini

        keywords_pt = {
          feature: "Funcionalidade",
          scenario: "Cenário",
          scenario_outline: "Esquema do Cenário",
          examples: "Exemplos",
          given: "Dado",
          when: "Quando",
          then: "Então",
          and: "E"
        }

        keywords_en = {
          feature: "Feature",
          scenario: "Scenario",
          scenario_outline: "Scenario Outline",
          examples: "Examples",
          given: "Given",
          when: "When",
          then: "Then",
          and: "And"
        }

        keywords = idioma == 'en' ? keywords_en : keywords_pt

        # Prompt base que instrui a IA a gerar cenários Gherkin no idioma indicado
        prompt_base = <<~PROMPT
                        Gere cenários BDD no formato Gherkin, utilizando as palavras-chave estruturais no idioma "#{idioma}":
                          Feature: #{keywords[:feature]}
                          Scenario: #{keywords[:scenario]}
                          Scenario Outline: #{keywords[:scenario_outline]}
                          Examples: #{keywords[:examples]}
                          Given: #{keywords[:given]}
                          When: #{keywords[:when]}
                          Then: #{keywords[:then]}
                          And: #{keywords[:and]}
                      
                        Instruções:
                        - Todos os textos dos passos devem ser escritos em **português**.
                        - Use as palavras-chave Gherkin no idioma especificado ("#{idioma}").
                        - Gere **vários cenários**, incluindo positivos e negativos.
                        - Use `Scenario Outline` e `Examples` sempre que houver valores variáveis.
                        - Mantenha os parâmetros como `<email>`, `<senha>` e outros entre colchetes angulares, exatamente como aparecem.
                        - Se a história fornecer contexto (ex: `[CONTEXT]` ou "Dado que..."), utilize-o como base para os cenários.
                        - Se não houver contexto explícito, **crie um coerente** baseado na história.
                        - A primeira linha do resultado deve conter obrigatoriamente `# language: #{idioma}`.
                        - Evite passos vagos ou genéricos. Use ações claras e específicas.
                        - Gere apenas o conteúdo da feature, sem explicações adicionais.
                      
                        História fornecida:
                        #{historia}
                      PROMPT



        unless api_key
          warn "❌ API Key do Gemini não encontrada no .env (GEMINI_API_KEY)"
          return nil
        end

        uri = URI("#{GEMINI_API_URL}?key=#{api_key}")

        # Estrutura do corpo da requisição para a API Gemini
        request_body = {
          contents: [
            {
              role: "user",
              parts: [{ text: prompt_base }]
            }
          ]
        }

        # Executa requisição POST para a API Gemini
        response = Net::HTTP.post(uri, request_body.to_json, { "Content-Type" => "application/json" })

        if response.is_a?(Net::HTTPSuccess)
          json = JSON.parse(response.body)

          unless json["candidates"]&.is_a?(Array) && json["candidates"].any?
            warn "❌ Resposta da IA sem candidatos válidos:"
            warn JSON.pretty_generate(json)
            return nil
          end

          texto_ia = json["candidates"].first.dig("content", "parts", 0, "text")
          if texto_ia
            # Limpeza e sanitização do texto para manter padrão Gherkin
            texto_limpo = Utils.limpar(texto_ia)
            Utils.remover_steps_duplicados(texto_ia, idioma)

            # Ajuste da diretiva de idioma na saída gerada
            texto_limpo.sub!(/^# language: .*/, "# language: #{idioma}")
            texto_limpo.prepend("# language: #{idioma}\n") unless texto_limpo.start_with?("# language:")

            # Garante diretiva de idioma
            feature_text = Utils.limpar(texto_ia)
            feature_text.sub!(/^# language: .*/, "") # remove qualquer # language: existente
            feature_text.prepend("# language: #{idioma}\n") # insere a correta

            return texto_limpo
          else
            warn I18n.t('errors.ia_no_content')
            warn JSON.pretty_generate(json)
            return nil
          end
        else
          warn I18n.t('errors.gemini_error', code: response.code, body: response.body)
          return nil
        end
      end
    end
  end
end
