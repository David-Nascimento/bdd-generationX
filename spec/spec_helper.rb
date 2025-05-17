# spec/spec_helper.rb
require 'bundler/setup' # Carrega as gems do Gemfile automaticamente
require 'rspec'
require 'webmock/rspec' # Para mockar requisições HTTP (se usar)
require 'simplecov' # Para medir cobertura de testes (opcional)
require 'set'
require 'unicode'

$LOAD_PATH.unshift(File.expand_path('../../lib', __dir__))

# Inicia SimpleCov para medir cobertura, opcional mas recomendável
SimpleCov.start do
  add_filter '/spec/'
  add_filter '/config/'
  add_filter '/vendor/'
  track_files '{lib}/**/*.rb'
end

RSpec.configure do |config|
  # Habilita o modo expect sintaxe do RSpec
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  # Configura mocks (mocks/stubs)
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true # Verifica se doubles/mocks batem com métodos reais
  end

  # Permite que os testes rodem em ordem aleatória (ajuda encontrar testes dependentes)
  config.order = :random

  # Seeds random para reprodutibilidade
  Kernel.srand config.seed

  # Habilita persistência do status dos testes (para rodar apenas falhos)
  config.example_status_persistence_file_path = 'spec/reports/examples.txt'

  # Permite filtrar testes por tags, por exemplo :focus para rodar só alguns testes
  config.filter_run_when_matching :focus

  # Configuração para imprimir backtrace reduzida para facilitar leitura
  config.backtrace_exclusion_patterns << /gems/

  # Antes e depois de cada teste, você pode configurar hooks para limpar estados, etc
  # Exemplo para limpar mocks:
  config.before(:each) do
    # Limpeza ou setup antes de cada teste
  end

  # Configura o formatter para saída colorida no terminal
  config.color = true
  config.tty = true

  # Configura o formatter padrão (progress)
  config.formatter = :progress
end

# Configura WebMock para bloquear conexões externas nas specs, a menos que permitido
WebMock.disable_net_connect!(allow_localhost: true)

# Requer arquivos principais do projeto para poder testar
# Ajuste os paths conforme sua estrutura
require_relative '../lib/env'

# Outras libs auxiliares que seu projeto usa podem ser carregadas aqui

