class AccountsController < ApplicationController
  before_action :require_user, except: :confirm_email

  def edit; end

  def update
    return initiate_email_change if account_params[:email].present?

    unless current_user.email_confirmed?
      redirect_to edit_account_path, alert: "Confirm your email with a sign-in link before editing your name."
      return
    end

    if current_user.update(account_params.slice(:name))
      redirect_to edit_account_path, notice: "Name updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # Reached from the link emailed to the new address; proves control of it.
  def confirm_email
    user = User.find_by_token_for(:email_change, params[:token])
    if user&.pending_email
      user.update!(email: user.pending_email, pending_email: nil, email_confirmed_at: Time.current)
      reset_session
      session[:user_id] = user.id
      redirect_to edit_account_path, notice: "Your email is now #{user.email}."
    else
      redirect_to root_path, alert: "That confirmation link is invalid or has expired. You can request a new one from your account page."
    end
  rescue ActiveRecord::RecordInvalid
    redirect_to root_path, alert: "That email address is no longer available."
  end

  private

  def initiate_email_change
    new_email = account_params[:email].to_s.strip.downcase

    if new_email == current_user.email
      redirect_to edit_account_path, notice: "#{new_email} is already your email address."
    elsif User.where.not(id: current_user.id).exists?(email: new_email)
      redirect_to edit_account_path, alert: "That email address is already in use by another account."
    elsif !URI::MailTo::EMAIL_REGEXP.match?(new_email)
      redirect_to edit_account_path, alert: "That doesn't look like an email address."
    else
      current_user.update!(pending_email: new_email)
      MagicLinkMailer.email_change(current_user).deliver_later
      redirect_to edit_account_path, notice: "We sent a confirmation link to #{new_email}. Your email won't change until you click it."
    end
  end

  def account_params = params.require(:user).permit(:name, :email)
end
