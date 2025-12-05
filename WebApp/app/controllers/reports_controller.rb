class ReportsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_reportable

  def new
    @report = Report.new
  end

  def create
    @report = @reportable.reports.build(report_params)
    @report.reporter = current_user

    if @report.save
      respond_to do |format|
        format.html { redirect_back fallback_location: root_path, notice: t('reports.created') }
        format.turbo_stream { render turbo_stream: turbo_stream.replace("report-button-#{@reportable.class.name.downcase}-#{@reportable.id}", partial: 'reports/reported_badge') }
        format.json { render json: { success: true, message: t('reports.created') } }
      end
    else
      respond_to do |format|
        format.html { redirect_back fallback_location: root_path, alert: @report.errors.full_messages.join(', ') }
        format.turbo_stream { render turbo_stream: turbo_stream.replace("report-form", partial: 'reports/form', locals: { report: @report, reportable: @reportable }) }
        format.json { render json: { success: false, errors: @report.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  private

  def set_reportable
    if params[:recipe_id]
      @reportable = Recipe.find(params[:recipe_id])
    elsif params[:user_id]
      @reportable = User.find(params[:user_id])
    else
      redirect_to root_path, alert: t('reports.invalid_target')
    end
  end

  def report_params
    params.require(:report).permit(:reason, :description)
  end
end




