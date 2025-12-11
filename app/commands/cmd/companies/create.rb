module Cmd
  module Companies
    class Create
      Result = Struct.new(:success?, :company, :errors)

      def initialize(company)
        @company = company
      end

      def call
        if @company.valid?
          ActiveRecord::Base.transaction do
            @company.save!
            Result.new(true, @company, nil)
          end
        else
          Result.new(false, @company, @company.errors.full_messages)
        end
      rescue ActiveRecord::RecordInvalid => e
        Result.new(false, @company, @company.errors.full_messages.presence || [e.message])
      end
    end
  end
end