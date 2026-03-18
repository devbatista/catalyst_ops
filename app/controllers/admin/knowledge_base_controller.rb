class Admin::KnowledgeBaseController < AdminController
  def index
    @articles = KnowledgeBaseArticle.order(:category, :title)
  end
end
