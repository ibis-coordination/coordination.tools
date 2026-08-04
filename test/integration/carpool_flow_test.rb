require "test_helper"

class CarpoolFlowTest < ActionDispatch::IntegrationTest
  setup do
    @organizer = User.create!(name: "Organizer", email: "organizer@example.com")
    @carpool = @organizer.carpools.create!(name: "Beach day", destination: "Ocean Beach", starts_at: 2.days.from_now)
  end

  test "email and name create a session without confirmation" do
    post session_path, params: { user: { name: "Alex", email: " ALEX@EXAMPLE.COM " } }
    assert_redirected_to root_path
    assert_equal "alex@example.com", User.find_by!(name: "Alex").email
  end

  test "creating entries requires a session" do
    post carpool_rides_path(@carpool), params: { ride: { role: "driver", origin: "Mission", seats: 2 } }
    assert_redirected_to new_session_path
    assert_equal 0, @carpool.rides.count
  end

  test "a ride uses the signed in user and email as contact" do
    driver = User.create!(name: "Sam", email: "sam@example.com")
    sign_in_as(driver)
    post carpool_rides_path(@carpool), params: { ride: { role: "driver", origin: "Mission", seats: 3 } }
    assert_equal driver, @carpool.rides.last.user
    get carpool_path(@carpool)
    assert_match "sam@example.com", response.body
  end

  test "claiming seats removes the user's ride request" do
    driver = User.create!(name: "Sam", email: "sam@example.com")
    rider = User.create!(name: "Alex", email: "alex@example.com")
    ride = @carpool.rides.create!(user: driver, role: "driver", origin: "Mission", seats: 3)
    @carpool.rides.create!(user: rider, role: "rider", origin: "Sunset", seats: 2)
    sign_in_as(rider)

    post carpool_ride_ride_claims_path(@carpool, ride), params: { ride_claim: { pickup_location: "Sunset", seats: 2 } }

    assert_equal 0, @carpool.rides.where(user: rider).count
    assert_equal 2, ride.ride_claims.find_by!(user: rider).seats
    assert_equal 1, ride.reload.available_seats
  end

  test "a claim cannot exceed available capacity" do
    driver = User.create!(name: "Sam", email: "sam@example.com")
    rider = User.create!(name: "Alex", email: "alex@example.com")
    ride = @carpool.rides.create!(user: driver, role: "driver", origin: "Mission", seats: 1)
    sign_in_as(rider)
    assert_no_difference("RideClaim.count") do
      post carpool_ride_ride_claims_path(@carpool, ride), params: { ride_claim: { pickup_location: "Sunset", seats: 2 } }
    end
  end

  test "a rider switches rather than joining multiple rides" do
    first_driver = User.create!(name: "Sam", email: "sam@example.com")
    second_driver = User.create!(name: "Jo", email: "jo@example.com")
    rider = User.create!(name: "Alex", email: "alex@example.com")
    first = @carpool.rides.create!(user: first_driver, role: "driver", origin: "Mission", seats: 2)
    second = @carpool.rides.create!(user: second_driver, role: "driver", origin: "Sunset", seats: 2)
    sign_in_as(rider)
    post carpool_ride_ride_claims_path(@carpool, first), params: { ride_claim: { pickup_location: "Castro", seats: 1 } }

    assert_no_difference("RideClaim.count") do
      post carpool_ride_ride_claims_path(@carpool, second), params: { ride_claim: { pickup_location: "Castro", seats: 1 } }
    end
    assert_equal second, @carpool.ride_claims.find_by!(user: rider).ride
  end

  test "drivers cannot claim and passengers cannot become drivers" do
    driver = User.create!(name: "Sam", email: "sam@example.com")
    other_driver = User.create!(name: "Jo", email: "jo@example.com")
    other_ride = @carpool.rides.create!(user: other_driver, role: "driver", origin: "Sunset", seats: 2)
    sign_in_as(driver)
    post carpool_rides_path(@carpool), params: { ride: { role: "driver", origin: "Mission", seats: 2 } }
    assert_no_difference("RideClaim.count") do
      post carpool_ride_ride_claims_path(@carpool, other_ride), params: { ride_claim: { pickup_location: "Mission", seats: 1 } }
    end

    delete session_path
    passenger = User.create!(name: "Alex", email: "alex@example.com")
    other_ride.ride_claims.create!(carpool: @carpool, user: passenger, pickup_location: "Castro", seats: 1)
    sign_in_as(passenger)
    assert_no_difference("Ride.count") do
      post carpool_rides_path(@carpool), params: { ride: { role: "driver", origin: "Castro", seats: 2 } }
    end
  end

  test "canceling a ride returns passengers to ride requests" do
    driver = User.create!(name: "Sam", email: "sam@example.com")
    passenger = User.create!(name: "Alex", email: "alex@example.com")
    ride = @carpool.rides.create!(user: driver, role: "driver", origin: "Mission", seats: 3)
    ride.ride_claims.create!(carpool: @carpool, user: passenger, pickup_location: "Castro", seats: 2)
    sign_in_as(driver)

    delete carpool_ride_path(@carpool, ride)

    request = @carpool.rides.find_by!(user: passenger)
    assert_equal "rider", request.role
    assert_equal "Castro", request.origin
    assert_equal 2, request.seats
  end

  test "leaving a ride restores the passenger's ride request" do
    driver = User.create!(name: "Sam", email: "sam@example.com")
    passenger = User.create!(name: "Alex", email: "alex@example.com")
    ride = @carpool.rides.create!(user: driver, role: "driver", origin: "Mission", seats: 3)
    claim = ride.ride_claims.create!(carpool: @carpool, user: passenger, pickup_location: "Castro", seats: 2)
    sign_in_as(passenger)

    delete carpool_ride_ride_claim_path(@carpool, ride, claim)

    request = @carpool.rides.find_by!(user: passenger)
    assert_equal "rider", request.role
    assert_equal "Castro", request.origin
    assert_equal 2, request.seats
    assert_not RideClaim.exists?(claim.id)
  end

  test "outbound and return arrangements are independent" do
    @carpool.update!(return_starts_at: 3.days.from_now)
    driver = User.create!(name: "Sam", email: "sam@example.com")
    rider = User.create!(name: "Alex", email: "alex@example.com")
    outbound = @carpool.rides.create!(user: driver, role: "driver", direction: "outbound", origin: "Mission", seats: 2)
    returning = @carpool.rides.create!(user: driver, role: "driver", direction: "return", origin: "Ocean Beach", seats: 2)
    sign_in_as(rider)

    post carpool_ride_ride_claims_path(@carpool, outbound), params: { ride_claim: { pickup_location: "Castro", seats: 1 } }
    post carpool_ride_ride_claims_path(@carpool, returning), params: { ride_claim: { pickup_location: "Ocean Beach", seats: 1 } }

    assert_equal 2, @carpool.ride_claims.where(user: rider).count
    assert_equal %w[outbound return], @carpool.ride_claims.where(user: rider).order(:direction).pluck(:direction)
    get carpool_path(@carpool)
    assert_select ".direction-title", text: "To the event"
    assert_select ".direction-title", text: "Return trip"
  end

  test "the organizer can add a return trip to an existing carpool" do
    sign_in_as(@organizer)
    return_time = 3.days.from_now.change(min: 0)

    patch carpool_path(@carpool), params: { carpool: { name: @carpool.name, destination: @carpool.destination, starts_at: @carpool.starts_at, return_starts_at: return_time } }

    assert_redirected_to carpool_path(@carpool)
    assert_in_delta return_time.to_i, @carpool.reload.return_starts_at.to_i, 1
  end

  test "return entries ask for a destination" do
    @carpool.update!(return_starts_at: 3.days.from_now)
    sign_in_as(User.create!(name: "Sam", email: "sam@example.com"))
    get carpool_path(@carpool, role: "driver", direction: "return")

    assert_response :success
    assert_select "label[for='return_ride_origin']", text: "Destination"
    assert_select "label[for='outbound_ride_origin']", text: "Starting location"
  end
end
