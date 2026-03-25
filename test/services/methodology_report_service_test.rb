require "test_helper"

class MethodologyReportServiceTest < ActiveSupport::TestCase
  test "builds methodology classification values close to the sample table" do
    row = MethodologyReportService.classification_table.find { |item| item[:t] == 13 }

    assert_in_delta 0.40, row[:lin_n], 0.01
    assert_in_delta 0.61, row[:lin_s], 0.01
    assert_in_delta 0.81, row[:lin_v], 0.01
    assert_in_delta 0.44, row[:exp_n], 0.01
    assert_in_delta 0.72, row[:exp_s], 0.01
    assert_in_delta 0.93, row[:exp_v], 0.02
    assert_equal "Высокий", row[:exp_v_meta][:name]
  end

  test "uses p(t) directly for collaborative grid" do
    grid = MethodologyReportService.collab_grid_for(p_t: 0.9)
    row = grid.find { |item| item[:n] == 5 }

    assert_in_delta ProbabilityService.collab_test(0.9, 3, 5), row[:values][3], 1e-9
  end

  test "builds assignment for first student in general list" do
    assignment = MethodologyReportService.general_list_assignment(1)

    assert_equal [2, 5, 9], assignment[:attack_variants]
    assert_equal 2, assignment[:detection_variant]
    assert_in_delta 0.75, assignment[:detection_probabilities][:high], 1e-9
    assert_in_delta 0.47, assignment[:detection_probabilities][:low], 1e-9
  end

  test "keeps linear and exponential parameters aligned with methodology table" do
    variant = MethodologyReportService::ATTACK_VARIANTS.fetch(2)

    assert_equal({a: 0.035, b: 0.015}, variant[:linear])
    assert_equal({a: 0.8, b: 0.045}, variant[:exponential])
  end
end
