class ApplicationController < ActionController::Base
  allow_browser versions: :modern
  stale_when_importmap_changes

  helper_method :current_user, :signed_in?

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id])
  end

  def signed_in? = current_user.present?

  def require_user
    return if signed_in?

    session[:return_to] = request.fullpath if request.get?
    redirect_to new_session_path, alert: "Enter your name and email to continue."
  end
end
