module UserFindable
  extend ActiveSupport::Concern

  included do
    private

    def find_user
      @user ||= User.find(params[:id])
    end
  end
end
