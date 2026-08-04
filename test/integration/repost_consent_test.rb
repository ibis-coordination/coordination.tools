require "test_helper"

class RepostConsentTest < ActionDispatch::IntegrationTest
  setup do
    @organizer = User.create!(name: "Organizer", email: "organizer@example.com")
    @carpool = @organizer.carpools.create!(name: "Beach day", destination: "Ocean Beach", starts_at: 2.days.from_now)
    @driver = User.create!(name: "Sam", email: "sam@example.com")
    @passenger = User.create!(name: "Alex", email: "alex@example.com")
    @ride = @carpool.rides.create!(user: @driver, role: "driver", origin: "Mission", seats: 3)
    @claim = @ride.ride_claims.create!(carpool: @carpool, user: @passenger, pickup_location: "22 Castro St", seats: 1)
  end

  test "leaving a ride on your own does not post a request in your name" do
    sign_in_as(@passenger)

    delete carpool_ride_ride_claim_path(@carpool, @ride, @claim)
    follow_redirect!

    assert_not @carpool.rides.exists?(user: @passenger)
    assert_match(/post a new ride request/i, response.body)
  end

  test "a repost after driver removal does not publish the pickup address" do
    sign_in_as(@driver)

    delete carpool_ride_ride_claim_path(@carpool, @ride, @claim)

    request = @carpool.rides.find_by!(user: @passenger, role: "rider")
    assert_nil request.origin
  end

  test "a repost after ride cancellation does not publish the pickup address" do
    sign_in_as(@driver)

    delete carpool_ride_path(@carpool, @ride)

    request = @carpool.rides.find_by!(user: @passenger, role: "rider")
    assert_nil request.origin
    assert_equal 1, request.seats
  end
end
