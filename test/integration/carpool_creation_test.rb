require "test_helper"

class CarpoolCreationTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  VALID_DETAILS = { name: "Beach day", destination: "Ocean Beach", starts_at: "2026-09-01T10:00" }.freeze

  test "the create form is shown without signing in" do
    get new_carpool_path

    assert_response :success
    assert_select "input[name='user[name]']"
    assert_select "input[name='user[email]']"
  end

  test "a new visitor creates a carpool in one step" do
    post carpools_path, params: { carpool: VALID_DETAILS, user: { name: "Fresh", email: "fresh@example.com" } }

    user = User.find_by!(email: "fresh@example.com")
    carpool = Carpool.find_by!(name: "Beach day")
    assert_equal user, carpool.user
    assert_redirected_to carpool_path(carpool)

    get edit_carpool_path(carpool)
    assert_response :success # signed in as the owner
  end

  test "an existing email finishes carpool creation after the magic link" do
    existing = User.create!(name: "Organizer", email: "organizer@example.com")

    assert_no_difference("Carpool.count") do
      assert_enqueued_emails 1 do
        post carpools_path, params: { carpool: VALID_DETAILS, user: { email: "organizer@example.com" } }
      end
    end

    get confirm_session_path(token: existing.generate_token_for(:magic_link))

    carpool = Carpool.find_by!(name: "Beach day")
    assert_equal existing, carpool.user
    assert_redirected_to carpool_path(carpool)
  end

  test "invalid carpool details re-render with your info intact" do
    assert_no_difference("User.count") do
      post carpools_path, params: { carpool: VALID_DETAILS.merge(name: "", destination: ""), user: { name: "Fresh", email: "fresh@example.com" } }
    end

    assert_response :unprocessable_entity
    assert_select "input[name='user[email]'][value=?]", "fresh@example.com"
  end
end
