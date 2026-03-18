require 'redcarpet'

markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)

KnowledgeBaseArticle.delete_all

Dir.glob(Rails.root.join('docs/gestor/*/*.md')).each do |file_path|
  content_md = File.read(file_path)
  content_html = markdown.render(content_md)

  title = content_md[/^#\s*(.+)/, 1] || File.basename(file_path, File.extname(file_path)).humanize
  category = file_path.split('/gestor/').last.split('/').first.titleize

  KnowledgeBaseArticle.create!(
    title: title,
    category: category,
    content: content_html
  )
end