require_relative 'lib/bddgenx/gherkin_cleaner'

texto_gerado = <<~TEXT
  ```gherkin
  # language: en
  Feature: Exemplo de cadastro
  Scenario: Usuário realiza cadastro
  Given o usuário acessa a página de cadastro
  When ele preenche os dados corretamente
  Then o cadastro é realizado com sucesso
TEXT

puts "Texto original:"
puts texto_gerado
puts "------"

texto_limpo = Bddgenx::GherkinCleaner.limpar(texto_gerado)

puts "Texto limpo e formatado:"
puts texto_limpo


