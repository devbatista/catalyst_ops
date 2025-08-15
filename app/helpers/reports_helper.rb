module ReportsHelper
  def available_report_categories
    categories = {
      'Operacional' => [
        { 
          name: 'Ordens de Serviço por Período e Status',
          path: service_orders_app_reports_path,
          description: 'Visualize ordens de serviço filtrando por data e status.'
        }
        # { name: 'Outro Relatório Operacional', path: '#', description: 'Descrição do outro relatório.' }
      ],
      'Financeiro' => [
        { 
          name: 'Relatório de Faturamento (Exemplo)', 
          path: '#', # Trocar pelo caminho real quando for criado
          description: 'Acompanhe o faturamento por período.' 
        }
        # Adicione relatórios financeiros aqui quando estiverem prontos
      ],
      'Clientes' => [
        # Adicione relatórios de clientes aqui
      ]
    }

    categories.reject { |_categories, reports| reports.empty? }
  end
end