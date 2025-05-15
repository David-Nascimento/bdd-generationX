module Bddgenx
  class Validator
    def self.validar(historia)
      erros = []

      unless historia[:como] && historia[:quero] && historia[:para]
        erros << "❌ Cabeçalho incompleto (Como, Quero, Para obrigatórios)"
      end

      if historia[:grupos].empty?
        erros << "❌ Nenhum grupo de blocos detectado"
      else
        historia[:grupos].each_with_index do |grupo, idx|
          if grupo[:passos].empty? && grupo[:exemplos].empty?
            erros << "❌ Grupo #{idx + 1} do tipo [#{grupo[:tipo]}] está vazio"
          end

          if grupo[:tipo] == "EXAMPLES" && grupo[:exemplos].none? { |l| l.strip.start_with?('|') }
            erros << "❌ Grupo de EXAMPLES no bloco #{idx + 1} não contém tabela válida"
          end
        end
      end

      if erros.any?
        puts "⚠️  Erros encontrados no arquivo:"
        erros.each { |e| puts "   - #{e}" }
        return false
      end

      true
    end
  end
end
