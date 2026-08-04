require "test_helper"

class DisplacementTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  setup do
    @organizer = User.create!(name: "Organizer", email: "organizer@example.com")
    @carpool = @organizer.carpools.create!(name: "Beach day", destination: "Ocean Beach", starts_at: 2.days.from_now)
    @driver = User.create!(name: "Sam", email: "sam@example.com")
    @passenger = User.create!(name: "Alex", email: "alex@example.com")
    @ride = @carpool.rides.create!(user: @driver, role: "driver", origin: "Mission", seats: 3)
    @claim = @ride.ride_claims.create!(carpool: @carpool, user: @passenger, pickup_location: "Castro", seats: 2)
  end

  test "canceling a ride emails each displaced passenger" do
    second = User.create!(name: "Jo", email: "jo@example.com")
    @ride.ride_claims.create!(carpool: @carpool, user: second, pickup_location: "Richmond", seats: 1)
    sign_in_as(@driver)

    assert_enqueued_emails 2 do
      delete carpool_ride_path(@carpool, @ride)
    end

    perform_enqueued_jobs
    recipients = ActionMailer::Base.deliveries.flat_map(&:to)
    assert_includes recipients, "alex@example.com"
    assert_includes recipients, "jo@example.com"
    body = ActionMailer::Base.deliveries.last.text_part.body.to_s
    assert_match @carpool.name, body
    assert_match carpool_url(@carpool, host: "example.com"), body
  end

  test "canceling a ride with no passengers sends no email" do
    empty_ride = @carpool.rides.create!(
      user: User.create!(name: "Jo", email: "jo@example.com"),
      role: "driver", origin: "Sunset", seats: 2, direction: "outbound"
    )
    sign_in_as(empty_ride.user)

    assert_no_enqueued_emails do
      delete carpool_ride_path(@carpool, empty_ride)
    end
  end
end
