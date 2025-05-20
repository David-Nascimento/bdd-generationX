module Bddgenx
  module IA
    ##
    # Cliente para interação com a API Microsoft Copilot para geração
    # de conteúdo, aqui usado para criar cenários BDD no formato Gherkin.
    #
    class MicrosoftCopilotCliente
      MICROSOFT_COPILOT_API_URL = ENV['MICROSOFT_COPILOT_API_URL']

      ##
      # Gera cenários BDD baseados em uma história, solicitando à API Microsoft Copilot
      # o retorno no formato Gherkin com palavras-chave no idioma desejado.
      #
      # @param historia [String] Texto base da história para gerar os cenários.
      # @param idioma [String] Código do idioma, 'pt' por padrão.
      # @return [String, nil] Cenários no formato Gherkin, ou nil em caso de erro.
      #
      def self.gerar_cenarios(historia, idioma = 'pt')
        api_key = Bddgenx.configuration.microsoft_copilot_api_key  # para Copilot

        # Define as palavras-chave para os cenários BDD
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

        # Escolhe o conjunto de palavras-chave conforme o idioma
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

        # Verifica se a chave de API foi configurada corretamente
        unless api_key
          warn "❌ API Key do Microsoft Copilot não encontrada no .env (MICROSOFT_COPILOT_API_KEY)"
          return nil
        end

        # Define o endpoint da API Microsoft Copilot
        uri = URI("#{MICROSOFT_COPILOT_API_URL}?key=#{api_key}")

        # Estrutura do corpo da requisição para a API Microsoft Copilot
        request_body = {
          contents: [
            {
              model: "o4-mini",
              role: "user",
              parts: [{ text: prompt_base }]
            }
          ]
        }

        # Executa requisição POST para a API Microsoft Copilot
        response = Net::HTTP.post(uri, request_body.to_json, { "Content-Type" => "application/json" })

        # Verifica se a resposta foi bem-sucedida
        if response.is_a?(Net::HTTPSuccess)
          json = JSON.parse(response.body)

          unless json["choices"]&.is_a?(Array) && json["choices"].any?
            warn "❌ Resposta da IA sem candidatos válidos:"
            warn JSON.pretty_generate(json)
            return nil
          end

          # Recupera o conteúdo gerado pela IA
          texto_ia = json["choices"].first.dig("message", "content")

          if texto_ia
            # Limpeza e sanitização do texto para manter padrão Gherkin
            texto_limpo = Utils.limpar(texto_ia)
            Utils.remover_steps_duplicados(texto_ia, idioma)

            # Ajuste da diretiva de idioma na saída gerada
            texto_limpo.sub!(/^# language: .*/, "# language: #{idioma}")
            texto_limpo.prepend("# language: #{idioma}\n") unless texto_limpo.start_with?("# language:")

            return texto_limpo
          else
            warn I18n.t('errors.ia_no_content')
            warn JSON.pretty_generate(json)
            return nil
          end
        else
          warn I18n.t('errors.microsoft_copilot_error', code: response.code, body: response.body)
          return nil
        end
      end
    end
  end
end
