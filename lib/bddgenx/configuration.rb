# encoding: utf-8
#
# Este arquivo define a classe de configuração global da gem BDDGenX.
#
# A classe `Bddgenx::Configuration` permite configurar o modo de operação da ferramenta
# (ex: estático ou com IA) e define as variáveis de ambiente que armazenam as chaves de API
# para serviços externos como OpenAI (ChatGPT), Google Gemini e Microsoft Copilot.

module Bddgenx
  # Classe de configuração principal da gem BDDGenX.
  # Permite definir o modo de geração BDD e os nomes das variáveis de ambiente
  # que armazenam as chaves de API para integração com serviços de IA.
  class Configuration
    # Modo de execução da gem.
    # Pode ser:
    # - :static   → geração local
    # - :chatgpt  → uso da IA do ChatGPT (OpenAI)
    # - :gemini   → uso da IA Gemini (Google)
    # - :copilot  → uso do Microsoft Copilot
    #
    # @return [Symbol]
    attr_accessor :mode

    # Nome da variável de ambiente que contém a chave da API da OpenAI
    # @return [String]
    attr_accessor :openai_api_key_env

    # Nome da variável de ambiente que contém a chave da API do Google Gemini
    # @return [String]
    attr_accessor :gemini_api_key_env

    # Nome da variável de ambiente que contém a chave da API do Microsoft Copilot
    # @return [String]
    attr_accessor :microsoft_copilot_api_env

    ##
    # Inicializa a configuração com valores padrão:
    # - modo: :static
    # - ENV keys: 'OPENAI_API_KEY', 'GEMINI_API_KEY', 'MICROSOFT_COPILOT_API_KEY'
    def initialize
      @mode = :static
      @openai_api_key_env = 'OPENAI_API_KEY'
      @gemini_api_key_env = 'GEMINI_API_KEY'
      @microsoft_copilot_api_env = 'MICROSOFT_COPILOT_API_KEY'
    end

    ##
    # Retorna a chave da API do OpenAI, lida diretamente da ENV.
    #
    # @return [String, nil] Chave de API ou nil se não definida
    def openai_api_key
      ENV[@openai_api_key_env]
    end

    ##
    # Retorna a chave da API do Gemini, lida diretamente da ENV.
    #
    # @return [String, nil] Chave de API ou nil se não definida
    def gemini_api_key
      ENV[@gemini_api_key_env]
    end

    ##
    # Retorna a chave da API do Microsoft Copilot, lida diretamente da ENV.
    #
    # @return [String, nil] Chave de API ou nil se não definida
    def microsoft_copilot_api_key
      ENV[@microsoft_copilot_api_env]
    end
  end

  ##
  # Retorna uma instância singleton da configuração da gem.
  #
  # @return [Configuration]
  def self.configuration
    @configuration ||= Configuration.new
  end

  ##
  # Permite configurar a gem usando um bloco DSL.
  #
  # Exemplo:
  #   Bddgenx.configure do |config|
  #     config.mode = :gemini
  #     config.gemini_api_key_env = 'MY_GEMINI_KEY'
  #   end
  #
  # @yieldparam config [Configuration] instância de configuração atual
  def self.configure
    yield(configuration)
  end
end
