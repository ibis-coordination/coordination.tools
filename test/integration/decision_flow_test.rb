require "test_helper"

class DecisionFlowTest < ActionDispatch::IntegrationTest
  test "a visitor creates, shares, adds options, votes, and closes a decision" do
    post decisions_path, params: { decision: { question: "Where should we eat?" }, user: { name: "Ada", email: "ada@example.com" } }
    decision = Decision.find_by!(question: "Where should we eat?")
    assert_redirected_to decision_path(decision)

    post decision_decision_options_path(decision), params: { decision_option: { title: "Cafe" } }
    option = decision.decision_options.find_by!(title: "Cafe")
    post decision_decision_vote_path(decision), params: { accepted_option_ids: [option.id], preferred_option_ids: [option.id] }
    assert_redirected_to decision_path(decision)
    assert decision.decision_votes.find_by!(user: decision.user, decision_option: option).preferred?

    post close_decision_path(decision), params: { final_statement: "Cafe it is." }
    assert decision.reload.closed?
    assert_equal "Cafe it is.", decision.final_statement
  end

  test "results stay hidden until the viewer votes" do
    owner = User.create!(name: "Owner", email: "owner2@example.com")
    decision = owner.decisions.create!(question: "Pick one")
    decision.decision_options.create!(title: "A", user: owner)
    get decision_path(decision)
    assert_response :success
    assert_select "h2", text: "Results", count: 0
  end
end
