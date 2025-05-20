# encoding: utf-8
#
# Este arquivo é responsável por carregar todas as dependências da gem `bddgenx`.
#
# Ele inclui:
# - Gems padrão do Ruby (ex: JSON, net/http, fileutils)
# - Gems externas (ex: Prawn, Faraday, Dotenv)
# - Módulos internos do projeto `bddgenx`
#
# Também define o idioma ativo da gem (via I18n), configura variáveis de ambiente
# e carrega clientes de IA, geradores, validadores, exportadores e estruturas de projeto.

# --------------------------------------
# 📦 Gems padrão da linguagem Ruby
# --------------------------------------

require 'json'           # Manipulação de dados JSON
require 'net/http'       # Requisições HTTP nativas
require 'uri'            # Manipulação de URLs
require 'fileutils'      # Operações com arquivos e diretórios
require 'open3'          # Execução de comandos externos
require 'bigdecimal'     # Cálculos com alta precisão
require 'i18n'           # Internacionalização
require 'csv'            # Manipulação de arquivos CSV
require 'yard'           # Documentação automática

# --------------------------------------
# 📚 Gems externas
# --------------------------------------

require 'prawn'          # Geração de PDFs
require 'prawn/table'    # Tabelas em PDF
require 'prawn-svg'      # Suporte a SVG no PDF
require 'faraday'        # Cliente HTTP
require 'dotenv'         # Carrega variáveis de .env
require 'unicode'        # Manipulação de caracteres unicode
require 'java_properties'# Leitura de arquivos .properties
require 'stringio'       # IO virtual em memória
require 'tempfile'       # Arquivos temporários

# --------------------------------------
# 🌍 Configuração de idioma (I18n)
# --------------------------------------

Dotenv.load  # Carrega as variáveis do `.env`

# Carrega os arquivos de tradução do diretório `locales/`
locales_path = File.expand_path('bddgenx/locales/*.yml', __dir__)
I18n.load_path += Dir[locales_path]

# Define o idioma ativo com base em ENV['BDDGENX_LANG'], padrão: :pt
I18n.locale = ENV['BDDGENX_LANG']&.strip&.to_sym || :pt

# --------------------------------------
# 🔧 Bundler (para carregar dependências do Gemfile)
# --------------------------------------

require 'bundler/setup' if File.exist?(File.expand_path('../../Gemfile', __FILE__))

# --------------------------------------
# 🧩 Módulos utilitários internos
# --------------------------------------

require_relative 'bddgenx/support/validator'
require_relative 'bddgenx/support/font_loader'
require_relative 'bddgenx/utils/gherkin_cleaner_helper'
require_relative 'bddgenx/utils/remover_steps_duplicados_helper'
require_relative 'bddgenx/utils/language_helper'

# --------------------------------------
# 🤖 Clientes de IA (OpenAI, Gemini, Copilot)
# --------------------------------------

require_relative 'bddgenx/ia/gemini_cliente'
require_relative 'bddgenx/ia/chatgtp_cliente'
require_relative 'bddgenx/ia/microsoft_copilot_cliente'

# --------------------------------------
# 🛠 Geradores e Orquestrador
# --------------------------------------

require_relative 'bddgenx/generators/generator'
require_relative 'bddgenx/generators/steps_generator'
require_relative 'bddgenx/generators/runner'

# --------------------------------------
# 📄 Parser e Metadados
# --------------------------------------

require_relative 'parser'
require_relative 'bddgenx/version'

# --------------------------------------
# 📤 Relatórios e Exportação
# --------------------------------------

require_relative 'bddgenx/reports/pdf_exporter'
require_relative 'bddgenx/reports/backup'
require_relative 'bddgenx/reports/tracer'

# --------------------------------------
# ⚙️ Configuração e Setup
# --------------------------------------

require_relative 'bddgenx/configuration'
require_relative 'bddgenx/setup'
require_relative 'bddgenx/support/loader'
require_relative 'bddgenx/support/properties_loader'

# --------------------------------------
# 🔁 Carregamento de propriedades como variáveis de ambiente
# --------------------------------------

properties = Bddgenx::PropertiesLoader.load_properties

# Mapeamento de variáveis .properties → ENV
ENV['CHATGPT_API_URL'] ||= properties['openai.api.url']
ENV['OPENAI_API_KEY'] ||= properties['openai.api.key']
ENV['GEMINI_API_URL']  ||= properties['gemini.api.url']
ENV['GEMINI_API_KEY']  ||= properties['gemini.api.key']
ENV['MICROSOFT_COPILOT_API_URL'] ||= properties['copilot.api.url']
ENV['MICROSOFT_COPILOT_API_KEY'] ||= properties['copilot.api.key']
ENV['BDDGENX_MODE'] ||= properties['mode']
ENV['BDDGENX_LANG'] ||= properties['lang']
