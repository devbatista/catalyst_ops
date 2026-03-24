module Coupons
  class SignupBenefitResolver
    class Result
      attr_reader :coupon, :original_amount, :discount_amount, :final_amount, :errors

      def initialize(success:, coupon:, original_amount:, discount_amount:, final_amount:, errors:)
        @success = success
        @coupon = coupon
        @original_amount = BigDecimal(original_amount.to_s)
        @discount_amount = BigDecimal(discount_amount.to_s)
        @final_amount = BigDecimal(final_amount.to_s)
        @errors = errors
      end

      def success?
        @success
      end

      def coupon_applied?
        coupon.present?
      end

      def trial?
        coupon&.trial? || false
      end

      def zero_cost?
        final_amount.zero?
      end
    end

    def initialize(plan:, coupon_code:, company: nil, payment_method: nil)
      @plan = plan
      @coupon_code = coupon_code.to_s.upcase.strip
      @company = company
      @payment_method = payment_method
    end

    def call
      return failure("Plano inválido.") if plan.blank?

      original_amount = plan.transaction_amount.to_d
      return success(coupon: nil, original_amount: original_amount, discount_amount: 0, final_amount: original_amount) if coupon_code.blank?

      coupon = Coupon.find_by(code: coupon_code)
      return failure("Cupom inválido.") if coupon.blank?
      return failure("Cupom indisponível no momento.") unless coupon.available?
      return failure("Sua empresa já utilizou um cupom nos últimos 12 meses.") if company.present? && !coupon.redeemable_by?(company)

      final_amount = coupon.calculate_final_amount(original_amount)
      return failure("Cupons gratuitos para o primeiro ciclo devem ser cadastrados como cupom de teste.") if final_amount.zero? && !coupon.trial?
      return failure("Cupons de desconto no cartão ainda não são suportados neste fluxo.") if payment_method == "credit_card" && !coupon.trial?

      success(
        coupon: coupon,
        original_amount: original_amount,
        discount_amount: original_amount - final_amount,
        final_amount: final_amount
      )
    end

    private

    attr_reader :plan, :coupon_code, :company, :payment_method

    def success(coupon:, original_amount:, discount_amount:, final_amount:)
      Result.new(
        success: true,
        coupon: coupon,
        original_amount: original_amount,
        discount_amount: discount_amount,
        final_amount: final_amount,
        errors: nil
      )
    end

    def failure(message)
      Result.new(
        success: false,
        coupon: nil,
        original_amount: plan&.transaction_amount.to_d || 0,
        discount_amount: 0,
        final_amount: plan&.transaction_amount.to_d || 0,
        errors: message
      )
    end
  end
end
