require "test_helper"

class BoardPolishTest < ActionDispatch::IntegrationTest
  setup do
    @organizer = User.create!(name: "Organizer", email: "organizer@example.com")
    @carpool = @organizer.carpools.create!(name: "Beach day", destination: "Ocean Beach", starts_at: 2.days.from_now.change(hour: 10))
    @rider = User.create!(name: "Alex", email: "alex@example.com")
  end

  test "the seats label matches the selected role" do
    sign_in_as(@rider)

    get carpool_path(@carpool, role: "rider", direction: "outbound")
    assert_select "#join-outbound label", text: "Seats you need"

    get carpool_path(@carpool, role: "driver", direction: "outbound")
    assert_select "#join-outbound label", text: "Seats you can offer"
  end

  test "the seats label carries per-role texts for live swapping" do
    sign_in_as(@rider)
    get carpool_path(@carpool)

    assert_select "#join-outbound label[data-driver-text][data-rider-text]"
  end

  test "join and claim forms survive live refreshes" do
    driver = User.create!(name: "Sam", email: "sam@example.com")
    ride = @carpool.rides.create!(user: driver, role: "driver", origin: "Mission", seats: 3)
    sign_in_as(@rider)
    get carpool_path(@carpool)

    assert_select "#join-outbound[data-turbo-permanent]"
    assert_select "#claim-details-#{ride.id}[data-turbo-permanent]"
  end

  test "departure times on a different day than the event show the date" do
    driver = User.create!(name: "Sam", email: "sam@example.com")
    same_day = @carpool.starts_at.change(hour: 8)
    other_day = @carpool.starts_at - 1.day
    @carpool.rides.create!(user: driver, role: "driver", origin: "Mission", seats: 3, departure_time: other_day)
    sign_in_as(@rider)
    get carpool_path(@carpool)

    assert_match other_day.strftime("%b %-d"), response.body
  end

  test "the carpool form says times are local to the event" do
    get new_carpool_path

    assert_match(/local time/i, response.body)
  end
end
