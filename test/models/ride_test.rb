require "test_helper"

class RideTest < ActiveSupport::TestCase
  setup do
    @organizer = User.create!(name: "Organizer", email: "organizer@example.com")
    @driver = User.create!(name: "Sam", email: "sam@example.com")
    @carpool = @organizer.carpools.create!(name: "Beach day", destination: "Ocean Beach", starts_at: 2.days.from_now)
  end

  test "accepts drivers and riders" do
    assert @carpool.rides.create!(user: @driver, role: "driver", origin: "Mission", seats: 2).valid?
    rider = User.create!(name: "Alex", email: "alex@example.com")
    assert @carpool.rides.create!(user: rider, role: "rider", origin: "Sunset", seats: 1).valid?
  end

  test "does not reduce capacity below claimed seats" do
    ride = @carpool.rides.create!(user: @driver, role: "driver", origin: "Mission", seats: 3)
    rider = User.create!(name: "Alex", email: "alex@example.com")
    ride.ride_claims.create!(carpool: @carpool, user: rider, pickup_location: "Sunset", seats: 2)
    assert_not ride.update(seats: 1)
  end

  test "driver with passengers cannot change direction" do
    @carpool.update!(return_starts_at: 3.days.from_now)
    ride = @carpool.rides.create!(user: @driver, role: "driver", origin: "Mission", seats: 2)
    rider = User.create!(name: "Alex", email: "alex@example.com")
    ride.ride_claims.create!(carpool: @carpool, user: rider, pickup_location: "Sunset", seats: 1)
    assert_not ride.update(direction: "return")
    assert_equal "outbound", ride.reload.direction
  end

  test "driver with passengers cannot become a rider" do
    ride = @carpool.rides.create!(user: @driver, role: "driver", origin: "Mission", seats: 2)
    rider = User.create!(name: "Alex", email: "alex@example.com")
    ride.ride_claims.create!(carpool: @carpool, user: rider, pickup_location: "Sunset", seats: 1)
    assert_not ride.update(role: "rider")
  end
end
