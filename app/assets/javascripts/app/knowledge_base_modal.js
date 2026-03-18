document.addEventListener('DOMContentLoaded', function() {
  document.querySelectorAll('.js-knowledge-base-article').forEach(function(link) {
    link.addEventListener('click', function(e) {
      e.preventDefault();
      const title = this.dataset.articleTitle;
      const content = this.dataset.articleContent;
      document.getElementById('knowledgeBaseModalLabel').textContent = title;
      document.getElementById('knowledgeBaseModalBody').innerHTML = content;
      // Use sempre a API do Bootstrap para abrir o modal
      const modal = new bootstrap.Modal(document.getElementById('knowledgeBaseModal'));
      modal.show();
    });
  });
});