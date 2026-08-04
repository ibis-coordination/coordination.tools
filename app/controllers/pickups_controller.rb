class PickupsController < ApplicationController
  before_action :require_user

  # A driver accepting a ride request: the rider asked for a seat, so the
  # driver can assign them one directly instead of coordinating out-of-band.
  def create
    @carpool = Carpool.find_by!(public_id: params[:carpool_public_id])
    request_ride = @carpool.rides.where(role: "rider").find(params[:ride_id])
    my_ride = @carpool.rides.find_by!(user: current_user, role: "driver", direction: request_ride.direction)

    @carpool.with_lock do
      my_ride.ride_claims.reload
      if my_ride.available_seats < request_ride.seats
        redirect_to carpool_path(@carpool), alert: "Your ride does not have enough free seats for #{request_ride.user.name}."
        return
      end

      my_ride.ride_claims.create!(
        carpool: @carpool,
        user: request_ride.user,
        pickup_location: request_ride.origin,
        seats: request_ride.seats
      )
      request_ride.destroy!
    end

    CarpoolMailer.picked_up(request_ride.user, @carpool, current_user.name).deliver_later
    redirect_to carpool_path(@carpool), notice: "#{request_ride.user.name} is in your ride now. We emailed them the news."
  end
end
