require "test_helper"

class RelaxedRequirementsTest < ActionDispatch::IntegrationTest
  setup do
    @organizer = User.create!(name: "Organizer", email: "organizer@example.com")
    @carpool = @organizer.carpools.create!(name: "Beach day", destination: "Ocean Beach", starts_at: 2.days.from_now)
    @driver = User.create!(name: "Sam", email: "sam@example.com")
    @rider = User.create!(name: "Alex", email: "alex@example.com")
  end

  test "a carpool without a name gets one from the destination" do
    sign_in_as(@organizer)

    post carpools_path, params: { carpool: { name: "", destination: "Stinson Beach", starts_at: 2.days.from_now } }

    carpool = Carpool.find_by!(destination: "Stinson Beach")
    assert_equal "Carpool to Stinson Beach", carpool.name
  end

  test "a ride can be posted without a location" do
    sign_in_as(@driver)

    post carpool_rides_path(@carpool), params: { ride: { role: "driver", direction: "outbound", origin: "", seats: 3 } }

    ride = @carpool.rides.find_by!(user: @driver)
    assert ride.origin.blank?

    get carpool_path(@carpool)
    assert_match(/not set — ask Sam/, response.body)
  end

  test "a seat can be claimed without a pickup location" do
    ride = @carpool.rides.create!(user: @driver, role: "driver", origin: "Mission", seats: 3)
    sign_in_as(@rider)

    post carpool_ride_ride_claims_path(@carpool, ride), params: { ride_claim: { pickup_location: "", seats: 1 } }

    assert ride.ride_claims.exists?(user: @rider)
  end

  test "the seats field defaults to 1" do
    sign_in_as(@rider)
    get carpool_path(@carpool)

    assert_select "#join-outbound input[name='ride[seats]'][value='1']"
  end

  test "optional location fields are labeled optional" do
    ride = @carpool.rides.create!(user: @driver, role: "driver", origin: "Mission", seats: 3)
    sign_in_as(@rider)
    get carpool_path(@carpool)

    assert_select "#join-outbound label", text: "Starting location (optional)"
    assert_select ".claim-form label", text: "Pickup location (optional)"

    get new_carpool_path
    assert_select "label", text: "Destination address (optional)"
  end

  test "a carpool needs only a destination and its date is TBD until set" do
    sign_in_as(@organizer)

    post carpools_path, params: { carpool: { destination: "Stinson Beach", starts_at: "" } }
    carpool = Carpool.find_by!(destination: "Stinson Beach")
    assert_nil carpool.starts_at

    get carpool_path(carpool)
    assert_match(/TBD/, response.body)

    get root_path
    assert_select "a[href=?]", carpool_path(carpool) # still listed as upcoming
    assert_match(/Date TBD/, response.body)
  end

  test "required fields are grouped before optional ones" do
    get new_carpool_path
    body = response.body
    assert_operator body.index("Trip name *"), :<, body.index("Destination address (optional)")
    assert_operator body.index("Your email *"), :<, body.index("Event start time (optional)")
    assert_operator body.index("Your email *"), :<, body.index("Destination address (optional)")

    ride = @carpool.rides.create!(user: @driver, role: "driver", origin: "Mission", seats: 3)
    sign_in_as(@rider)
    get carpool_path(@carpool)
    body = response.body
    assert_operator body.index("Seats you can offer *"), :<, body.index("Starting location (optional)")
    assert_operator body.index("Number of seats *"), :<, body.index("Pickup location (optional)")
  end

  test "displacement still works when locations were never given" do
    ride = @carpool.rides.create!(user: @driver, role: "driver", origin: "", seats: 3)
    ride.ride_claims.create!(carpool: @carpool, user: @rider, pickup_location: "", seats: 1)
    sign_in_as(@driver)

    delete carpool_ride_path(@carpool, ride)

    request = @carpool.rides.find_by!(user: @rider)
    assert_equal "rider", request.role
  end
end
