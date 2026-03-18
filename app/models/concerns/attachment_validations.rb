module AttachmentValidations
  extend ActiveSupport::Concern

  included do
    validates :attachments,
      content_type: [
        'image/png', 'image/jpeg', 'image/jpg', 'image/gif', 'image/bmp', 'image/webp',
        'application/pdf',
        'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        'application/vnd.ms-excel', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        'video/mp4', 'video/quicktime', 'video/x-msvideo', 'video/x-ms-wmv'
      ],
      size: { less_than: 10.megabytes, message: 'deve ter menos de 10MB' },
      limit: { max: 5, message: 'máximo de 5 arquivos por registro' }
  end
end