# frozen_string_literal: true
module Userable
  extend ActiveSupport::Concern

  included do
    protected

    def user_params
      params.require(:user).permit(:email,
                                   :password)
    end

    def find_user
      @user ||= User.find(params[:id])
    end
  end
end
