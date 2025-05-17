# lib/bddgenx/configuration.rb
module Bddgenx
  class Configuration
    # :static, :chatgpt ou :gemini
    attr_accessor :mode

    # Nomes das ENV vars para as chaves
    attr_accessor :openai_api_key_env, :gemini_api_key_env

    def initialize
      @mode = :static
      @openai_api_key_env = 'OPENAI_API_KEY'
      @gemini_api_key_env = 'GEMINI_API_KEY'
    end

    # Retorna a chave real, carregada do ENV
    def openai_api_key
      ENV[@openai_api_key_env]
    end

    def gemini_api_key
      ENV[@gemini_api_key_env]
    end
  end

  # Singleton de configuração
  def self.configuration
    @configuration ||= Configuration.new
  end

  # DSL para configurar
  def self.configure
    yield(configuration)
  end
end
