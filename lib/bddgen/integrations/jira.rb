require 'jira-ruby'

module Bddgen
  module Integrations
    class Jira
      def initialize(options = {})
        @client = JIRA::Client.new(
          username: options[:username],
          password: options[:api_token],
          site: options[:site],
          context_path: '',
          auth_type: :basic
        )
        @project_key = options[:project_key]
      end

      def enviar_cenario(titulo, descricao)
        issue = {
          fields: {
            project: { key: @project_key },
            summary: titulo,
            description: descricao,
            issuetype: { name: "Task" }
          }
        }

        @client.Issue.build.save(issue)
        puts "✅ Cenário enviado para Jira: #{titulo}"
      end
    end
  end
end
