module CarpoolBoard
  private

  # Everything the board (carpools/show) needs, so failed ride and claim
  # submissions can re-render it with errors in place.
  def load_board
    @drivers = @carpool.rides.where(role: "driver").includes(:user, ride_claims: :user).order(:departure_time, :created_at).group_by(&:direction)
    @riders = @carpool.rides.where(role: "rider").includes(:user).order(:created_at).group_by(&:direction)
    @current_claims = current_user ? @carpool.ride_claims.where(user: current_user).index_by(&:direction) : {}
    @your_rides = current_user ? @carpool.rides.where(user: current_user).index_by(&:direction) : {}
    @pending_offers = current_user ? @carpool.seat_offers.pending.where(user: current_user).index_by(&:ride_id) : {}
    @sent_offers = current_user ? @carpool.seat_offers.where(ride: @carpool.rides.where(user: current_user)).index_by { |o| [ o.ride_id, o.user_id ] } : {}
  end
end
