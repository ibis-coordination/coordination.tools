class RidesController < ApplicationController
  include CarpoolBoard

  before_action :require_user
  before_action :set_carpool
  before_action :set_owned_ride, only: %i[edit update]
  before_action :set_removable_ride, only: :destroy

  def create
    @ride = @carpool.rides.new(ride_params.merge(user: current_user))
    if @ride.save
      redirect_to carpool_path(@carpool), notice: @ride.driver? ? "Ride offered." : "Ride request added."
    else
      load_board
      @failed_ride = @ride
      flash.now[:alert] = @ride.errors.full_messages.to_sentence
      render "carpools/show", status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    updated = false
    @carpool.with_lock { updated = @ride.update(ride_params) }
    if updated
      redirect_to carpool_path(@carpool), notice: "Your entry was updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    ride_owner = @ride.user
    displaced = []
    @carpool.with_lock do
      if @ride.driver?
        displaced = @ride.ride_claims.includes(:user).map do |claim|
          { user: claim.user, seats: claim.seats, direction: claim.direction }
        end
        @ride.ride_claims.destroy_all
        displaced.each do |passenger|
          next if @carpool.rides.exists?(user: passenger[:user], direction: passenger[:direction])
          # The repost carries no location: the pickup address was shared with
          # the driver, not the whole board.
          @carpool.rides.create!(
            user: passenger[:user],
            role: "rider",
            direction: passenger[:direction],
            seats: passenger[:seats],
            notes: "The previous ride was canceled."
          )
        end
      end
      @ride.destroy!
    end
    displaced.each do |passenger|
      CarpoolMailer.ride_canceled(passenger[:user], @carpool, ride_owner.name).deliver_later
    end
    CarpoolMailer.entry_removed(ride_owner, @carpool).deliver_later if ride_owner != current_user

    notice = ride_owner == current_user ? "Your entry was removed." : "#{ride_owner.name}'s entry was removed and they were emailed."
    notice += " #{helpers.pluralize(displaced.size, "passenger")} moved to ride requests and emailed." if displaced.any?
    redirect_to carpool_path(@carpool), notice: notice
  end

  private

  def set_carpool = @carpool = Carpool.find_by!(public_id: params[:carpool_public_id])
  def set_owned_ride = @ride = @carpool.rides.find_by!(id: params[:id], user: current_user)

  # Removal is allowed for the entry's owner and for the carpool's organizer
  # (moderation); editing stays owner-only.
  def set_removable_ride
    @ride = @carpool.rides.find_by!(id: params[:id])
    raise ActiveRecord::RecordNotFound unless @ride.user == current_user || @carpool.user == current_user
  end

  def ride_params
    params.require(:ride).permit(:role, :direction, :origin, :departure_time, :seats, :notes)
  end
end
