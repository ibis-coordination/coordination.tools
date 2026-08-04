class HomeController < ApplicationController
  def show
    return unless signed_in?

    involved = Carpool.where(user: current_user)
      .or(Carpool.where(id: current_user.rides.select(:carpool_id)))
      .or(Carpool.where(id: current_user.ride_claims.select(:carpool_id)))
    @upcoming_carpools = involved.where(starts_at: Time.current..).order(:starts_at)
    @past_carpools = involved.where(starts_at: ...Time.current).order(starts_at: :desc)
  end
end
