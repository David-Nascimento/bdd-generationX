# lib/bddgenx/env.rb
# encoding: utf-8
#
# Responsável por carregar todas as dependências da gem bddgenx.
# Inclui bibliotecas padrão, gems externas e arquivos internos
# essenciais para o funcionamento da geração BDD, com suporte a I18n,
# IA (ChatGPT, Gemini), geração de PDF, validações e estrutura de projeto.

# --------------------------------------
# 📦 Gems padrão da linguagem Ruby
# --------------------------------------

require 'json'           # Manipulação de dados JSON
require 'net/http'       # Requisições HTTP nativas
require 'uri'            # Manipulação de URLs
require 'fileutils'      # Operações com arquivos e diretórios
require 'open3'          # Execução de comandos externos com captura de saída
require 'bigdecimal'     # Cálculos matemáticos de alta precisão
require 'i18n'           # Internacionalização (traduções dinâmicas)

# --------------------------------------
# 📚 Gems externas
# --------------------------------------

require 'prawn'          # Geração de documentos PDF
require 'prawn/table'    # Suporte a tabelas no Prawn
require 'prawn-svg'      # Suporte a SVG no PDF
require 'faraday'        # Cliente HTTP para integração com APIs (ex: Gemini)
require 'dotenv'         # Carrega variáveis de ambiente do arquivo `.env`
require 'unicode'        # Manipulação e normalização de caracteres Unicode

# --------------------------------------
# 🌍 Configuração de idioma (I18n)
# --------------------------------------

Dotenv.load  # Carrega variáveis como BDDGENX_LANG e APIs

# Define o caminho de arquivos de tradução YAML
locales_path = File.expand_path('bddgenx/locales/*.yml', __dir__)
I18n.load_path += Dir[locales_path]

# Define o idioma ativo somente se estiver presente e válido
idioma_env = ENV['BDDGENX_LANG']
if idioma_env && !idioma_env.strip.empty?
  I18n.locale = idioma_env.strip.to_sym
else
  I18n.locale = :pt
end


# --------------------------------------
# 🔧 Bundler (para projetos com Gemfile)
# --------------------------------------

# Carrega as dependências listadas no Gemfile (se houver)
require 'bundler/setup' if File.exist?(File.expand_path('../../Gemfile', __FILE__))

# --------------------------------------
# 🧩 Módulos utilitários da gem
# --------------------------------------

require_relative 'bddgenx/support/gherkin_cleaner'           # Sanitização de Gherkin gerado
require_relative 'bddgenx/support/remover_steps_duplicados'  # Remove passos duplicados
require_relative 'bddgenx/support/validator'                 # Valida estrutura de entrada
require_relative 'bddgenx/support/font_loader'               # Carrega fontes do PDF

# --------------------------------------
# 🤖 Clientes de IA (ChatGPT, Gemini)
# --------------------------------------

require_relative 'bddgenx/ia/gemini_cliente'   # Integração com Google Gemini
require_relative 'bddgenx/ia/chatgtp_cliente'  # Integração com OpenAI (ChatGPT)

# --------------------------------------
# 🛠 Geradores (features, steps e execução)
# --------------------------------------

require_relative 'bddgenx/generators/generator'        # Geração do conteúdo `.feature`
require_relative 'bddgenx/generators/steps_generator'  # Geração de arquivos `*_steps.rb`
require_relative 'bddgenx/generators/runner'           # Orquestrador da execução CLI

# --------------------------------------
# 📄 Parser e metadados
# --------------------------------------

require_relative 'parser'               # Interpreta arquivos `.txt` de entrada
require_relative 'bddgenx/version'      # Lê versão do arquivo `VERSION`

# --------------------------------------
# 📤 Relatórios e exportação
# --------------------------------------

require_relative 'bddgenx/reports/pdf_exporter'  # Exporta features para PDF
require_relative 'bddgenx/reports/backup'        # Gera backups de arquivos
require_relative 'bddgenx/reports/tracer'        # Rastreabilidade de geração

# --------------------------------------
# ⚙️ Configuração da gem e loaders auxiliares
# --------------------------------------

require_relative 'bddgenx/configuration'  # Variáveis de configuração (modo, APIs, etc.)
require_relative 'bddgenx/setup'          # Inicializa estrutura do projeto (input/, features/, etc.)
require_relative 'bddgenx/support/loader' # Exibe loaders/spinners no terminal

# --------------------------------------
# 🔁 Define modo de execução (ambiente de dev por padrão)
# --------------------------------------

ENV['BDDGENX_ENV'] = 'development'
