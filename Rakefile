# Rakefile
require_relative 'lib/env'
require 'rake'

namespace :bddgenx do
  desc 'Inicializar projeto'
  task :setup do
    Bddgenx::Setup.inicializar_projeto
  end

  desc 'Executa a geração BDD usando o modo atual (static, chatgpt, gemini)'
  task :generate do
    puts "⚙️  Modo de geração: #{Bddgenx.configuration.mode}"

    # Evita que ARGV contenha o nome da task (como "bddgenx:static")
    ARGV.clear

    Bddgenx::Runner.execute
  end

  desc 'Gera features no modo estático (sem IA)'
  task :static do
    Bddgenx.configure do |config|
      config.mode = :static
    end
    ENV['BDDGENX_MODE'] = 'static'
    Rake::Task['bddgenx:generate'].invoke
  end

  desc 'Gera features usando ChatGPT'
  task :chatgpt do
    Bddgenx.configure do |config|
      config.mode = :chatgpt
      config.openai_api_key_env = 'OPENAI_API_KEY'
    end
    ENV['BDDGENX_MODE'] = 'chatgpt'
    Rake::Task['bddgenx:generate'].invoke
  end

  desc 'Gera features usando Gemini'
  task :gemini do
    Bddgenx.configure do |config|
      config.mode = :gemini
      config.gemini_api_key_env = 'GEMINI_API_KEY'
    end
    ENV['BDDGENX_MODE'] = 'gemini'
    Rake::Task['bddgenx:generate'].invoke
  end
end
