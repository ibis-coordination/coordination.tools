class RideClaimsController < ApplicationController
  include CarpoolBoard

  before_action :require_user
  before_action :set_carpool_and_ride
  before_action :reject_drivers, only: :create

  def create
    @ride_claim = @ride.ride_claims.new(ride_claim_params.merge(user: current_user, carpool: @carpool))

    @carpool.with_lock do
      @ride.ride_claims.reload
      if @ride.available_seats < @ride_claim.seats
        redirect_to carpool_path(@carpool), alert: "This ride does not have enough seats."
        return
      end

      @carpool.ride_claims.where(user: current_user, direction: @ride.direction).destroy_all
      @carpool.rides.where(user: current_user, role: "rider", direction: @ride.direction).destroy_all
      @ride_claim.save!
    end

    redirect_to carpool_path(@carpool), notice: "You joined #{@ride.user.name}'s ride."
  rescue ActiveRecord::RecordInvalid
    load_board
    @claim_ride = @ride
    flash.now[:alert] = @ride_claim.errors.full_messages.to_sentence
    render "carpools/show", status: :unprocessable_entity
  end

  # The arrangement can be ended by the passenger, the driver, or the
  # organizer (moderation). Leaving on your own posts nothing in your name;
  # being removed reposts your request — without the pickup address, which
  # was shared with the driver, not the whole board.
  def destroy
    claim = @ride.ride_claims.find_by!(id: params[:id])
    authorized = [ claim.user, @ride.user, @carpool.user ].include?(current_user)
    raise ActiveRecord::RecordNotFound unless authorized

    passenger = claim.user
    @carpool.with_lock do
      seats = claim.seats
      direction = claim.direction
      claim.destroy!
      if passenger != current_user && !@carpool.rides.exists?(user: passenger, direction: direction)
        @carpool.rides.create!(
          user: passenger,
          role: "rider",
          direction: direction,
          seats: seats,
          notes: "Previously assigned to a ride."
        )
      end
    end

    if passenger == current_user
      notice = "You left #{@ride.user.name}'s ride. If you still need a seat, you can post a new ride request."
    else
      CarpoolMailer.removed_from_ride(passenger, @carpool, @ride.user.name).deliver_later
      notice = "#{passenger.name} was moved back to ride requests and emailed."
    end
    redirect_to carpool_path(@carpool), notice: notice
  end

  private

  def set_carpool_and_ride
    @carpool = Carpool.find_by!(public_id: params[:carpool_public_id])
    @ride = @carpool.rides.where(role: "driver").find(params[:ride_id])
  end

  def ride_claim_params = params.require(:ride_claim).permit(:pickup_location, :seats)

  def reject_drivers
    redirect_to carpool_path(@carpool), alert: "Remove your driver entry before joining another ride." if @carpool.rides.exists?(user: current_user, role: "driver", direction: @ride.direction)
  end
end
