module Register::SignupsHelper
  def payment_methods
    (@payment_methods.presence || ['pix', 'credit_card', 'boleto']).map(&:to_s)
  end

  def payment_method_label(method)
    method.to_s == 'credit_card' ? 'Cartão' : method.to_s.capitalize
  end

  def payment_method_icon(method)
    { 
      'pix' => 'bx-money',
      'credit_card' => 'bx-credit-card',
      'boleto' => 'bx-barcode'
    }[method.to_s]
  end
end