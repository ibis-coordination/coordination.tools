require "test_helper"

class RideClaimTest < ActiveSupport::TestCase
  test "requires pickup location and seat count" do
    organizer = User.create!(name: "Organizer", email: "organizer@example.com")
    driver = User.create!(name: "Sam", email: "sam@example.com")
    rider = User.create!(name: "Alex", email: "alex@example.com")
    carpool = organizer.carpools.create!(name: "Beach day", destination: "Ocean Beach", starts_at: 2.days.from_now)
    ride = carpool.rides.create!(user: driver, role: "driver", origin: "Mission", seats: 2)

    assert_not ride.ride_claims.new(carpool: carpool, user: rider).valid?
    assert ride.ride_claims.new(carpool: carpool, user: rider, pickup_location: "Sunset", seats: 2).valid?
  end
end
