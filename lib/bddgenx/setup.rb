#!/usr/bin/env ruby
module Bddgenx
  class Setup
    def self.inicializar_projeto
      puts "🔧 Configurando ambiente do projeto BddGenX..."

      # Cria .env a partir do exemplo
      if File.exist?(".env")
        puts "✅ .env já existe. Nada a fazer."
      else
        if File.exist?(".env.example")
          FileUtils.cp(".env.example", ".env")
          puts "✅ .env criado a partir de .env.example"
        else
          puts "⚠️ Arquivo .env.example não encontrado. Crie manualmente o .env"
        end
      end

      # Garante existência do diretório de input
      FileUtils.mkdir_p("input")
      puts "📂 Pasta input criada (se necessário)."

      puts "\n✅ Setup completo! Agora edite o arquivo `.env` e adicione suas chaves de API."
    end
  end
end