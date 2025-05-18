# lib/bddgenx/setup.rb

module Bddgenx
  class Setup
    SPINNER_FRAMES = %w[⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏].freeze
    SPINNER_DELAY = 0.1
    def self.run
      thread, stop = start_spinner(I18n.t('setup.spinner_checking'))

      resultados = []
      resultados << verificar("input") do
        File.write('input/historia.txt', exemplo_txt) unless File.exist?('input/historia.txt')
      end

      resultados << verificar("features/steps") do
        File.write('features/exemplo_login.feature', exemplo_feature) unless File.exist?('features/exemplo_login.feature')
        File.write('features/steps/exemplo_login_steps.rb', exemplo_step) unless File.exist?('features/steps/exemplo_login_steps.rb')
      end

      resultados << verificar("reports/pdf")
      resultados << verificar("reports/backup")

      resultados << verificar(".env", is_file: true) do
        File.write('.env', exemplo_env)
      end

      stop_spinner(thread, stop)

      resultados.each { |mensagem| puts mensagem }
      puts "\n#{I18n.t('setup.success')}"
    end

    def self.verificar(path, is_file: false)
      if is_file
        if File.exist?(path)
          I18n.t('setup.file_exists', path: path)
        else
          yield if block_given?
          I18n.t('setup.file_created', path: path)
        end
      else
        if Dir.exist?(path)
          I18n.t('setup.dir_exists', path: path)
        else
          FileUtils.mkdir_p(path)
          yield if block_given?
          I18n.t('setup.dir_created', path: path)
        end
      end
    end

    def self.start_spinner(mensagem)
      done_flag = false

      thread = Thread.new do
        i = 0
        until done_flag
          print "\r#{SPINNER_FRAMES[i % SPINNER_FRAMES.size]} #{mensagem}"
          sleep(SPINNER_DELAY)
          i += 1
        end
      end

      [thread, -> { done_flag = true }]
    end

    def self.stop_spinner(thread, stop_proc)
      stop_proc.call
      thread.join
      print "\r"
    end

    def self.exemplo_txt
      <<~TXT
        # language: pt
        Como um gerente
        Quero que meus clientes efetue login
        Para acompanhar o progresso da equipe
        
        [SUCCESS]
        Quando preencho email e senha válidos
        Então sou redirecionado para o dashboard
        
        [FAILURE]
        Quando informo uma senha incorreta
        Então recebo a mensagem "Credenciais inválidas"
        
        [SUCCESS]
        Quando tento logar com "<email>" e "<senha>"
        Então recebo "<resultado>"
        
        [EXAMPLES]
        | email              | senha            | resultado                 |
        | teste@site.com     | 123456           | acesso permitido          |
        | errado@site.com    | senhaincorreta   | acesso negado             |
      TXT
    end

    def self.exemplo_feature
      <<~FEATURE
      # language: pt
      Funcionalidade: que meus clientes efetue login
        # Como um gerente
        # Quero que meus clientes efetue login
        # Para acompanhar o progresso da equipe
          @success
          Cenário: Success
            Quando preencho email e senha válidos
            Então sou redirecionado para o dashboard
             
      
          @failure
          Cenário: Failure
            Quando informo uma senha incorreta
            Então recebo a mensagem "Credenciais inválidas"
      
          @success
          Esquema do Cenário: Exemplo 1
            Quando tento logar com "<email>" e "<senha>"
            Então recebo "<resultado>"
      
            Exemplos:
              | email              | senha            | resultado                 |
              | teste@site.com     | 123456           | acesso permitido          |
              | errado@site.com    | senhaincorreta   | acesso negado             |
    FEATURE
    end

    def self.exemplo_step
      <<~STEP
        Quando("preencho email e senha válidos") do
          pending 'Implementar passo: preencho email e senha válidos'
        end
        
        Então("sou redirecionado para o dashboard") do
          pending 'Implementar passo: sou redirecionado para o dashboard'
        end
        
        Quando("informo uma senha incorreta") do
          pending 'Implementar passo: informo uma senha incorreta'
        end
        
        Então("recebo a mensagem {string}") do |arg1|
          pending 'Implementar passo: recebo a mensagem "Credenciais inválidas"'
        end
        
        Quando("tento logar com {string} e {string}") do |arg1, arg2|
          pending 'Implementar passo: tento logar com "<email>" e "<senha>"'
        end
        
        Então("recebo {string}") do |arg1|
          pending 'Implementar passo: recebo "<resultado>"'
        end
      STEP
    end

    def self.exemplo_env
      <<~ENV
          ############################################
          # CONFIGURAÇÃO DE CHAVES DE ACESSO À IA   #
          ############################################
          OPENAI_API_KEY={{SUA_CHAVE_OPENAI}}
          CHATGPT_API_URL={{CHATGPT_API_URL}}
      
          ############################################
          # CONFIGURAÇÃO DE CHAVES DE URI À IA   #
          ############################################
          OPENAI_API_KEY={{SUA_CHAVE_OPENAI}}
          GEMINI_API_URL={{GEMINI_API_URL}}
      
          ############################################
          # MODO DE GERAÇÃO DE CENÁRIOS BDD         #
          ############################################
          BDDGENX_MODE=static
          BDDGENX_LANG=pt
        ENV
    end
  end
end
