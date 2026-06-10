class ExperimentsController < ApplicationController
  before_action :set_experiment, only: %i[show edit update destroy]

  def index
    @experiments = Experiment.all.order(created_at: :desc)
    @assignment = MethodologyReportService.general_list_assignment(1)
    @detection_surface_high = MethodologyReportService.collab_probability_surface_config(
      p_t: @assignment[:detection_probabilities][:high]
    )
    @detection_surface_low = MethodologyReportService.collab_probability_surface_config(
      p_t: @assignment[:detection_probabilities][:low]
    )
  end

  def show
    @results = @experiment.experiment_results.order(:t)
    @collab_grid = MethodologyReportService.collab_grid_for(p_t: @experiment.p_single)
    @comparison_analysis = ExperimentComparisonService.new(@experiment).call
    @runtime_comparison_analysis = ExperimentRuntimeComparisonService.new(@experiment).call
    @single_base_by_k = (1..5).map do |k|
      [k, ProbabilityService.single_test(@experiment.p_single, k)]
    end
    @collab_base_by_n = (1..8).map do |n|
      {
        name: "n=#{n}",
        data: (1..5).filter_map do |k|
          next unless k <= n

          [k, ProbabilityService.collab_test(@experiment.p_single, k, n)]
        end
      }
    end.select { |series| series[:data].any? }
    @experiment_surface = MethodologyReportService.experiment_surface_config(
      experiment: @experiment,
      results: @results
    )
  end

  def new
    @experiment = Experiment.new
  end

  def edit
  end

  def create
    @experiment = Experiment.new(experiment_params)

    respond_to do |format|
      if @experiment.save
        ExperimentRunner.new(@experiment).run
        format.html { redirect_to @experiment, notice: "Experiment was successfully created." }
      else
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @experiment.update(experiment_params)
        ExperimentRunner.new(@experiment).run
        format.html { redirect_to @experiment, notice: "Experiment was successfully updated.", status: :see_other }
      else
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @experiment.destroy!

    respond_to do |format|
      format.html { redirect_to experiments_path, notice: "Experiment was successfully destroyed.", status: :see_other }
    end
  end

  private

  def set_experiment
    @experiment = Experiment.find(params.expect(:id))
  end

  def experiment_params
    params.expect(experiment: [:attacks_id, :p_single, :p_ai, :n, :k])
  end
end
