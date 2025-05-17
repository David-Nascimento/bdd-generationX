module Bddgenx
  module Support
    class Loader
      SPINNERS = {
        default: %w[| / - \\],
        dots: %w[⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏]
      }

      def self.run(mensagem = "⏳ Processando...", tipo = :default)
        spinner = SPINNERS[tipo] || SPINNERS[:default]
        done = false

        thread = Thread.new do
          i = 0
          print "\n"
          until done
            print "\r#{mensagem} #{spinner[i % spinner.length]}"
            sleep(0.1)
            i += 1
          end
        end

        result = yield
        done = true
        thread.join
        print "\r#{mensagem} ✅\n"
        result
      end
    end
  end
end
