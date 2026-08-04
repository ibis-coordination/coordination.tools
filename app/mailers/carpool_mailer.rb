class CarpoolMailer < ApplicationMailer
  def seat_offer(offer)
    @user = offer.user
    @carpool = offer.carpool
    @driver_name = offer.ride.user.name
    @carpool_url = carpool_url(@carpool)
    mail to: @user.email, subject: "#{@driver_name} offered you a seat for #{@carpool.name}"
  end

  def offer_accepted(driver, carpool, rider_name)
    @user = driver
    @carpool = carpool
    @rider_name = rider_name
    @carpool_url = carpool_url(carpool)
    mail to: driver.email, subject: "#{rider_name} accepted your seat offer for #{carpool.name}"
  end

  def removed_from_ride(user, carpool, driver_name)
    @user = user
    @carpool = carpool
    @driver_name = driver_name
    @carpool_url = carpool_url(carpool)
    mail to: user.email, subject: "Your seat for #{carpool.name} was released"
  end

  def ride_canceled(user, carpool, driver_name)
    @user = user
    @carpool = carpool
    @driver_name = driver_name
    @carpool_url = carpool_url(carpool)
    mail to: user.email, subject: "Your ride for #{carpool.name} was canceled"
  end
end
