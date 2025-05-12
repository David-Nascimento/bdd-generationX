module Bddgenx
  class Validator
    TIPOS_CENARIO = %w[
      SUCCESS
      FAILURE
      ERROR
      EXCEPTION
      VALIDATION
      PERMISSION
      EDGE_CASE
      PERFORMANCE
    ]

    def self.validar(historia)
      valido = true

      if historia[:como].to_s.strip.empty? ||
         historia[:quero].to_s.strip.empty? ||
         historia[:para].to_s.strip.empty?
        puts "❌ História incompleta: 'Como', 'Quero' ou 'Para' está faltando."
        valido = false
      end

      cenarios_presentes = historia[:blocos].keys & TIPOS_CENARIO
      valido ||= historia[:blocos]["CONTEXT"]&.any? || historia[:regras]&.any?
      if cenarios_presentes.empty? && !valido
        puts "❌ Nenhum conteúdo válido detectado (cenários, contexto ou regras)."
        return false
      end

      valido
    end
  end
end
