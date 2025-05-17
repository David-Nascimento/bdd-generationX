# lib/bddgenx/env.rb
require 'json'
require 'net/http'
require 'uri'
require 'fileutils'
require 'prawn'
require 'prawn/table'
require 'prawn-svg'
require 'open3'
require 'faraday' # Gemini
require 'dotenv'
require 'unicode'
require 'bigdecimal'

# Caminho base do projeto
# Carrega todas as dependências do Bundler (se estiver usando)
require 'bundler/setup' if File.exist?(File.expand_path('../../Gemfile', __FILE__))

# Utils
require_relative  'bddgenx/support/gherkin_cleaner'
require_relative  'bddgenx/support/remover_steps_duplicados'
require_relative  'bddgenx/support/validator'
require_relative  'bddgenx/support/font_loader'

# IA
require_relative  'bddgenx/ia/gemini_cliente'
require_relative  'bddgenx/ia/chatgtp_cliente'

# Generator
require_relative  'bddgenx/generators/generator'
require_relative  'bddgenx/generators/steps_generator'
require_relative  'bddgenx/generators/runner'

# Parser e versão
require_relative  'parser'
require_relative  'version'

# Relatórios
require_relative  'bddgenx/reports/pdf_exporter'
require_relative  'bddgenx/reports/backup'
require_relative  'bddgenx/reports/tracer'

# Define uma constante global para indicar carregamento completo
ENV['BDDGENX_ENV'] = 'development'