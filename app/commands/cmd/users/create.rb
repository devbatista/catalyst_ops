module Cmd
  module Users
    class Create
      Result = Struct.new(:success?, :user, :errors)

      def initialize(user)
        @user = user
      end

      def call
        if @user.valid?
          ActiveRecord::Base.transaction do
            @user.save!
            Result.new(true, @user, nil)
          end
        else
          Result.new(false, @user, @user.errors.full_messages)
        end
      rescue ActiveRecord::RecordInvalid => e
        Result.new(false, @user, @user.errors.full_messages.presence || [e.message])
      end
    end
  end
end