require "test_helper"

class ProgressiveDisclosureTest < ActionDispatch::IntegrationTest
  setup do
    @organizer = User.create!(name: "Organizer", email: "organizer@example.com")
    @carpool = @organizer.carpools.create!(name: "Beach day", destination: "Ocean Beach", starts_at: 2.days.from_now)
    @rider = User.create!(name: "Alex", email: "alex@example.com")
  end

  test "the carpool form requires only a trip name, destination is an optional address" do
    sign_in_as(@organizer)

    post carpools_path, params: { carpool: { name: "Sunday hike", destination: "" } }

    carpool = Carpool.find_by!(name: "Sunday hike")
    assert_nil carpool.destination.presence
    assert_redirected_to carpool_path(carpool)
  end

  test "the carpool form tucks optional fields into a collapsed section" do
    get new_carpool_path

    assert_select "label", text: "Trip name *"
    assert_select "details.more-details:not([open])" do
      assert_select "label", text: "Destination address (optional)"
      assert_select "label", text: "Event start time (optional)"
      assert_select "label", text: "Return trip starts around (optional)"
      assert_select "label", text: "Notes (optional)"
    end
  end

  test "the collapsed section opens on edit when it holds values" do
    sign_in_as(@organizer)
    get edit_carpool_path(@carpool)

    assert_select "details.more-details[open]"
  end

  test "the ride form tucks optional fields into a collapsed section" do
    sign_in_as(@rider)
    get carpool_path(@carpool)

    assert_select "#join-outbound details.more-details:not([open])" do
      assert_select "label", text: "Starting location (optional)"
      assert_select "label", text: "Departure time (optional)"
      assert_select "label", text: "Notes (optional)"
    end
  end

  test "the claim form tucks the pickup location into a collapsed section" do
    driver = User.create!(name: "Sam", email: "sam@example.com")
    @carpool.rides.create!(user: driver, role: "driver", origin: "Mission", seats: 3)
    sign_in_as(@rider)
    get carpool_path(@carpool)

    assert_select ".claim-form details.more-details" do
      assert_select "label", text: "Pickup location (optional)"
    end
  end

  test "a blank destination hides the trip-facts row and homepage reference" do
    minimal = @organizer.carpools.create!(name: "Sunday hike")
    sign_in_as(@organizer)

    get carpool_path(minimal)
    assert_no_match(/Destination/, response.body)

    get root_path
    assert_select "a[href=?]", carpool_path(minimal)
  end
end
