require 'bddgenx'
require 'rake'

namespace :bddgenx do
  desc 'Executa geração interativa: escolha entre static, chatgpt, gemini ou deepseek'
  task :generate do
    puts "=== Qual modo deseja usar para gerar os cenários? ==="
    puts "1. static (sem IA)"
    puts "2. chatgpt (via OpenAI)"
    puts "3. gemini (via Google)"
    print "Digite o número (1-3): "

    escolha = STDIN.gets.chomp.to_i

    modo = case escolha
           when 1 then :static
           when 2 then :chatgpt
           when 3 then :gemini
           else
             puts "❌ Opção inválida. Saindo."; exit 1
           end

    Bddgenx.configure do |config|
      config.mode = modo
      config.openai_api_key_env = 'OPENAI_API_KEY'
      config.gemini_api_key_env = 'GEMINI_API_KEY'
    end

    # ⚠️ Limpa o ARGV antes de executar para evitar que [static] seja interpretado como nome de arquivo
    ARGV.clear

    ENV['BDDGENX_MODE'] = modo.to_s
    puts "\n⚙️  Modo selecionado: #{modo}\n\n"
    Bddgenx::Runner.execute
  end
end
