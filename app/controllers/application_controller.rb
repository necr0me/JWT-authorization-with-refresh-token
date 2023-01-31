class ApplicationController < ActionController::API
  include ActionController::Cookies

  include Authorization
  include ErrorHandler
end
