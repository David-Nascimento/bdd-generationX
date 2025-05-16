# lib/bddgenx/validator.rb
# encoding: utf-8
#
# Este arquivo define a classe Validator, responsável por validar a estrutura
# de uma história antes de gerar cenários ou arquivos .feature.
# Verifica presença de cabeçalho obrigatório e integridade dos grupos de passos.

module Bddgenx
  # Valida objetos de história garantindo que possuam campos e blocos corretos.
  class Validator
    # Valida o hash de história fornecido.
    #
    # Verifica:
    # - Presença das chaves :como, :quero, :para no cabeçalho
    # - Presença de pelo menos um grupo em :grupos
    # - Cada grupo deve ter ao menos passos ou exemplos
    # - Grupos do tipo "EXAMPLES" devem conter uma tabela de exemplos válida
    #
    # @param historia [Hash] Objeto de história com chaves :como, :quero, :para e :grupos
    # @return [Boolean] Retorna true se a história for válida; caso contrário, false
    def self.validar(historia)
      erros = []

      # Verificação do cabeçalho obrigatório
      unless historia[:como] && historia[:quero] && historia[:para]
        erros << "❌ Cabeçalho incompleto (Como, Quero, Para obrigatórios)"
      end

      # Verificação de grupos de passos
      if historia[:grupos].nil? || historia[:grupos].empty?
        erros << "❌ Nenhum grupo de blocos detectado"
      else
        historia[:grupos].each_with_index do |grupo, idx|
          # Cada grupo deve conter passos ou exemplos
          if (grupo[:passos].nil? || grupo[:passos].empty?) &&
             (grupo[:exemplos].nil? || grupo[:exemplos].empty?)
            erros << "❌ Grupo #{idx + 1} do tipo [#{grupo[:tipo]}] está vazio"
          end

          # Validação específica para blocos de exemplos
          if grupo[:tipo].casecmp('EXAMPLES').zero? &&
             grupo[:exemplos].none? { |l| l.strip.start_with?('|') }
            erros << "❌ Grupo de EXAMPLES no bloco #{idx + 1} não contém tabela válida"
          end
        end
      end

      # Exibe erros e retorna false se houver falhas
      if erros.any?
        puts "⚠️  Erros encontrados no arquivo:"
        erros.each { |e| puts "   - #{e}" }
        return false
      end

      # História válida
      true
    end
  end
end
