# lib/bddgenx/env.rb

# Carregamento de bibliotecas padrão e gems externas usadas no projeto

require 'json'           # Para manipulação de dados JSON
require 'net/http'       # Para fazer requisições HTTP
require 'uri'            # Para manipulação de URLs
require 'fileutils'      # Para manipulação de arquivos e diretórios
require 'prawn'          # Biblioteca para geração de PDFs
require 'prawn/table'    # Suporte a tabelas no Prawn PDF
require 'prawn-svg'      # Para incorporar SVG em PDFs com Prawn
require 'open3'          # Para executar comandos externos com captura de saída
require 'faraday'        # Cliente HTTP para Gemini API
require 'dotenv'         # Para carregar variáveis de ambiente de arquivos .env
require 'unicode'        # Para manipulação avançada de strings Unicode (ex: remoção de acentos)
require 'bigdecimal'     # Para operações matemáticas precisas com decimais

# Configura o caminho base do projeto e carrega as gems definidas no Gemfile (se existir)
require 'bundler/setup' if File.exist?(File.expand_path('../../Gemfile', __FILE__))

# Carregamento dos módulos utilitários (helpers)
require_relative  'bddgenx/support/gherkin_cleaner'          # Limpeza e normalização de textos Gherkin
require_relative  'bddgenx/support/remover_steps_duplicados' # Remoção de steps duplicados em features
require_relative  'bddgenx/support/validator'                # Validação de dados e entrada
require_relative  'bddgenx/support/font_loader'              # Carregamento de fontes para geração PDF

# Carregamento dos clientes para Integração com Inteligência Artificial
require_relative  'bddgenx/ia/gemini_cliente'                # Cliente para API Gemini (Google)
require_relative  'bddgenx/ia/chatgtp_cliente'               # Cliente para API ChatGPT (OpenAI)

# Carregamento dos geradores de BDD (features, steps e runner)
require_relative  'bddgenx/generators/generator'             # Gerador principal de arquivos .feature
require_relative  'bddgenx/generators/steps_generator'       # Gerador de arquivos steps.rb
require_relative  'bddgenx/generators/runner'                 # Classe responsável pela execução do processo de geração

# Parser do arquivo de entrada e versão da gem
require_relative  'parser'                                    # Parser para interpretar arquivos de entrada
require_relative 'bddgenx/version'                                   # Informação da versão da gem

# Relatórios e exportação
require_relative  'bddgenx/reports/pdf_exporter'              # Exporta relatórios em PDF usando Prawn
require_relative  'bddgenx/reports/backup'                    # Mecanismo de backup dos arquivos gerados
require_relative  'bddgenx/reports/tracer'                    # Rastreabilidade dos processos

require_relative 'bddgenx/configuration'                      # Configuração das variaveis de IA

# Define variável de ambiente global para indicar que o ambiente BDDGENX está em modo desenvolvimento
ENV['BDDGENX_ENV'] = 'development'
