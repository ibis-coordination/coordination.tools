class SessionsController < ApplicationController
  def new
    @user = User.new
    store_return_to(params[:return_to])
  end

  def create
    email = session_params[:email].to_s.strip.downcase

    if (existing = User.find_by(email: email))
      # The email is already claimed: prove ownership via magic link instead
      # of handing out a session.
      MagicLinkMailer.sign_in_link(existing).deliver_now
      redirect_to new_session_path, notice: "That email already has an account. We sent a sign-in link to #{email} — click it to continue."
      return
    end

    @user = User.new(name: session_params[:name], email: email)
    if @user.save
      start_session_for @user, notice: "Signed in as #{@user.email}."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def confirm
    user = User.find_by_token_for(:magic_link, params[:token])
    if user
      user.confirm_email!
      start_session_for user, notice: "Signed in as #{user.email}."
    else
      redirect_to new_session_path, alert: "That sign-in link is invalid or has expired. Enter your email to request a new one."
    end
  end

  def destroy
    reset_session
    redirect_to root_path, notice: "Signed out."
  end

  private

  def session_params = params.require(:user).permit(:name, :email)

  def start_session_for(user, notice:)
    return_to = session[:return_to]
    reset_session
    session[:user_id] = user.id
    redirect_to return_to || root_path, notice: notice
  end

  # Only same-origin paths, so a crafted link cannot redirect elsewhere after sign-in.
  def store_return_to(path)
    session[:return_to] = path if path.to_s.match?(%r{\A/(?!/)})
  end
end
