class SeatOffersController < ApplicationController
  before_action :require_user
  before_action :set_carpool

  # A driver inviting a rider: nothing is committed until the rider accepts,
  # so the person getting into the car always chooses whose car it is.
  def create
    request_ride = @carpool.rides.where(role: "rider").find(params[:ride_id])
    my_ride = @carpool.rides.find_by!(user: current_user, role: "driver", direction: request_ride.direction)

    offer = SeatOffer.new(carpool: @carpool, ride: my_ride, user: request_ride.user)
    if offer.save
      CarpoolMailer.seat_offer(offer).deliver_later
      redirect_to carpool_path(@carpool), notice: "Offer sent. #{request_ride.user.name} has been emailed and can accept or decline."
    else
      redirect_to carpool_path(@carpool), alert: "You have already offered #{request_ride.user.name} a seat."
    end
  end

  def accept
    offer = @carpool.seat_offers.pending.where(user: current_user).find(params[:id])
    ride = offer.ride
    request_ride = @carpool.rides.find_by(user: current_user, role: "rider", direction: ride.direction)
    seats = request_ride&.seats || 1

    @carpool.with_lock do
      ride.ride_claims.reload
      if ride.available_seats < seats
        redirect_to carpool_path(@carpool), alert: "#{ride.user.name}'s ride no longer has enough free seats. The offer remains open."
        return
      end

      ride.ride_claims.create!(
        carpool: @carpool,
        user: current_user,
        pickup_location: request_ride&.origin,
        seats: seats
      )
      @carpool.rides.where(user: current_user, role: "rider", direction: ride.direction).destroy_all
      @carpool.seat_offers.where(user: current_user).where(ride: @carpool.rides.where(direction: ride.direction)).destroy_all
    end

    CarpoolMailer.offer_accepted(ride.user, @carpool, current_user.name).deliver_later
    redirect_to carpool_path(@carpool), notice: "You're in #{ride.user.name}'s ride."
  end

  def decline
    offer = @carpool.seat_offers.pending.where(user: current_user).find(params[:id])
    offer.update!(declined_at: Time.current)
    redirect_to carpool_path(@carpool), notice: "Offer declined."
  end

  private

  def set_carpool = @carpool = Carpool.find_by!(public_id: params[:carpool_public_id])
end
