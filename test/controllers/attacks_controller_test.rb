require "test_helper"

class AttacksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @attack = attacks(:one)
  end

  test "should get index" do
    get attacks_url
    assert_response :success
  end

  test "should get new" do
    get new_attack_url
    assert_response :success
  end

  test "should create attack" do
    assert_difference("Attack.count") do
      post attacks_url, params: { attack: { a: @attack.a, attack_type: @attack.attack_type, b: @attack.b } }
    end

    assert_redirected_to attack_url(Attack.last)
  end

  test "should show attack" do
    get attack_url(@attack)
    assert_response :success
  end

  test "should get edit" do
    get edit_attack_url(@attack)
    assert_response :success
  end

  test "should update attack" do
    patch attack_url(@attack), params: { attack: { a: @attack.a, attack_type: @attack.attack_type, b: @attack.b } }
    assert_redirected_to attack_url(@attack)
  end

  test "should destroy attack" do
    assert_difference("Attack.count", -1) do
      delete attack_url(@attack)
    end

    assert_redirected_to attacks_url
  end
end
