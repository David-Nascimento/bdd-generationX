# lib/bddgenx/ia/gemini_cliente.rb
require 'net/http'
require 'json'
require 'uri'
require_relative '../utils/gherkin_cleaner'
require_relative '../utils/remover_steps_duplicados'

module Bddgenx
  module IA
    class GeminiCliente
      GEMINI_API_URL = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent'.freeze

      def self.gerar_cenarios(historia, idioma = 'pt')
        api_key = ENV['GEMINI_API_KEY']

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

        # Prompt base para solicitar saída Gherkin estruturada da IA
        prompt_base = <<~PROMPT
          Gere cenários BDD no formato Gherkin, usando as palavras-chave de estrutura no idioma "#{idioma}":
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
        unless api_key
          warn "❌ API Key do Gemini não encontrada no .env (GEMINI_API_KEY)"
          return nil
        end

        uri = URI("#{GEMINI_API_URL}?key=#{api_key}")
        prompt = prompt_base % { historia: historia }

        request_body = {
          contents: [
            {
              role: "user",
              parts: [{ text: prompt }]
            }
          ]
        }

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
            # Sanitiza o texto para garantir formato Gherkin correto
            texto_limpo = Bddgenx::GherkinCleaner.limpar(texto_ia)
            Utils::StepCleaner.remover_steps_duplicados(texto_ia, idioma)

            # Insere a diretiva language dinamicamente com base no idioma detectado
            texto_limpo.sub!(/^# language: .*/, "# language: #{idioma}")
            texto_limpo.prepend("# language: #{idioma}\n") unless texto_limpo.start_with?("# language:")

            return texto_limpo
          else
            warn "❌ Resposta da IA sem conteúdo de texto"
            warn JSON.pretty_generate(json)
            return nil
          end
        else
          warn "❌ Erro ao chamar Gemini: #{response.code} - #{response.body}"
          return nil
        end
      end

      def self.detecta_idioma_arquivo(caminho_arquivo)
        return 'pt' unless File.exist?(caminho_arquivo)

        File.foreach(caminho_arquivo) do |linha|
          if linha =~ /^#\s*language:\s*(\w{2})/i
            return $1.downcase
          end
        end

        'pt' # padrão
      end
    end
  end
end
