require 'xmlrpc/client'

module Bddgenx
    class TestLink
      def initialize(api_key, url)
        @server = XMLRPC::Client.new2(url)
        @key = api_key
      end

      def criar_caso_teste(plan_id, titulo, passos)
        steps_formated = passos.map.with_index(1) do |step, i|
          {
            step_number: i,
            actions: step,
            expected_results: '',
            execution_type: 1
          }
        end

        params = {
          devKey: @key,
          testprojectid: 1,
          testsuiteid: plan_id,
          testcasename: titulo,
          steps: steps_formated
        }

        response = @server.call('tl.createTestCase', params)
        puts "✅ Teste enviado ao TestLink: #{titulo}"
        response
      rescue => e
        puts "❌ Erro ao criar caso no TestLink: #{e.message}"
      end
    end
end
