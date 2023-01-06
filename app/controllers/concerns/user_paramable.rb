module UserParamable
  extend ActiveSupport::Concern

  included do
    private

    def user_params
      params.require(:user).permit(:email, :password)
    end
  end
end
