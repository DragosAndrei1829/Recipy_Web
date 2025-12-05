# frozen_string_literal: true

module Api
  module V1
    class ReportsController < BaseController
      before_action :set_reportable

      # POST /api/v1/recipes/:recipe_id/reports
      # POST /api/v1/users/:user_id/reports
      def create
        # Check if user already reported this content
        existing_report = @reportable.reports.find_by(reporter: current_user)
        if existing_report
          return render json: {
            success: false,
            error: 'already_reported',
            message: 'You have already reported this content'
          }, status: :unprocessable_entity
        end

        @report = @reportable.reports.build(report_params)
        @report.reporter = current_user

        if @report.save
          render json: {
            success: true,
            message: 'Report submitted successfully',
            data: {
              id: @report.id,
              reportable_type: @report.reportable_type,
              reportable_id: @report.reportable_id,
              reason: @report.reason,
              status: @report.status,
              created_at: @report.created_at
            }
          }, status: :created
        else
          render json: {
            success: false,
            errors: @report.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # GET /api/v1/reports/reasons
      def reasons
        render json: {
          success: true,
          data: Report::REASONS.map do |key, label|
            {
              key: key.to_s,
              label_ro: label,
              label_en: I18n.t("reports.reasons.#{key}", locale: :en, default: key.to_s.titleize)
            }
          end
        }
      end

      # GET /api/v1/reports/my_reports
      def my_reports
        reports = current_user.reported_content.includes(:reportable).order(created_at: :desc)
        
        render json: {
          success: true,
          data: reports.map do |report|
            {
              id: report.id,
              reportable_type: report.reportable_type,
              reportable_id: report.reportable_id,
              reason: report.reason,
              reason_label: report.reason_label,
              description: report.description,
              status: report.status,
              created_at: report.created_at,
              reviewed_at: report.reviewed_at
            }
          end
        }
      end

      private

      def set_reportable
        if params[:recipe_id]
          @reportable = Recipe.find_by(id: params[:recipe_id])
          unless @reportable
            return render json: { success: false, error: 'Recipe not found' }, status: :not_found
          end
        elsif params[:user_id]
          @reportable = User.find_by(id: params[:user_id])
          unless @reportable
            return render json: { success: false, error: 'User not found' }, status: :not_found
          end
          # Can't report yourself
          if @reportable == current_user
            return render json: { success: false, error: 'You cannot report yourself' }, status: :unprocessable_entity
          end
        else
          render json: { success: false, error: 'Invalid report target' }, status: :bad_request
        end
      end

      def report_params
        params.require(:report).permit(:reason, :description)
      end
    end
  end
end




