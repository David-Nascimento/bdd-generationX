require_relative '../lib/bddgenx/support/gherkin_cleaner'

RSpec.describe Bddgenx::GherkinCleaner do
  let(:texto_com_markdown) do
    <<~TEXT
      ```gherkin
        Feature: Exemplo
        Scenario: Cenário simples
        Given uma pré-condição
        When uma ação é executada
        Then o resultado esperado ocorre
        ```
    TEXT
  end

  let(:texto_com_duplicacao_language) do
    <<~TEXT
      # language: pt
      Feature: Exemplo
      # language: en
      Scenario: Cenário simples
      Given uma pré-condição
      ```
    TEXT
  end

  it 'remove blocos markdown corretamente' do
    resultado = described_class.remover_blocos_markdown(texto_com_markdown)
    expect(resultado).not_to include('```')
  end

  it 'remove linhas duplicadas de language mantendo a primeira' do
    resultado = described_class.corrigir_language(texto_com_duplicacao_language)
    expect(resultado.scan(/^# language:/).size).to eq(1)
    expect(resultado).to start_with('# language: pt')
  end

  it 'detecta idioma pt corretamente' do
    texto = "Dado que o usuário está logado"
    expect(described_class.detectar_idioma(texto)).to eq('pt')
  end

  it 'detecta idioma en corretamente' do
    texto = "Given the user is logged in"
    expect(described_class.detectar_idioma(texto)).to eq('en')
  end

  it 'corrige indentação conforme padrão Gherkin' do
    texto = <<~TEXT
      Feature: Exemplo
      Scenario: Cenário
      Given algo
      | coluna1 | coluna2 |
    TEXT

    esperado = <<~TEXT
      Feature: Exemplo
        Scenario: Cenário
          Given algo
            | coluna1 | coluna2 |
    TEXT

    expect(described_class.corrigir_indentacao(texto)).to eq(esperado)
  end

  it 'faz limpeza completa no texto' do
    texto = <<~TEXT
      ```gherkin
      # language: en
      Feature: Teste
      Scenario: Cenário
      Given algo
      ```
    TEXT

    resultado = described_class.limpar(texto)
    expect(resultado).to start_with('# language: en')
    expect(resultado).not_to include('```')
  end
end