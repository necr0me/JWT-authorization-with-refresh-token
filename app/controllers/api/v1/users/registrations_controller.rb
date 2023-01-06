class Api::V1::Users::RegistrationsController < ApplicationController
  include UserFindable
  include UserParamable

  before_action :find_user, :authorize!,
                only: :destroy

  def create
    @user = User.create(user_params)
    if @user.errors.empty?
      render json: { message: 'You have successfully registered'}, status: 200
    else
      render json: { message: 'Something went wrong', errors: @user.errors}, status: 422
    end
  end

  def destroy
    @user.destroy
    head 204
  end

end
