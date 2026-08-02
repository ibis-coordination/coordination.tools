require "test_helper"

class SessionsControllerTest < ActionController::TestCase
  tests SessionsController

  test "signing in discards pre-existing session state" do
    post :create, params: { user: { name: "Alex", email: "alex@example.com" } }, session: { planted: "by attacker" }

    assert_nil session[:planted]
    assert_equal User.find_by!(email: "alex@example.com").id, session[:user_id]
  end

  test "signing in still honors a stored return path" do
    post :create, params: { user: { name: "Alex", email: "alex@example.com" } }, session: { return_to: "/carpools/abc123" }

    assert_redirected_to "/carpools/abc123"
  end
end
