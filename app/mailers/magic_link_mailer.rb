class MagicLinkMailer < ApplicationMailer
  def sign_in_link(user, return_to: nil)
    @user = user
    @confirm_url = confirm_session_url(token: user.generate_token_for(:magic_link), return_to: return_to.presence)
    mail to: user.email, subject: "Your sign-in link for coordination.tools"
  end
end
