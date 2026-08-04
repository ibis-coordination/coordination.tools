class CarpoolMailer < ApplicationMailer
  def picked_up(user, carpool, driver_name)
    @user = user
    @carpool = carpool
    @driver_name = driver_name
    @carpool_url = carpool_url(carpool)
    mail to: user.email, subject: "You have a seat in #{driver_name}'s ride for #{carpool.name}"
  end

  def ride_canceled(user, carpool, driver_name)
    @user = user
    @carpool = carpool
    @driver_name = driver_name
    @carpool_url = carpool_url(carpool)
    mail to: user.email, subject: "Your ride for #{carpool.name} was canceled"
  end
end
