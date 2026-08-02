require "test_helper"

class CarpoolTest < ActiveSupport::TestCase
  test "creates a shareable public id" do
    user = User.create!(name: "Sam", email: "sam@example.com")
    carpool = user.carpools.create!(name: "Beach day", destination: "Ocean Beach", starts_at: 2.days.from_now)
    assert carpool.public_id.present?
    assert_equal carpool.public_id, carpool.to_param
  end

  test "the return trip cannot start before the event" do
    user = User.create!(name: "Sam", email: "sam@example.com")
    carpool = user.carpools.new(name: "Beach day", destination: "Ocean Beach", starts_at: 2.days.from_now, return_starts_at: 1.day.from_now)
    assert_not carpool.valid?
    assert carpool.errors[:return_starts_at].any?
  end
end
