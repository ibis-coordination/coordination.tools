class CarpoolMailer < ApplicationMailer
  def ride_canceled(user, carpool, driver_name)
    @user = user
    @carpool = carpool
    @driver_name = driver_name
    @carpool_url = carpool_url(carpool)
    mail to: user.email, subject: "Your ride for #{carpool.name} was canceled"
  end
end
