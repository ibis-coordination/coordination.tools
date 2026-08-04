require "test_helper"

class SeatOfferTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  setup do
    @organizer = User.create!(name: "Organizer", email: "organizer@example.com")
    @carpool = @organizer.carpools.create!(name: "Beach day", destination: "Ocean Beach", starts_at: 2.days.from_now)
    @driver = User.create!(name: "Sam", email: "sam@example.com")
    @rider = User.create!(name: "Alex", email: "alex@example.com")
    @driver_ride = @carpool.rides.create!(user: @driver, role: "driver", origin: "Mission", seats: 3)
    @ride_request = @carpool.rides.create!(user: @rider, role: "rider", origin: "Sunset", seats: 2)
  end

  test "offering a seat asks the rider instead of seating them" do
    sign_in_as(@driver)

    assert_enqueued_emails 1 do
      post carpool_seat_offers_path(@carpool), params: { ride_id: @ride_request.id }
    end

    assert_equal 0, @driver_ride.ride_claims.count # nothing committed
    assert Ride.exists?(@ride_request.id) # request still listed
    offer = SeatOffer.find_by!(ride: @driver_ride, user: @rider)
    assert_nil offer.declined_at

    perform_enqueued_jobs
    email = ActionMailer::Base.deliveries.last
    assert_equal ["alex@example.com"], email.to
    assert_match(/accept/i, email.text_part.body.to_s)
  end

  test "accepting an offer seats the rider on their own click" do
    offer = SeatOffer.create!(carpool: @carpool, ride: @driver_ride, user: @rider)
    sign_in_as(@rider)

    assert_enqueued_emails 1 do
      post accept_carpool_seat_offer_path(@carpool, offer)
    end

    claim = @driver_ride.ride_claims.find_by!(user: @rider)
    assert_equal "Sunset", claim.pickup_location
    assert_equal 2, claim.seats
    assert_not Ride.exists?(@ride_request.id)
    assert_not SeatOffer.exists?(offer.id)

    perform_enqueued_jobs
    assert_equal ["sam@example.com"], ActionMailer::Base.deliveries.last.to
  end

  test "declining an offer blocks re-offers" do
    offer = SeatOffer.create!(carpool: @carpool, ride: @driver_ride, user: @rider)
    sign_in_as(@rider)
    post decline_carpool_seat_offer_path(@carpool, offer)

    assert offer.reload.declined_at.present?
    assert_equal 0, @driver_ride.ride_claims.count

    sign_in_as(@driver)
    assert_no_difference("SeatOffer.count") do
      post carpool_seat_offers_path(@carpool), params: { ride_id: @ride_request.id }
    end
  end

  test "accepting fails gracefully when the seats are gone" do
    offer = SeatOffer.create!(carpool: @carpool, ride: @driver_ride, user: @rider)
    other = User.create!(name: "Jo", email: "jo@example.com")
    @driver_ride.ride_claims.create!(carpool: @carpool, user: other, pickup_location: "Castro", seats: 2)
    sign_in_as(@rider)

    post accept_carpool_seat_offer_path(@carpool, offer)

    assert_equal 0, @driver_ride.ride_claims.where(user: @rider).count
    assert SeatOffer.exists?(offer.id) # still pending; another seat may open up
  end

  test "only the offered rider can accept" do
    offer = SeatOffer.create!(carpool: @carpool, ride: @driver_ride, user: @rider)
    outsider = User.create!(name: "Jo", email: "jo@example.com")
    sign_in_as(outsider)

    post accept_carpool_seat_offer_path(@carpool, offer)

    assert_response :not_found
    assert_equal 0, @driver_ride.ride_claims.count
  end

  test "the board shows offer states to both sides" do
    sign_in_as(@driver)
    get carpool_path(@carpool)
    assert_select "form[action=?]", carpool_seat_offers_path(@carpool)

    offer = SeatOffer.create!(carpool: @carpool, ride: @driver_ride, user: @rider)
    get carpool_path(@carpool)
    assert_match(/Offer sent to Alex/, response.body)

    sign_in_as(@rider)
    get carpool_path(@carpool)
    assert_match(/Sam offered you a seat/, response.body)
    assert_select "form[action=?]", accept_carpool_seat_offer_path(@carpool, offer)
    assert_select "form[action=?]", decline_carpool_seat_offer_path(@carpool, offer)
  end
end
