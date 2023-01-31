module ErrorHandler
  extend ActiveSupport::Concern

  included do
    rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

    protected

    def record_not_found(e)
      render json: { message: e.message },
             status: 404
    end
  end
end