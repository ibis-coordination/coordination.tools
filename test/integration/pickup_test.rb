require "test_helper"

class PickupTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  setup do
    @organizer = User.create!(name: "Organizer", email: "organizer@example.com")
    @carpool = @organizer.carpools.create!(name: "Beach day", destination: "Ocean Beach", starts_at: 2.days.from_now)
    @driver = User.create!(name: "Sam", email: "sam@example.com")
    @rider = User.create!(name: "Alex", email: "alex@example.com")
    @driver_ride = @carpool.rides.create!(user: @driver, role: "driver", origin: "Mission", seats: 3)
    @ride_request = @carpool.rides.create!(user: @rider, role: "rider", origin: "Sunset", seats: 2)
  end

  test "a driver can pick up a ride request" do
    sign_in_as(@driver)

    assert_enqueued_emails 1 do
      post carpool_pickups_path(@carpool), params: { ride_id: @ride_request.id }
    end

    assert_redirected_to carpool_path(@carpool)
    claim = @driver_ride.ride_claims.find_by!(user: @rider)
    assert_equal "Sunset", claim.pickup_location
    assert_equal 2, claim.seats
    assert_not Ride.exists?(@ride_request.id)

    perform_enqueued_jobs
    email = ActionMailer::Base.deliveries.last
    assert_equal ["alex@example.com"], email.to
    assert_match "Sam", email.text_part.body.to_s
  end

  test "a pickup that does not fit is rejected" do
    @ride_request.update!(seats: 4)
    sign_in_as(@driver)

    post carpool_pickups_path(@carpool), params: { ride_id: @ride_request.id }

    assert_redirected_to carpool_path(@carpool)
    assert_equal 0, @driver_ride.ride_claims.count
    assert Ride.exists?(@ride_request.id)
  end

  test "only drivers with a ride in that direction can pick up" do
    outsider = User.create!(name: "Jo", email: "jo@example.com")
    sign_in_as(outsider)

    post carpool_pickups_path(@carpool), params: { ride_id: @ride_request.id }

    assert_response :not_found
    assert Ride.exists?(@ride_request.id)
  end

  test "the pickup button shows for eligible drivers only" do
    sign_in_as(@driver)
    get carpool_path(@carpool)
    assert_select "form[action=?]", carpool_pickups_path(@carpool)

    sign_in_as(@rider)
    get carpool_path(@carpool)
    assert_select "form[action=?]", carpool_pickups_path(@carpool), count: 0
  end
end
