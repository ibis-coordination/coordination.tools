require "test_helper"

class VisibilityTest < ActionDispatch::IntegrationTest
  setup do
    @organizer = User.create!(name: "Organizer", email: "organizer@example.com")
    @carpool = @organizer.carpools.create!(name: "Beach day", destination: "Ocean Beach", starts_at: 2.days.from_now)
    @driver = User.create!(name: "Sam", email: "sam@example.com")
    @passenger = User.create!(name: "Alex", email: "alex@example.com")
    @requester = User.create!(name: "Riley", email: "riley@example.com")
    @ride = @carpool.rides.create!(user: @driver, role: "driver", origin: "Mission", seats: 3)
    @claim = @ride.ride_claims.create!(carpool: @carpool, user: @passenger, pickup_location: "22 Castro St", seats: 1)
    @request = @carpool.rides.create!(user: @requester, role: "rider", origin: "Sunset", seats: 1)
  end

  test "a signed-in bystander sees no emails or pickup addresses" do
    bystander = User.create!(name: "Jo", email: "jo@example.com")
    sign_in_as(bystander)
    get carpool_path(@carpool)

    assert_no_match "sam@example.com", response.body
    assert_no_match "alex@example.com", response.body
    assert_no_match "riley@example.com", response.body
    assert_no_match "22 Castro St", response.body
  end

  test "driver and passenger see each other's contact details" do
    sign_in_as(@driver)
    get carpool_path(@carpool)
    assert_match "alex@example.com", response.body
    assert_match "22 Castro St", response.body
    assert_no_match "riley@example.com", response.body # request contact goes via seat offers

    sign_in_as(@passenger)
    get carpool_path(@carpool)
    assert_match "sam@example.com", response.body
  end

  test "a rider who has not joined the ride does not see the driver's email" do
    other = User.create!(name: "Jo", email: "jo@example.com")
    @carpool.rides.create!(user: other, role: "rider", origin: "Richmond", seats: 1)
    sign_in_as(other)
    get carpool_path(@carpool)

    assert_no_match "sam@example.com", response.body
  end

  test "the organizer sees participant emails but not pickup addresses" do
    sign_in_as(@organizer)
    get carpool_path(@carpool)

    assert_match "sam@example.com", response.body
    assert_match "alex@example.com", response.body
    assert_no_match "22 Castro St", response.body
  end
end
