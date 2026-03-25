require "application_system_test_case"

class ExperimentsTest < ApplicationSystemTestCase
  setup do
    @experiment = experiments(:one)
  end

  test "visiting the index" do
    visit experiments_url

    assert_selector "h1", text: "Активные эксперименты"
  end

  test "should create experiment" do
    visit experiments_url
    click_on "Запустить эксперимент"

    select "Линейная (A:0.03, B:0.01)", from: "Конфигурация атаки"
    fill_in "Вероятность однократного обнаружения p(t)", with: "0.8"
    fill_in "Вероятность появления атаки p(ai)", with: "1.0"
    fill_in "Количество узлов (N)", with: "5"
    fill_in "Количество тестировщиков (K)", with: "3"
    click_on "Запустить симуляцию"

    assert_text "Experiment was successfully created."
    assert_selector "h1", text: "Анализ эксперимента"
  end

  test "should update experiment" do
    visit experiment_url(@experiment)
    click_on "Изменить параметры"

    fill_in "Количество тестировщиков (K)", with: "2"
    click_on "Запустить симуляцию"

    assert_text "Experiment was successfully updated."
    assert_text "Тестировщики (K)"
  end

  test "should destroy experiment" do
    visit experiment_url(@experiment)
    accept_confirm do
      click_on "Удалить"
    end

    assert_text "Experiment was successfully destroyed."
  end
end
