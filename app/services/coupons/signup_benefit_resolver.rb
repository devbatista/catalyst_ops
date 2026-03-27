module Coupons
  class SignupBenefitResolver
    attr_reader :plan, :coupon_code, :company, :payment_method
    
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
      return failure("Cupom inválido.", coupon: nil, rejected: true) if coupon.blank?
      return failure("Cupom indisponível no momento.", coupon: coupon, rejected: true) unless coupon.available?
      return failure("Sua empresa já utilizou um cupom nos últimos 12 meses.", coupon: coupon, rejected: true) if company.present? && !coupon.redeemable_by?(company)

      final_amount = coupon.calculate_final_amount(original_amount)
      return failure("Cupons gratuitos para o primeiro ciclo devem ser cadastrados como cupom de teste.", coupon: coupon, rejected: true) if final_amount.zero? && !coupon.trial?
      return failure("Cupons de desconto no cartão ainda não são suportados neste fluxo.", coupon: coupon, rejected: true) if payment_method == "credit_card" && !coupon.trial?

      success(
        coupon: coupon,
        original_amount: original_amount,
        discount_amount: original_amount - final_amount,
        final_amount: final_amount
      )
    end

    private

    def success(coupon:, original_amount:, discount_amount:, final_amount:)
      Result.new(
        success: true,
        coupon: coupon,
        original_amount: BigDecimal(original_amount.to_s),
        discount_amount: BigDecimal(discount_amount.to_s),
        final_amount: BigDecimal(final_amount.to_s),
        errors: nil
      )
    end

    def failure(message, coupon: nil, rejected: false)
      log_rejected_coupon(coupon: coupon, reason: message) if rejected && coupon_code.present?

      Result.new(
        success: false,
        coupon: coupon,
        original_amount: plan&.transaction_amount.to_d || 0,
        discount_amount: BigDecimal("0"),
        final_amount: plan&.transaction_amount.to_d || 0,
        errors: message
      )
    end

    def log_rejected_coupon(coupon:, reason:)
      Audit::Log.call(
        action: "coupon.rejected",
        resource: coupon,
        metadata: {
          event: "rejected",
          model: self.class.name,
          coupon_code: coupon_code,
          coupon_id: coupon&.id,
          company_id: company&.id,
          plan_id: plan&.id,
          payment_method: payment_method,
          reason: reason,
          action_source: "coupons.signup_benefit_resolver"
        }
      )
    end

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
  end
end
