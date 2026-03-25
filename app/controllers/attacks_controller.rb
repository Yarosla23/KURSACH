class AttacksController < ApplicationController
  before_action :set_attack, only: %i[show edit update destroy]

  def index
    @attacks = Attack.all.order(created_at: :desc)
  end

  def show
    @classification_table = MethodologyReportService.classification_table
    @reference_failure_series = MethodologyReportService.reference_failure_series
    @failure_series = MethodologyReportService.failure_series_for(@attack)
    @weighted_failure_by_type = MethodologyReportService.weighted_failure_series_by_type
    @assignment = MethodologyReportService.general_list_assignment(1)
    @variant_linear_series = MethodologyReportService.variant_attack_series_group(
      @assignment[:attack_variants],
      attack_type: :linear
    )
    @variant_exponential_series = MethodologyReportService.variant_attack_series_group(
      @assignment[:attack_variants],
      attack_type: :exponential
    )
  end

  def new
    @attack = Attack.new
  end

  def edit
  end

  def create
    @attack = Attack.new(attack_params)

    respond_to do |format|
      if @attack.save
        format.html { redirect_to @attack, notice: "Attack was successfully created." }
        format.json { render :show, status: :created, location: @attack }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @attack.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @attack.update(attack_params)
        format.html { redirect_to @attack, notice: "Attack was successfully updated.", status: :see_other }
      else
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @attack.destroy!

    respond_to do |format|
      format.html { redirect_to attacks_path, notice: "Attack was successfully destroyed.", status: :see_other }
    end
  end

  private

  def set_attack
    @attack = Attack.find(params.expect(:id))
  end

  def attack_params
    params.expect(attack: [:attack_type, :a, :b])
  end
end
