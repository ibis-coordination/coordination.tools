class HomeController < ApplicationController
  def show
    return unless signed_in?

    involved = Carpool.where(user: current_user)
      .or(Carpool.where(id: current_user.rides.select(:carpool_id)))
      .or(Carpool.where(id: current_user.ride_claims.select(:carpool_id)))
    # Undated carpools haven't happened yet, so they count as upcoming
    # (sorted to the end by Postgres's NULLS LAST default).
    @upcoming_carpools = involved.where("starts_at >= ? OR starts_at IS NULL", Time.current).order(:starts_at)
    @past_carpools = involved.where(starts_at: ...Time.current).order(starts_at: :desc)
  end
end
