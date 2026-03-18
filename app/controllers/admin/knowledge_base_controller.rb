class Admin::KnowledgeBaseController < AdminController
  def index
    @all_categories = KnowledgeBaseArticle.distinct.order(:category).pluck(:category).compact

    @articles = KnowledgeBaseArticle.order(:category, :title)
    if params[:category].present?
      @articles = @articles.where(category: params[:category])
    end

    if params[:q].present?
      q = "%#{params[:q]}%"
      @articles = @articles.where("title ILIKE ? OR content ILIKE ?", q, q)
    end
  end

  def show
    @article = KnowledgeBaseArticle.find(params[:id])
  end

  def new
    @knowledge_base_article = KnowledgeBaseArticle.new
    @all_categories = KnowledgeBaseArticle.distinct.order(:category).pluck(:category).compact
  end

  def edit
    @knowledge_base_article = KnowledgeBaseArticle.find(params[:id])
    @all_categories = KnowledgeBaseArticle.distinct.order(:category).pluck(:category).compact
  end
end
