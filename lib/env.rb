# lib/bddgenx/env.rb
# encoding: utf-8
#
# Este arquivo é responsável por carregar todas as dependências da gem `bddgenx`.
# Ele inclui as bibliotecas padrão do Ruby, gems externas necessárias para o funcionamento da gem,
# e arquivos internos essenciais para a geração automática de BDD.
#
# A gem `bddgenx` oferece suporte à internacionalização (I18n), integração com APIs de IA (ChatGPT, Gemini),
# geração de documentos PDF, validações de entrada e estruturação do projeto para automação de testes em BDD.
#
# Dependências carregadas:
# - Gems padrão do Ruby: JSON, net/http, uri, fileutils, open3, bigdecimal, i18n
# - Gems externas: Prawn (PDF), Faraday (cliente HTTP), Dotenv (variáveis de ambiente), e outros utilitários
#
# Estrutura:
# - Inicialização de variáveis de ambiente e idioma
# - Carregamento de dependências internas
# - Configuração do modo de execução (static, chatgpt, gemini)
#

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
require 'java_properties' # Manipulação de arquivos `.properties`
require 'stringio'       # Manipulação de objetos IO em memória
require 'tempfile'       # Criação de arquivos temporários (se necessário)

# --------------------------------------
# 🌍 Configuração de idioma (I18n)
# --------------------------------------
#
# O arquivo de propriedades pode configurar o idioma das mensagens e textos.
# O idioma padrão é o português (pt), mas ele pode ser alterado para inglês (en) conforme a necessidade.
#
# O código verifica se a variável de ambiente `BDDGENX_LANG` foi definida,
# e se sim, usa esse valor para configurar o idioma ativo. Caso contrário,
# o idioma padrão será `pt`.

# Carrega variáveis de ambiente do arquivo .env
Dotenv.load  # Carrega variáveis como BDDGENX_LANG e APIs

# Define o caminho para os arquivos de tradução em YAML para o I18n
locales_path = File.expand_path('bddgenx/locales/*.yml', __dir__)
I18n.load_path += Dir[locales_path]

# Define o idioma ativo baseado na variável de ambiente BDDGENX_LANG ou usa o idioma padrão (pt)
idioma_env = ENV['BDDGENX_LANG']
if idioma_env && !idioma_env.strip.empty?
  I18n.locale = idioma_env.strip.to_sym
else
  I18n.locale = :pt
end


# --------------------------------------
# 🔧 Bundler (para projetos com Gemfile)
# --------------------------------------
#
# Carrega as dependências do projeto listadas no Gemfile, se existir.
# Isso permite que o Bundler gerencie as dependências e garanta que todas as gems necessárias
# estejam disponíveis durante a execução da gem.
#
# Se um `Gemfile` estiver presente, o Bundler será configurado para carregar essas dependências.

# Carrega as dependências listadas no Gemfile (se houver)
require 'bundler/setup' if File.exist?(File.expand_path('../../Gemfile', __FILE__))

# --------------------------------------
# 🧩 Módulos utilitários da gem
# --------------------------------------
#
# Aqui estão os módulos auxiliares utilizados para o funcionamento da gem `bddgenx`.
# Esses módulos oferecem funcionalidades como validação de estrutura de entrada,
# carregamento de fontes para geração de PDFs, e limpeza do conteúdo Gherkin.

require_relative 'bddgenx/support/validator'                 # Valida estrutura de entrada
require_relative 'bddgenx/support/font_loader'               # Carrega fontes do PDF

# Utilitários para limpeza e remoção de passos duplicados
require_relative 'bddgenx/utils/gherkin_cleaner_helper'           # Sanitização de Gherkin gerado
require_relative 'bddgenx/utils/remover_steps_duplicados_helper'  # Remove passos duplicados
require_relative 'bddgenx/utils/language_helper'                   # Helper para palavras-chave em diferentes idiomas

# --------------------------------------
# 🤖 Clientes de IA (ChatGPT, Gemini)
# --------------------------------------
#
# Aqui são carregados os módulos para integração com as APIs de IA: ChatGPT (OpenAI) e Gemini (Google).
# Esses clientes são utilizados para gerar automaticamente os cenários BDD com base nas histórias de usuário.

require_relative 'bddgenx/ia/gemini_cliente'   # Integração com Google Gemini
require_relative 'bddgenx/ia/chatgtp_cliente'  # Integração com OpenAI (ChatGPT)

# --------------------------------------
# 🛠 Geradores (features, steps e execução)
# --------------------------------------
#
# Esses módulos são responsáveis pela geração dos arquivos `.feature` e `*_steps.rb`,
# que são a base para os testes BDD gerados pela gem.

require_relative 'bddgenx/generators/generator'        # Geração do conteúdo `.feature`
require_relative 'bddgenx/generators/steps_generator'  # Geração de arquivos `*_steps.rb`
require_relative 'bddgenx/generators/runner'           # Orquestrador da execução CLI

# --------------------------------------
# 📄 Parser e metadados
# --------------------------------------
#
# O parser é responsável por interpretar os arquivos `.txt` que contêm as histórias de usuário,
# que depois são transformadas em cenários BDD e passos de testes.

require_relative 'parser'               # Interpreta arquivos `.txt` de entrada
require_relative 'bddgenx/version'      # Lê versão do arquivo `VERSION`

# --------------------------------------
# 📤 Relatórios e exportação
# --------------------------------------
#
# Esses módulos gerenciam a exportação de resultados, geração de PDFs e backup das features,
# além de rastrear as mudanças realizadas nas features e no código.

require_relative 'bddgenx/reports/pdf_exporter'  # Exporta features para PDF
require_relative 'bddgenx/reports/backup'        # Gera backups de arquivos
require_relative 'bddgenx/reports/tracer'        # Rastreabilidade de geração

# --------------------------------------
# ⚙️ Configuração da gem e loaders auxiliares
# --------------------------------------
#
# Módulos auxiliares que cuidam de configurações gerais da gem e a inicialização da estrutura do projeto.

require_relative 'bddgenx/configuration'  # Variáveis de configuração (modo, APIs, etc.)
require_relative 'bddgenx/setup'          # Inicializa estrutura do projeto (input/, features/, etc.)
require_relative 'bddgenx/support/loader' # Exibe loaders/spinners no terminal

require_relative 'bddgenx/support/properties_loader'  # Carregador de arquivos .properties

# --------------------------------------
# 🔁 Define modo de execução (ambiente de dev por padrão)
# --------------------------------------
#
# Aqui são carregadas as variáveis de ambiente, seja do arquivo `.properties` ou do `.env`.
# O código busca as variáveis definidas no `.properties` e as coloca no ambiente (`ENV`),
# para que possam ser utilizadas em qualquer parte do código.

properties = Bddgenx::PropertiesLoader.load_properties
# Definir variáveis de ambiente com base no arquivo .properties
ENV['CHATGPT_API_URL'] ||= properties['openai.api.url']
ENV['OPENAI_API_KEY'] ||= properties['openai.api.key']

ENV['GEMINI_API_URL'] ||= properties['gemini.api.url']
ENV['GEMINI_API_KEY'] ||= properties['gemini.api.key']

ENV['BDDGENX_MODE'] ||= properties['mode']
ENV['BDDGENX_LANG'] ||= properties['lang']
