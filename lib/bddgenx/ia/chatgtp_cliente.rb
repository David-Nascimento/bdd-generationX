# lib/bddgenx/ia/chatgpt_cliente.rb

module Bddgenx
  module IA
    ##
    # Cliente para interação com a API do ChatGPT da OpenAI para gerar
    # cenários BDD no formato Gherkin, com suporte a fallback para Gemini.
    #
    class ChatGptCliente
      CHATGPT_API_URL = 'https://api.openai.com/v1/chat/completions'.freeze
      MODEL = 'gpt-4o'

      ##
      # Gera cenários BDD a partir de uma história fornecida,
      # solicitando à API do ChatGPT a criação dos cenários em formato Gherkin.
      # Se a API key não estiver configurada ou houver erro na requisição,
      # utiliza fallback com o GeminiCliente.
      #
      # @param historia [String] Texto com a história para basear os cenários.
      # @param idioma [String] Código do idioma ('pt' ou 'en'), padrão 'pt'.
      # @return [String] Cenários gerados em formato Gherkin com palavras-chave no idioma indicado.
      #
      def self.gerar_cenarios(historia, idioma = 'pt')
        api_key = Bddgenx.configuration.openai_api_key  # para ChatGPT

        unless api_key
          warn "❌ API Key do ChatGPT não encontrada no .env (OPENAI_API_KEY)"
          return fallback_com_gemini(historia, idioma)
        end

        # Palavras-chave Gherkin para português e inglês
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

        # Prompt base enviado ao ChatGPT, instruindo a saída no formato correto
        prompt_base = <<~PROMPT
          Gere cenários BDD no formato Gherkin, usando as palavras-chave de estrutura no idioma \"#{idioma}\":
            Feature: #{keywords[:feature]}
            Scenario: #{keywords[:scenario]}
            Scenario Outline: #{keywords[:scenario_outline]}
            Examples: #{keywords[:examples]}
            Given: #{keywords[:given]}
            When: #{keywords[:when]}
            Then: #{keywords[:then]}
            And: #{keywords[:and]}

          Atenção: Os textos e descrições dos cenários e passos devem ser escritos em português, mesmo que as palavras-chave estejam em inglês.

          História:
          #{historia}
        PROMPT

        uri = URI(CHATGPT_API_URL)
        request_body = {
          model: MODEL,
          messages: [
            {
              role: "user",
              content: prompt_base
            }
          ]
        }

        headers = {
          "Content-Type" => "application/json",
          "Authorization" => "Bearer #{api_key}"
        }

        response = Net::HTTP.post(uri, request_body.to_json, headers)

        if response.is_a?(Net::HTTPSuccess)
          json = JSON.parse(response.body)
          texto_ia = json.dig("choices", 0, "message", "content")

          if texto_ia
            texto_limpo = Bddgenx::GherkinCleaner.limpar(texto_ia)
            Utils::StepCleaner.remover_steps_duplicados(texto_ia, idioma)

            # Ajusta a linha de idioma no arquivo gerado
            texto_limpo.sub!(/^# language: .*/, "# language: #{idioma}")
            texto_limpo.prepend("# language: #{idioma}\n") unless texto_limpo.start_with?("# language:")
            return texto_limpo
          else
            warn "❌ Resposta da IA sem conteúdo de texto"
            warn JSON.pretty_generate(json)
            return fallback_com_gemini(historia, idioma)
          end
        else
          warn "❌ Erro ao chamar ChatGPT: #{response.code} - #{response.body}"
          return fallback_com_gemini(historia, idioma)
        end
      end

      ##
      # Método de fallback que chama o GeminiCliente para gerar cenários,
      # usado quando a API do ChatGPT não está disponível ou ocorre erro.
      #
      # @param historia [String] Texto da história para basear os cenários.
      # @param idioma [String] Código do idioma ('pt' ou 'en').
      # @return [String] Cenários gerados pelo GeminiCliente.
      #
      def self.fallback_com_gemini(historia, idioma)
        warn "🔁 Tentando gerar com Gemini como fallback..."
        GeminiCliente.gerar_cenarios(historia, idioma)
      end

      ##
      # Detecta o idioma de um arquivo de feature pela linha "# language:".
      #
      # @param caminho_arquivo [String] Caminho para o arquivo de feature.
      # @return [String] Código do idioma detectado ('pt' por padrão).
      #
      def self.detecta_idioma_arquivo(caminho_arquivo)
        return 'pt' unless File.exist?(caminho_arquivo)

        File.foreach(caminho_arquivo) do |linha|
          if linha =~ /^#\s*language:\s*(\w{2})/i
            return $1.downcase
          end
        end

        'pt'
      end
    end
  end
end
