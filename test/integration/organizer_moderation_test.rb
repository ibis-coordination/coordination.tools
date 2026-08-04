require "test_helper"

class OrganizerModerationTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  setup do
    @organizer = User.create!(name: "Organizer", email: "organizer@example.com")
    @carpool = @organizer.carpools.create!(name: "Beach day", destination: "Ocean Beach", starts_at: 2.days.from_now)
    @driver = User.create!(name: "Sam", email: "sam@example.com")
    @passenger = User.create!(name: "Alex", email: "alex@example.com")
    @ride = @carpool.rides.create!(user: @driver, role: "driver", origin: "Mission", seats: 3)
    @claim = @ride.ride_claims.create!(carpool: @carpool, user: @passenger, pickup_location: "Castro", seats: 1)
  end

  test "the organizer can remove a ride; owner and passengers are emailed" do
    sign_in_as(@organizer)

    assert_enqueued_emails 2 do
      delete carpool_ride_path(@carpool, @ride)
    end

    assert_not Ride.exists?(@ride.id)
    assert @carpool.rides.exists?(user: @passenger, role: "rider")

    perform_enqueued_jobs
    recipients = ActionMailer::Base.deliveries.flat_map(&:to)
    assert_includes recipients, "sam@example.com"    # ride owner told of removal
    assert_includes recipients, "alex@example.com"   # displaced passenger
  end

  test "the organizer can remove a claim; the passenger is reposted and emailed" do
    sign_in_as(@organizer)

    assert_enqueued_emails 1 do
      delete carpool_ride_ride_claim_path(@carpool, @ride, @claim)
    end

    assert_not RideClaim.exists?(@claim.id)
    assert @carpool.rides.exists?(user: @passenger, role: "rider")
  end

  test "the organizer sees remove controls on entries they don't own" do
    sign_in_as(@organizer)
    get carpool_path(@carpool)

    assert_select ".owner-actions form[action=?]", carpool_ride_path(@carpool, @ride)
    assert_select ".passengers form[action=?]", carpool_ride_ride_claim_path(@carpool, @ride, @claim)
  end

  test "the organizer cannot edit entries they don't own" do
    sign_in_as(@organizer)

    get edit_carpool_ride_path(@carpool, @ride)
    assert_response :not_found
  end

  test "a non-organizer still cannot remove someone else's ride" do
    outsider = User.create!(name: "Jo", email: "jo@example.com")
    sign_in_as(outsider)

    delete carpool_ride_path(@carpool, @ride)

    assert_response :not_found
    assert Ride.exists?(@ride.id)
  end
end
