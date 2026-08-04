require "test_helper"

class FormRequirednessTest < ActionDispatch::IntegrationTest
  setup do
    @organizer = User.create!(name: "Organizer", email: "organizer@example.com")
    @carpool = @organizer.carpools.create!(name: "Beach day", destination: "Ocean Beach", starts_at: 2.days.from_now)
  end

  test "the carpool form marks required and optional fields" do
    get new_carpool_path

    assert_select "label", text: "Trip name *"
    assert_select "label", text: "Destination *"
    assert_select "label", text: "Event start time *"
    assert_select "label", text: "Return trip starts around (optional)"
    assert_select "label", text: "Notes (optional)"
    assert_select "label", text: "Your name *"
    assert_select "label", text: "Your email *"
    assert_match "* required", response.body
  end

  test "the ride form marks required and optional fields" do
    sign_in_as(@organizer)
    get carpool_path(@carpool)

    assert_select "#join-outbound label", text: "Starting location *"
    assert_select "#join-outbound label", text: "Departure time (optional)"
    assert_select "#join-outbound label", text: "Seats you can offer *"
    assert_select "#join-outbound label", text: "Notes (optional)"
  end

  test "the claim form marks its required fields" do
    driver = User.create!(name: "Sam", email: "sam@example.com")
    @carpool.rides.create!(user: driver, role: "driver", origin: "Mission", seats: 3)
    rider = User.create!(name: "Alex", email: "alex@example.com")
    sign_in_as(rider)
    get carpool_path(@carpool)

    assert_select ".claim-form label", text: "Pickup location *"
    assert_select ".claim-form label", text: "Number of seats *"
  end

  test "the sign-in steps mark their required fields" do
    get new_session_path
    assert_select "label", text: "Email *"

    post session_path, params: { user: { email: "fresh@example.com" } }
    assert_select "label", text: "Name *"
  end

  test "the account forms mark their required fields" do
    sign_in_as(@organizer)
    get edit_account_path

    assert_select "label", text: "Name *"
    assert_select "label", text: "New email address *"
  end
end
