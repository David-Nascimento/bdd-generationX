# spec/support/gherkin_cleaner_spec.rb
require 'spec_helper'
RSpec.describe Bddgenx::GherkinCleaner do
  let(:texto_completo) do
    <<~TXT
      ```gherkin
      # language: en
      Feature: Test feature
        Scenario: Test scenario
          Given something
          When I do this
          Then I expect that
      ```
    TXT
  end

  it 'remove blocos markdown e corrige language e indentação' do
    resultado = described_class.limpar(texto_completo)

    expect(resultado).to start_with('# language:')
    expect(resultado).to include('Feature:')
    expect(resultado).not_to include('```')
    expect(resultado.lines.first).to match(/^# language:/)
    expect(resultado).to include("  Scenario: Test scenario\n")
    expect(resultado).to include("    Given something\n")
  end

  it 'detecta idioma corretamente' do
    expect(described_class.detectar_idioma("Dado algo")).to eq('pt')
    expect(described_class.detectar_idioma("Given something")).to eq('en')
    expect(described_class.detectar_idioma("Texto qualquer")).to eq('pt')
  end
end
