require "test_helper"

class MyCarpoolsTest < ActionDispatch::IntegrationTest
  setup do
    @organizer = User.create!(name: "Organizer", email: "organizer@example.com")
    @carpool = @organizer.carpools.create!(name: "Beach day", destination: "Ocean Beach", starts_at: 2.days.from_now)
  end

  test "the homepage lists carpools you organize, drive in, or ride in" do
    driver = User.create!(name: "Sam", email: "sam@example.com")
    passenger = User.create!(name: "Alex", email: "alex@example.com")
    driven = @organizer.carpools.create!(name: "Hike", destination: "Tam", starts_at: 3.days.from_now)
    ridden = @organizer.carpools.create!(name: "Show", destination: "The Fillmore", starts_at: 4.days.from_now)
    unrelated = @organizer.carpools.create!(name: "Secret", destination: "Nowhere", starts_at: 5.days.from_now)
    ride = driven.rides.create!(user: driver, role: "driver", origin: "Mission", seats: 3)
    show_ride = ridden.rides.create!(user: driver, role: "driver", origin: "Mission", seats: 3)
    show_ride.ride_claims.create!(carpool: ridden, user: passenger, pickup_location: "Castro", seats: 1)

    sign_in_as(driver)
    get root_path
    assert_select "a[href=?]", carpool_path(driven)
    assert_select "a[href=?]", carpool_path(ridden)
    assert_select "a[href=?]", carpool_path(unrelated), count: 0

    sign_in_as(passenger)
    get root_path
    assert_select "a[href=?]", carpool_path(ridden)
    assert_select "a[href=?]", carpool_path(driven), count: 0

    sign_in_as(@organizer)
    get root_path
    assert_select "a[href=?]", carpool_path(@carpool)
    assert_select "a[href=?]", carpool_path(unrelated)
  end

  test "signed-out visitors see no carpool list" do
    get root_path
    assert_select "a[href=?]", carpool_path(@carpool), count: 0
  end

  test "the owner can delete a carpool" do
    sign_in_as(@organizer)

    assert_difference("Carpool.count", -1) do
      delete carpool_path(@carpool)
    end
    assert_redirected_to root_path
    assert_raises(ActiveRecord::RecordNotFound) { Carpool.find(@carpool.id) }
  end

  test "deleting a carpool removes its rides and claims" do
    driver = User.create!(name: "Sam", email: "sam@example.com")
    ride = @carpool.rides.create!(user: driver, role: "driver", origin: "Mission", seats: 3)
    ride.ride_claims.create!(carpool: @carpool, user: User.create!(name: "Alex", email: "alex@example.com"), pickup_location: "Castro", seats: 1)
    sign_in_as(@organizer)

    delete carpool_path(@carpool)

    assert_equal 0, Ride.where(carpool_id: @carpool.id).count
    assert_equal 0, RideClaim.where(carpool_id: @carpool.id).count
  end

  test "only the owner can delete a carpool" do
    other = User.create!(name: "Sam", email: "sam@example.com")
    sign_in_as(other)

    assert_no_difference("Carpool.count") do
      delete carpool_path(@carpool)
    end
    assert_response :not_found
  end

  test "the edit page offers deletion to the owner" do
    sign_in_as(@organizer)
    get edit_carpool_path(@carpool)

    assert_select "form[action=?] button", carpool_path(@carpool)
  end
end
