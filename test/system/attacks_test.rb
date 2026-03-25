require "application_system_test_case"

class AttacksTest < ApplicationSystemTestCase
  setup do
    @attack = attacks(:one)
  end

  test "visiting the index" do
    visit attacks_url
    assert_selector "h1", text: "Attacks"
  end

  test "should create attack" do
    visit attacks_url
    click_on "New attack"

    fill_in "A", with: @attack.a
    fill_in "Attack type", with: @attack.attack_type
    fill_in "B", with: @attack.b
    click_on "Create Attack"

    assert_text "Attack was successfully created"
    click_on "Back"
  end

  test "should update Attack" do
    visit attack_url(@attack)
    click_on "Edit this attack", match: :first

    fill_in "A", with: @attack.a
    fill_in "Attack type", with: @attack.attack_type
    fill_in "B", with: @attack.b
    click_on "Update Attack"

    assert_text "Attack was successfully updated"
    click_on "Back"
  end

  test "should destroy Attack" do
    visit attack_url(@attack)
    click_on "Destroy this attack", match: :first

    assert_text "Attack was successfully destroyed"
  end
end
