require 'spec_helper'

RSpec.describe Bddgenx::IA::ChatGptCliente do
  before do
    stub_const("ENV", ENV.to_hash.merge("OPENAI_API_KEY" => "fake_key"))
  end

  it 'retorna texto limpo da IA' do
    resposta_ia = {
      choices: [
        { message: { content: "# language: pt\nFeature: Exemplo\nScenario: Cenário de teste\nGiven algo" } }
      ]
    }.to_json

    stub_request(:post, Bddgenx::IA::ChatGptCliente::CHATGPT_API_URL)
      .to_return(status: 200, body: resposta_ia, headers: { 'Content-Type' => 'application/json' })

    resultado = described_class.gerar_cenarios("História de exemplo", "pt")
    expect(resultado).to include('Feature:')
    expect(resultado).to start_with("# language: pt")
  end

  it 'chama fallback com Gemini quando chave não existe' do
    stub_const("ENV", ENV.to_hash.reject { |k| k == "OPENAI_API_KEY" })

    expect(described_class).to receive(:fallback_com_gemini).with("História de exemplo", "pt")
    described_class.gerar_cenarios("História de exemplo", "pt")
  end
end
