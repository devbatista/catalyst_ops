class App::KnowledgeBaseController < ApplicationController
  def index
    authorize! :read, :knowledge_base

    @articles = KnowledgeBaseArticle
      .for_audience(current_user.role)
      .order(:category, :title)
  end
end
