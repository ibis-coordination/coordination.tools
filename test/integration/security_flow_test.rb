require "test_helper"

class SecurityFlowTest < ActionDispatch::IntegrationTest
  setup do
    @organizer = User.create!(name: "Organizer", email: "organizer@example.com")
    @carpool = @organizer.carpools.create!(name: "Beach day", destination: "Ocean Beach", starts_at: 2.days.from_now)
  end

  test "claiming an existing email cannot change that user's name or create a session" do
    post session_path, params: { user: { name: "Mallory", email: "organizer@example.com" } }

    assert_redirected_to new_session_path
    assert_equal "Organizer", @organizer.reload.name
    assert_equal 1, User.count

    get edit_account_path
    assert_redirected_to new_session_path # Mallory is not signed in
  end

  test "signing in after a bounce still returns to the requested page" do
    get edit_account_path
    assert_redirected_to new_session_path

    post session_path, params: { user: { name: "Alex", email: "alex@example.com" } }

    assert_redirected_to edit_account_path
  end

  test "participant emails are hidden from signed out visitors" do
    driver = User.create!(name: "Sam", email: "sam@example.com")
    passenger = User.create!(name: "Alex", email: "alex@example.com")
    ride = @carpool.rides.create!(user: driver, role: "driver", origin: "Mission", seats: 3)
    ride.ride_claims.create!(carpool: @carpool, user: passenger, pickup_location: "Castro", seats: 1)

    get carpool_path(@carpool)
    assert_response :success
    assert_no_match "sam@example.com", response.body
    assert_no_match "alex@example.com", response.body

    sign_in_as(passenger)
    get carpool_path(@carpool)
    assert_match "sam@example.com", response.body
  end

  test "signed out visitors see a sign-in prompt instead of entry forms" do
    get carpool_path(@carpool)

    assert_response :success
    assert_select "form.ride-form", count: 0
    assert_select "a[href=?]", new_session_path(return_to: carpool_path(@carpool))
  end

  test "signing in from a carpool page returns to that carpool" do
    get new_session_path(return_to: carpool_path(@carpool))
    post session_path, params: { user: { name: "Alex", email: "alex@example.com" } }

    assert_redirected_to carpool_path(@carpool)
  end

  test "an external return_to is ignored" do
    get new_session_path(return_to: "https://evil.example.com/phish")
    post session_path, params: { user: { name: "Alex", email: "alex@example.com" } }

    assert_redirected_to root_path
  end

  test "canceling a ride succeeds even when a displaced passenger already has a ride request" do
    driver = User.create!(name: "Sam", email: "sam@example.com")
    passenger = User.create!(name: "Alex", email: "alex@example.com")
    ride = @carpool.rides.create!(user: driver, role: "driver", origin: "Mission", seats: 3)
    ride.ride_claims.create!(carpool: @carpool, user: passenger, pickup_location: "Castro", seats: 1)
    # Drifted state: the passenger also holds a ride request in the same direction.
    stray = @carpool.rides.new(user: passenger, role: "rider", origin: "Sunset", seats: 1, direction: "outbound")
    stray.save!(validate: false)

    sign_in_as(driver)
    delete carpool_ride_path(@carpool, ride)

    assert_redirected_to carpool_path(@carpool)
    assert_not Ride.exists?(ride.id)
    assert_equal 1, @carpool.rides.where(user: passenger, role: "rider", direction: "outbound").count
  end
end
