class CarpoolsController < ApplicationController
  include CarpoolBoard

  before_action :require_user, only: %i[edit update destroy]
  before_action :set_owned_carpool, only: %i[edit update destroy]
  def new
    @carpool = Carpool.new(starts_at: 1.week.from_now.change(min: 0))
  end

  def create
    return guest_create unless signed_in?

    @carpool = current_user.carpools.new(carpool_params)
    if @carpool.save
      redirect_to carpool_path(@carpool), notice: "Your carpool is ready to share."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @carpool.update(carpool_params)
      redirect_to carpool_path(@carpool), notice: "Carpool details updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @carpool.destroy!
    redirect_to root_path, notice: "The #{@carpool.name} carpool was deleted."
  end

  def show
    @carpool = Carpool.find_by!(public_id: params[:public_id])
    load_board
  end

  private

  # Signed-out visitors fill in the carpool and their name/email in one form,
  # instead of bouncing through a sign-up interstitial first.
  def guest_create
    email = params.dig(:user, :email).to_s.strip.downcase
    @carpool = Carpool.new(carpool_params)

    if (existing = User.find_by(email: email))
      @carpool.user = existing
      if @carpool.valid?
        # Prove ownership of the email first; the carpool is created right
        # after the magic link is clicked (see SessionsController).
        session[:pending_carpool] = carpool_params.to_h
        MagicLinkMailer.sign_in_link(existing).deliver_later
        redirect_to new_carpool_path, notice: "We emailed a sign-in link to #{email}. Click it and we'll finish creating your carpool."
      else
        @carpool.user = nil
        render :new, status: :unprocessable_entity
      end
      return
    end

    user = User.new(name: params.dig(:user, :name), email: email)
    @carpool.user = user
    if user.valid? && @carpool.valid?
      ActiveRecord::Base.transaction { user.save! && @carpool.save! }
      reset_session
      session[:user_id] = user.id
      redirect_to carpool_path(@carpool), notice: "Signed in as #{user.email}. Your carpool is ready to share."
    else
      @guest_user = user
      @carpool.user = nil
      render :new, status: :unprocessable_entity
    end
  end

  def set_owned_carpool
    @carpool = current_user.carpools.find_by!(public_id: params[:public_id])
  end

  def carpool_params
    params.require(:carpool).permit(:name, :destination, :starts_at, :return_starts_at, :details)
  end
end
