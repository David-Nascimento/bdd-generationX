# spec/utils/step_cleaner_spec.rb
require 'spec_helper'

RSpec.describe Bddgenx::Utils::StepCleaner do
  let(:texto_com_steps_duplicados) do
    <<~TXT
      Dado que eu tenho o numero "12"
      E informo mais 20
      Então meu resultado é <resultado>
      Exemplos:
        | resultado         |
        | 32                |
        | 43                |
    TXT
  end

  it 'remove steps duplicados corretamente no idioma en' do
    resultado = described_class.remover_steps_duplicados(texto_com_steps_duplicados, 'en')
    linhas = resultado.lines.select { |l| l.strip != '' }
    expect(linhas.count { |l| l.start_with?('Dado') }).to eq(1)
    expect(linhas.count { |l| l.start_with?('Então') }).to eq(1)
  end

  it 'canonicalize_step generaliza parâmetros e ignora maiúsculas e acentos' do
    step1 = 'Given Eu tenho 5 maças'
    step2 = 'Given Eu tenho "5" maças'
    canonical1 = described_class.canonicalize_step(step1, %w[Dado Quando Então E])
    canonical2 = described_class.canonicalize_step(step2, %w[Dado Quando Então E])
    expect(canonical1).to eq(canonical2)
  end
end
