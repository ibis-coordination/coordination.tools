class DecisionsController < ApplicationController
  before_action :require_user, only: %i[edit update destroy close]
  before_action :set_decision, only: %i[show]
  before_action :set_owned_decision, only: %i[edit update destroy close]

  def new
    @decision = Decision.new(deadline: 1.week.from_now)
  end

  def create
    return guest_create unless signed_in?

    @decision = current_user.decisions.new(decision_params)
    if @decision.save
      redirect_to decision_path(@decision), notice: "Your decision is ready to share. Add some options next."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @option = DecisionOption.new
    @my_votes = signed_in? ? @decision.decision_votes.where(user: current_user).index_by(&:decision_option_id) : {}
    @has_voted = @my_votes.any?
  end

  def edit; end

  def update
    if @decision.update(decision_params)
      redirect_to decision_path(@decision), notice: "Decision details updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def close
    @decision.update!(closed_at: Time.current, final_statement: params[:final_statement])
    redirect_to decision_path(@decision), notice: "The decision is closed."
  end

  def destroy
    @decision.destroy!
    redirect_to root_path, notice: "The decision was deleted."
  end

  private

  def guest_create
    email = params.dig(:user, :email).to_s.strip.downcase
    @decision = Decision.new(decision_params)

    if (existing = User.find_by(email: email))
      @decision.user = existing
      if @decision.valid?
        session[:pending_decision] = decision_params.to_h
        MagicLinkMailer.sign_in_link(existing).deliver_later
        redirect_to new_decision_path, notice: "We emailed a sign-in link to #{email}. Click it and we'll finish creating your decision."
      else
        @decision.user = nil
        render :new, status: :unprocessable_entity
      end
      return
    end

    user = User.new(name: params.dig(:user, :name), email: email)
    @decision.user = user
    if user.valid? && @decision.valid?
      ActiveRecord::Base.transaction { user.save! && @decision.save! }
      reset_session
      session[:user_id] = user.id
      redirect_to decision_path(@decision), notice: "Signed in as #{user.email}. Your decision is ready to share."
    else
      @guest_user = user
      @decision.user = nil
      render :new, status: :unprocessable_entity
    end
  end

  def set_decision = @decision = Decision.find_by!(public_id: params[:public_id])
  def set_owned_decision = @decision = current_user.decisions.find_by!(public_id: params[:public_id])
  def decision_params = params.require(:decision).permit(:question, :description, :deadline, :options_open)
end
