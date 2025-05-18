# lib/bddgenx/setup.rb

module Bddgenx
  class Setup
    def self.run
      puts "🛠 Iniciando verificação da estrutura do projeto..."

      criar_pasta_com_log('input') do
        File.write('input/historia.txt', <<~TXT) unless File.exist?('input/historia.txt')
          # language: pt
          Como um usuário do sistema
          Quero acessar minha conta
          Para realizar ações seguras

          [CONTEXT]
          Dado que estou na tela de login

          [SUCCESS]
          Quando preencho email e senha válidos
          Então vejo a tela inicial
        TXT
      end

      criar_pasta_com_log('features/steps') do
        File.write('features/exemplo_login.feature', <<~FEATURE) unless File.exist?('features/exemplo_login.feature')
          # language: pt
          Funcionalidade: Acesso ao sistema

            @contexto
            Cenário: Acesso bem-sucedido
              Dado que estou na tela de login
              Quando preencho email e senha válidos
              Então vejo a tela inicial
        FEATURE

        File.write('features/steps/exemplo_login_steps.rb', <<~STEP) unless File.exist?('features/steps/exemplo_login_steps.rb')
          Dado("que estou na tela de login") do
            pending 'Implementar: que estou na tela de login'
          end

          Quando("preencho email e senha válidos") do
            pending 'Implementar: preencho email e senha válidos'
          end

          Então("vejo a tela inicial") do
            pending 'Implementar: vejo a tela inicial'
          end
        STEP
      end

      criar_pasta_com_log('reports/pdf')
      criar_pasta_com_log('reports/backup')

      unless File.exist?('.env')
        File.write('.env', <<~ENV)
          ############################################
          # CONFIGURAÇÃO DE CHAVES DE ACESSO À IA   #
          ############################################
          OPENAI_API_KEY={{SUA_CHAVE_OPENAI}}
          GEMINI_API_KEY={{SUA_CHAVE_GEMINI}}

          ############################################
          # CONFIGURAÇÃO DE URI DE ACESSO À IA   #
          ############################################
          CHATGPT_API_URL={{SUA_CHAVE_OPENAI}}
          GEMINI_API_URL={{SUA_CHAVE_GEMINI}}

          ############################################
          # MODO DE GERAÇÃO DE CENÁRIOS BDD         #
          ############################################
          BDDGENX_MODE=static
          BDDGENX_LANG=pt
        ENV
        puts "✅ Arquivo .env criado com configurações iniciais."
      else
        puts "✔️  Arquivo .env já existente."
      end

      puts "✅ Estrutura verificada com sucesso!"
    end

    def self.criar_pasta_com_log(path)
      if Dir.exist?(path)
        puts "✔️  Diretório já existe: #{path}"
      else
        FileUtils.mkdir_p(path)
        puts "📁 Diretório criado: #{path}"
        yield if block_given?
      end
    end
  end
end
