# lib/bddgenx/properties_loader.rb
#
# Módulo `Bddgenx::PropertiesLoader` é responsável por carregar e processar os arquivos de configuração
# `.properties` que contêm variáveis de ambiente, além de também carregar as variáveis do arquivo `.env`.
# Este módulo lida com a substituição de placeholders nas propriedades, garantindo que as variáveis de ambiente
# sejam corretamente carregadas e definidas para uso no sistema.
#
# O fluxo de trabalho é o seguinte:
# 1. Carregar variáveis de ambiente a partir do arquivo `.env`.
# 2. Localizar e ler arquivos `.properties` presentes no diretório raiz do projeto.
# 3. Substituir placeholders no conteúdo dos arquivos `.properties` com variáveis de ambiente.
# 4. Mesclar as propriedades carregadas e definir as variáveis de ambiente no Ruby.
#
# Este módulo permite a configuração flexível de variáveis de ambiente, com suporte tanto para arquivos `.env`
# quanto para arquivos `.properties`.

module Bddgenx
  class PropertiesLoader
    # Carregar as variáveis do arquivo .env
    #
    # Este método utiliza a gem `dotenv` para carregar variáveis de ambiente a partir de um arquivo `.env`.
    # Ele carrega as variáveis do arquivo `.env` para o ambiente de execução, onde elas ficam disponíveis via
    # `ENV['VAR_NAME']` em qualquer parte do código.
    def self.load_env_variables
      Dotenv.load  # Carrega as variáveis do .env automaticamente
    end

    # Função para substituir variáveis no conteúdo do arquivo .properties
    #
    # Este método recebe o conteúdo de um arquivo `.properties` e substitui os placeholders no formato `{{VAR_NAME}}`
    # pelas variáveis de ambiente correspondentes, se definidas. Caso a variável de ambiente não esteja definida,
    # o placeholder original é mantido no conteúdo.
    #
    # @param content [String] O conteúdo do arquivo `.properties` a ser processado.
    # @return [String] O conteúdo com os placeholders substituídos pelas variáveis de ambiente.
    def self.replace_placeholders(content)
      content.gsub!(/\{\{(\w+)\}\}/) do |match|
        ENV[$1] || match  # Substitui pela variável de ambiente ou mantém o placeholder
      end
      content
    end

    # Função para garantir que o arquivo seja lido com a codificação correta
    #
    # Este método lê um arquivo especificado com codificação UTF-8. Caso o arquivo contenha caracteres inválidos,
    # eles são substituídos por um caractere de substituição, garantindo que o conteúdo seja lido corretamente.
    #
    # @param file [String] O caminho do arquivo a ser lido.
    # @return [String] O conteúdo do arquivo lido, com caracteres inválidos substituídos, se necessário.
    def self.read_file_with_correct_encoding(file)
      # Lê o arquivo com codificação UTF-8 e ignora caracteres inválidos
      content = File.read(file, encoding: 'UTF-8')
      content.encode('UTF-8', invalid: :replace, undef: :replace, replace: '?')
    end

    # Carregar e substituir propriedades de arquivos .properties
    #
    # Este método localiza todos os arquivos `.properties` no diretório raiz do projeto,
    # lê seu conteúdo, substitui os placeholders pelas variáveis de ambiente, carrega as propriedades
    # e mescla essas propriedades em um único hash.
    #
    # Após carregar as propriedades, ele também define as variáveis de ambiente no Ruby (via `ENV`)
    # usando as propriedades carregadas, mas não sobrescreve as variáveis de ambiente já definidas.
    #
    # @return [Hash] O hash contendo as propriedades carregadas e mescladas dos arquivos `.properties`.
    def self.load_properties
      # Carregar variáveis do .env primeiro
      load_env_variables

      # Localizar arquivos .properties na raiz do projeto
      properties_files = Dir.glob(File.expand_path('../*.properties', __dir__))

      properties = {}

      properties_files.each do |file|
        # Forçar a leitura do arquivo com codificação UTF-8 e lidar com caracteres inválidos
        content = read_file_with_correct_encoding(file)

        # Substituir os placeholders antes de carregar as propriedades
        content = replace_placeholders(content)

        # Carregar as propriedades do arquivo
        file_properties = JavaProperties::Properties.load(StringIO.new(content))

        # Mesclar as propriedades carregadas no hash
        properties.merge!(file_properties.to_h)
      end

      # Agora, define as variáveis de ambiente a partir das propriedades carregadas
      set_environment_variables(properties)

      properties
    end

    # Função para definir variáveis de ambiente a partir das propriedades carregadas
    #
    # Este método percorre as propriedades carregadas e as define como variáveis de ambiente (`ENV`) no Ruby.
    # Se a variável de ambiente já estiver definida (por exemplo, pelo `.env`), ela não será sobrescrita.
    #
    # @param properties [Hash] O hash contendo as propriedades carregadas dos arquivos `.properties`.
    def self.set_environment_variables(properties)
      properties.each do |key, value|
        # Se a variável de ambiente já estiver definida, não sobrescreve
        ENV[key.upcase] ||= value
      end
    end
  end
end
