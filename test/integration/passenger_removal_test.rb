require "test_helper"

class PassengerRemovalTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  setup do
    @organizer = User.create!(name: "Organizer", email: "organizer@example.com")
    @carpool = @organizer.carpools.create!(name: "Beach day", destination: "Ocean Beach", starts_at: 2.days.from_now)
    @driver = User.create!(name: "Sam", email: "sam@example.com")
    @passenger = User.create!(name: "Alex", email: "alex@example.com")
    @ride = @carpool.rides.create!(user: @driver, role: "driver", origin: "Mission", seats: 3)
    @claim = @ride.ride_claims.create!(carpool: @carpool, user: @passenger, pickup_location: "Castro", seats: 2)
  end

  test "the driver can remove a passenger, who is reposted and emailed" do
    sign_in_as(@driver)

    assert_enqueued_emails 1 do
      delete carpool_ride_ride_claim_path(@carpool, @ride, @claim)
    end

    assert_not RideClaim.exists?(@claim.id)
    request = @carpool.rides.find_by!(user: @passenger)
    assert_equal "rider", request.role
    assert_equal "Castro", request.origin

    perform_enqueued_jobs
    email = ActionMailer::Base.deliveries.last
    assert_equal ["alex@example.com"], email.to
  end

  test "a bystander cannot remove someone else's claim" do
    outsider = User.create!(name: "Jo", email: "jo@example.com")
    sign_in_as(outsider)

    delete carpool_ride_ride_claim_path(@carpool, @ride, @claim)

    assert_response :not_found
    assert RideClaim.exists?(@claim.id)
  end

  test "the driver sees a remove control next to each passenger" do
    sign_in_as(@driver)
    get carpool_path(@carpool)

    assert_select ".passengers form[action=?]", carpool_ride_ride_claim_path(@carpool, @ride, @claim)
  end

  test "a passenger leaving their own ride still works and sends no email" do
    sign_in_as(@passenger)

    assert_no_enqueued_emails do
      delete carpool_ride_ride_claim_path(@carpool, @ride, @claim)
    end
    assert_not RideClaim.exists?(@claim.id)
  end
end
