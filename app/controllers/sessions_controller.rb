class SessionsController < ApplicationController
  def new
    @user = User.new
    store_return_to(params[:return_to])
  end

  def create
    email = session_params[:email].to_s.strip.downcase
    @user = User.find_or_initialize_by(email: email)
    @user.name = session_params[:name] if @user.new_record?

    if @user.save
      return_to = session[:return_to]
      reset_session
      session[:user_id] = @user.id
      redirect_to return_to || root_path, notice: "Signed in as #{@user.email}."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    reset_session
    redirect_to root_path, notice: "Signed out."
  end

  private

  def session_params = params.require(:user).permit(:name, :email)

  # Only same-origin paths, so a crafted link cannot redirect elsewhere after sign-in.
  def store_return_to(path)
    session[:return_to] = path if path.to_s.match?(%r{\A/(?!/)})
  end
end
