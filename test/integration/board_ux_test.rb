require "test_helper"

class BoardUxTest < ActionDispatch::IntegrationTest
  setup do
    @organizer = User.create!(name: "Organizer", email: "organizer@example.com")
    @carpool = @organizer.carpools.create!(
      name: "Beach day", destination: "Ocean Beach",
      starts_at: 2.days.from_now, return_starts_at: 3.days.from_now
    )
    @driver = User.create!(name: "Sam", email: "sam@example.com")
    @rider = User.create!(name: "Alex", email: "alex@example.com")
  end

  test "each direction section has its own join form" do
    sign_in_as(@rider)
    get carpool_path(@carpool)

    assert_select "#join-outbound form.ride-form"
    assert_select "#join-return form.ride-form"
  end

  test "role and direction params preselect the matching section's form" do
    sign_in_as(@rider)
    get carpool_path(@carpool, role: "rider", direction: "return")

    assert_select "#join-return input[type=radio][value=rider][checked]"
    assert_select "#join-outbound input[type=radio][value=driver][checked]"
  end

  test "signed-out ride buttons carry the choice through sign-in" do
    get carpool_path(@carpool)

    expected = new_session_path(return_to: carpool_path(@carpool, role: "driver", direction: "outbound", anchor: "join-outbound"))
    assert_select "a[href=?]", expected
    expected_return = new_session_path(return_to: carpool_path(@carpool, role: "rider", direction: "return", anchor: "join-return"))
    assert_select "a[href=?]", expected_return
  end

  test "a user with an entry sees their status instead of a duplicate form" do
    ride = @carpool.rides.create!(user: @driver, role: "driver", origin: "Mission", seats: 3)
    sign_in_as(@driver)
    get carpool_path(@carpool)

    assert_select "#join-outbound form.ride-form", count: 0
    assert_select "#join-outbound a[href=?]", edit_carpool_ride_path(@carpool, ride)
  end

  test "a failed ride post shows the error at the top of the page" do
    sign_in_as(@driver)
    post carpool_rides_path(@carpool), params: { ride: { role: "driver", direction: "outbound", origin: "", seats: 3 } }

    assert_response :unprocessable_entity
    assert_select ".flash .error-box", text: /Origin/
  end

  test "claim forms are rendered inline without a reload" do
    @carpool.rides.create!(user: @driver, role: "driver", origin: "Mission", seats: 3)
    sign_in_as(@rider)
    get carpool_path(@carpool)

    assert_select "details.claim-details form"
    assert_select "details.claim-details summary", text: "Join this ride"
  end

  test "the claim form prefills from your own ride request" do
    @carpool.rides.create!(user: @driver, role: "driver", origin: "Mission", seats: 3)
    @carpool.rides.create!(user: @rider, role: "rider", origin: "Sunset", seats: 2)
    sign_in_as(@rider)
    get carpool_path(@carpool)

    assert_select "details.claim-details input[name='ride_claim[pickup_location]'][value=?]", "Sunset"
    assert_select "details.claim-details input[name='ride_claim[seats]'][value=?]", "2"
  end

  test "the claim form prefills from your current claim when switching" do
    first = @carpool.rides.create!(user: @driver, role: "driver", origin: "Mission", seats: 3)
    second = @carpool.rides.create!(user: User.create!(name: "Jo", email: "jo@example.com"), role: "driver", origin: "Richmond", seats: 3)
    first.ride_claims.create!(carpool: @carpool, user: @rider, pickup_location: "Castro", seats: 1)
    sign_in_as(@rider)
    get carpool_path(@carpool)

    assert_select "details.claim-details summary", text: "Switch to this ride"
    assert_select "details.claim-details input[name='ride_claim[pickup_location]'][value=?]", "Castro"
  end

  test "a failed claim reopens the form with the error visible" do
    ride = @carpool.rides.create!(user: @driver, role: "driver", origin: "Mission", seats: 3)
    sign_in_as(@rider)
    post carpool_ride_ride_claims_path(@carpool, ride), params: { ride_claim: { pickup_location: "", seats: 1 } }

    assert_response :unprocessable_entity
    assert_select ".flash .error-box"
    assert_select "details.claim-details[open] form"
  end

  test "the live-update hint appears exactly once" do
    sign_in_as(@rider)
    get carpool_path(@carpool)

    assert_select ".live-hint", count: 1
  end

  test "an empty board nudges the organizer to share the link" do
    sign_in_as(@organizer)
    get carpool_path(@carpool)

    assert_match(/[Ss]hare/, response.body)
  end

  test "seat totals say what they count" do
    @carpool.rides.create!(user: @driver, role: "driver", origin: "Mission", seats: 3)
    @carpool.rides.create!(user: @rider, role: "rider", origin: "Sunset", seats: 2)
    sign_in_as(@rider)
    get carpool_path(@carpool)

    assert_match(/3 seats free/, response.body)
    assert_match(/2 seats needed/, response.body)
  end
end
