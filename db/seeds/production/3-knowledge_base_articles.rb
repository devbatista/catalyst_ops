require "redcarpet"

puts "Criando os artigos da base de conhecimento..."

markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)

KnowledgeBaseArticle.delete_all

{
  "gestor" => Rails.root.join("docs/gestor/*/*.md"),
  "tecnico" => Rails.root.join("docs/tecnico/*/*.md"),
}.each do |audience, pattern|
  Dir.glob(pattern).each do |file_path|
    content_md = File.read(file_path)
    content_html = markdown.render(content_md)

    title = content_md[/^#\s*(.+)/, 1] || File.basename(file_path, File.extname(file_path)).humanize
    category = file_path.split("/#{audience}/").last.split("/").first.titleize

    KnowledgeBaseArticle.create!(
      title: title,
      category: category,
      content: content_html,
      audience: audience,
    )
  end
end

puts "Artigos da base de conhecimento criados..."
puts "###################################"