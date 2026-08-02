class CarpoolsController < ApplicationController
  before_action :require_user, except: :show
  before_action :set_owned_carpool, only: %i[edit update]
  def new
    @carpool = Carpool.new(starts_at: 1.week.from_now.change(min: 0))
  end

  def create
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

  def show
    @carpool = Carpool.find_by!(public_id: params[:public_id])
    @drivers = @carpool.rides.where(role: "driver").includes(:ride_claims).order(:departure_time, :created_at).group_by(&:direction)
    @riders = @carpool.rides.where(role: "rider").order(:created_at).group_by(&:direction)
    direction = params[:direction].presence_in(%w[outbound return]) || "outbound"
    direction = "outbound" if direction == "return" && @carpool.return_starts_at.blank?
    @ride = @carpool.rides.new(role: params[:role].presence_in(%w[driver rider]) || "driver", direction: direction)
    @current_claims = current_user ? @carpool.ride_claims.where(user: current_user).index_by(&:direction) : {}
    if params[:join_ride].present?
      @join_ride = @carpool.rides.where(role: "driver").find(params[:join_ride])
      @current_claim = @current_claims[@join_ride.direction]
      @ride_claim = @join_ride.ride_claims.new(
        pickup_location: @current_claim&.pickup_location,
        seats: @current_claim&.seats || 1
      )
    end
  end

  private

  def set_owned_carpool
    @carpool = current_user.carpools.find_by!(public_id: params[:public_id])
  end

  def carpool_params
    params.require(:carpool).permit(:name, :destination, :starts_at, :return_starts_at, :details)
  end
end
