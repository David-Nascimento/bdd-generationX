require 'jira-ruby'

module Bddgenx
  class JiraClient
    # Configuração do JIRA, baseada em variáveis de ambiente
    JIRA_OPTIONS = {
      username:     ENV['JIRA_USER'],
      password:     ENV['JIRA_API_TOKEN'],
      site:         ENV['JIRA_SITE'],            # Ex: https://meujira.atlassian.net
      context_path: '',
      auth_type:    :basic,
      read_timeout: 120
    }.freeze

    # Chave do projeto onde serão criadas as issues
    PROJECT_KEY = ENV['JIRA_PROJECT_KEY'] || 'PROJ'
    # Tipo de issue para features e testes
    ISSUE_TYPE_FEATURE = 'Task'
    ISSUE_TYPE_TEST    = 'Test'

    def initialize
      @client = JIRA::Client.new(JIRA_OPTIONS)
    end

    # Cria uma task no Jira com o conteúdo da feature e anexa o PDF do relatório
    # @param feature_path [String] caminho para o arquivo .feature
    # @param pdf_path [String] caminho para o arquivo .pdf
    # @return [JIRA::Resource::Issue] issue criada
    def create_feature_task(feature_path, pdf_path)
      feature_summary = "BDD Feature: #{File.basename(feature_path)}"
      feature_description = File.read(feature_path)

      issue_fields = {
        'fields' => {
          'project'     => { 'key' => PROJECT_KEY },
          'summary'     => feature_summary,
          'description' => "h2. Feature Definition\n{code}#{feature_description}{code}",
          'issuetype'   => { 'name' => ISSUE_TYPE_FEATURE }
        }
      }

      issue = @client.Issue.build.save(issue_fields) ? @client.Issue.find(issue_fields['fields']['project']['key'] + '-' + @client.Issue.build.id) : nil
      raise 'Erro ao criar issue de feature' unless issue

      # Anexa o PDF se existir
      if File.exist?(pdf_path)
        issue.attachments.build.save(file: File.new(pdf_path))
      end

      issue
    end

    # Cria um caso de teste no Test Management (Test issue) baseado em um cenário
    # @param scenario_name [String] nome do cenário de teste
    # @param scenario_steps [Array<String>] lista de passos do cenário
    # @return [JIRA::Resource::Issue] issue criada
    def create_test_case(scenario_name, scenario_steps)
      test_summary = "Test Case: #{scenario_name}"
      test_description = scenario_steps.map.with_index(1) { |step, i| "#{i}. #{step}" }.join("\n")

      test_fields = {
        'fields' => {
          'project'     => { 'key' => PROJECT_KEY },
          'summary'     => test_summary,
          'description' => test_description,
          'issuetype'   => { 'name' => ISSUE_TYPE_TEST }
        }
      }

      test_issue = @client.Issue.build.save(test_fields) ? @client.Issue.find(test_fields['fields']['project']['key'] + '-' + @client.Issue.build.id) : nil
      raise 'Erro ao criar caso de teste' unless test_issue
      test_issue
    end
  end
end
