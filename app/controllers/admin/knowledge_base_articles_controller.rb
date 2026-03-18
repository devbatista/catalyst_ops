class Admin::KnowledgeBaseArticlesController < AdminController
  before_action :set_knowledge_base_article, only: [:show, :edit, :update, :destroy]

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
  end

  def new
    @knowledge_base_article = KnowledgeBaseArticle.new
    @all_categories = KnowledgeBaseArticle.distinct.order(:category).pluck(:category).compact
  end

  def edit
    @all_categories = KnowledgeBaseArticle.distinct.order(:category).pluck(:category).compact
  end

  def create
    @knowledge_base_article = KnowledgeBaseArticle.new(knowledge_base_article_params)

    if @knowledge_base_article.save
      redirect_to admin_knowledge_base_index_path, notice: "Artigo criado com sucesso."
    else
      @all_categories = KnowledgeBaseArticle.distinct.order(:category).pluck(:category).compact
      render :new
    end
  end

  def update
    if @knowledge_base_article.update(knowledge_base_article_params)
      redirect_to admin_knowledge_base_path(@knowledge_base_article), notice: "Artigo atualizado com sucesso."
    else
      @all_categories = KnowledgeBaseArticle.distinct.order(:category).pluck(:category).compact
      render :edit
    end
  end

  def destroy
    if @knowledge_base_article.destroy
      redirect_to admin_knowledge_base_index_path, notice: "Artigo excluído com sucesso."
    else
      redirect_to admin_knowledge_base_index_path, alert: "Não foi possível excluir o artigo."
    end
  end
  
  private

  def set_knowledge_base_article
    @knowledge_base_article = KnowledgeBaseArticle.find(params[:id])
  end

  def knowledge_base_article_params
    params.require(:knowledge_base_article).permit(:title, :content, :category)
  end
end
