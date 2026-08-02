class AccountsController < ApplicationController
  before_action :require_user

  def edit; end

  def update
    unless current_user.email_confirmed?
      redirect_to edit_account_path, alert: "Confirm your email with a sign-in link before editing your name."
      return
    end

    if current_user.update(account_params)
      redirect_to edit_account_path, notice: "Name updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def account_params = params.require(:user).permit(:name)
end
