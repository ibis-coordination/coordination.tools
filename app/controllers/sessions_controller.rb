class SessionsController < ApplicationController
  def new
    @user = User.new
    store_return_to(params[:return_to])
  end

  def create
    email = session_params[:email].to_s.strip.downcase

    # A signed-in user re-submitting their own email is confirming it (from
    # the account page), not signing in again.
    if signed_in? && current_user.email == email
      deliver_magic_link(current_user, return_to: edit_account_path)
      redirect_to edit_account_path, notice: "We emailed a sign-in link to #{email}. Click it to confirm your address."
      return
    end

    if (existing = User.find_by(email: email))
      # The email is already claimed: prove ownership via magic link instead
      # of handing out a session.
      deliver_magic_link(existing, return_to: session[:return_to])
      redirect_to new_session_path, notice: "We emailed a sign-in link to #{email}. Click it to continue."
      return
    end

    @user = User.new(name: session_params[:name], email: email)

    # Email-first: a new email gets asked for a name as a second step rather
    # than failing validation on a field that was never shown.
    if session_params[:name].blank?
      @user.validate
      @ask_name = @user.errors[:email].none?
      render :new, status: :unprocessable_entity
      return
    end

    if @user.save
      start_session_for @user, notice: "Signed in as #{@user.email}."
    else
      @ask_name = @user.errors[:email].none?
      render :new, status: :unprocessable_entity
    end
  end

  def confirm
    user = User.find_by_token_for(:magic_link, params[:token])
    if user
      user.confirm_email!
      store_return_to(params[:return_to])
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

  # The return path rides along in the emailed link because the link is often
  # opened in a different browser (a phone's mail app), where this session's
  # return_to does not exist.
  def deliver_magic_link(user, return_to:)
    MagicLinkMailer.sign_in_link(user, return_to: same_origin_path(return_to)).deliver_later
  end

  def start_session_for(user, notice:)
    return_to = session[:return_to]
    pending_carpool = session[:pending_carpool]
    pending_decision = session[:pending_decision]
    reset_session
    session[:user_id] = user.id

    # A guest who filled in the create-carpool form gets their carpool now
    # that the magic link proved the email is theirs.
    if pending_carpool
      carpool = user.carpools.new(pending_carpool)
      if carpool.save
        redirect_to carpool_path(carpool), notice: "#{notice} Your carpool is ready to share."
        return
      end
    end

    if pending_decision
      decision = user.decisions.new(pending_decision)
      if decision.save
        redirect_to decision_path(decision), notice: "#{notice} Your decision is ready to share."
        return
      end
    end

    redirect_to return_to || root_path, notice: notice
  end

  def store_return_to(path)
    session[:return_to] = path if same_origin_path(path)
  end

  # Only same-origin paths, so a crafted link cannot redirect elsewhere after sign-in.
  def same_origin_path(path)
    path.to_s.match?(%r{\A/(?!/)}) ? path : nil
  end
end
