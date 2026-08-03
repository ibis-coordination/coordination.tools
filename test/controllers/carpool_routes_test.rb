require "test_helper"

class CarpoolRoutesTest < ActionDispatch::IntegrationTest
  test "carpool routes live under /carpool" do
    assert_equal "/carpool", new_carpool_path
    assert_equal "/carpool", carpools_path # create
    assert_equal "/carpool/abc123", carpool_path("abc123")
    assert_equal "/carpool/abc123/edit", edit_carpool_path("abc123")
    assert_equal "/carpool/abc123/rides", carpool_rides_path("abc123")
    assert_routing "/carpool", controller: "carpools", action: "new"
    assert_routing "/carpool/abc123", controller: "carpools", action: "show", public_id: "abc123"
  end
end
