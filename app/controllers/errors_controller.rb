class ErrorsController < ActionController::Base
  layout false

  STATUS_MESSAGES = {
    "404" => {
      title: "Página não encontrada",
      message: "O endereço informado não existe ou foi removido."
    },
    "422" => {
      title: "Requisição não pôde ser processada",
      message: "Não foi possível concluir a ação. Tente novamente."
    },
    "500" => {
      title: "Erro interno do servidor",
      message: "Ocorreu um erro inesperado ao processar sua solicitação."
    },
    "503" => {
      title: "Serviço temporariamente indisponível",
      message: "Estamos em manutenção ou com instabilidade temporária."
    }
  }.freeze

  def show
    status_code = params[:code].to_s
    status_code = "500" unless STATUS_MESSAGES.key?(status_code)

    @status_code = status_code
    @status_title = STATUS_MESSAGES.dig(status_code, :title)
    @status_message = STATUS_MESSAGES.dig(status_code, :message)

    render status: status_code.to_i
  end
end
