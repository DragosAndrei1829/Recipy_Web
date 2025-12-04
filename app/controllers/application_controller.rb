class ApplicationController < ActionController::Base
  allow_browser versions: :modern
  
  include DeviceHelper
  helper_method :mobile_device?, :tablet_device?, :desktop_device?

  before_action :set_locale, unless: :admin_route?
  around_action :tag_request_log
  
  layout :layout_by_resource

  rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
  rescue_from ActionController::RoutingError, with: :handle_not_found
  rescue_from ActionController::ParameterMissing, with: :handle_bad_request
  rescue_from ActiveRecord::RecordInvalid, with: :handle_unprocessable_entity
  rescue_from StandardError, with: :handle_internal_error

  stale_when_importmap_changes

  helper_method :available_quick_filters

  def available_quick_filters
    [
      { slug: "under20", icon: "clock", label: I18n.t("filters.quick_under_20"), params: { max_time: 20 } },
      { slug: "hi9", icon: "star", label: I18n.t("filters.quick_high_rating"), params: { min_rating: 9 } },
      { slug: "easy", icon: "sparkles", label: I18n.t("filters.quick_easy"), params: { min_difficulty: 1, max_time: 30 } },
      { slug: "light", icon: "leaf", label: I18n.t("filters.quick_low_cal"), params: { max_calories: 400 } }
    ]
  end

  def set_locale
    I18n.locale = params[:locale] || session[:locale] || I18n.default_locale
    session[:locale] = I18n.locale
  end

  def admin_route?
    request.path.start_with?("/admin") || request.path.start_with?("/adminDashboard")
  end

  def default_url_options(_options = {})
    if request && (request.path.start_with?("/admin") || request.path.start_with?("/adminDashboard"))
      {}
    else
      { locale: I18n.locale }
    end
  end

  def switch_locale
    locale = params[:locale].to_sym
    if I18n.available_locales.include?(locale)
      session[:locale] = locale
      I18n.locale = locale
      referer = request.referer || root_path
      uri = URI.parse(referer)
      path = uri.path
      path = path.gsub(/^\/(ro|en)/, "")
      new_path = "/#{locale}#{path}"
      new_path = "/#{locale}" if new_path == "/#{locale}/"
      redirect_to new_path
    else
      redirect_back(fallback_location: root_path)
    end
  end

  def after_sign_in_path_for(_resource)
    root_path
  end

  def after_sign_out_path_for(_resource)
    root_path
  end

  private

  def tag_request_log
    request_id = request.uuid
    Rails.logger.tagged(request_id) { yield }
  end

  def handle_not_found(error)
    render_error(:not_found, "errors/not_found", error, I18n.t("errors.not_found"))
  end

  def handle_bad_request(error)
    render_error(:bad_request, "errors/not_found", error, I18n.t("errors.bad_request"))
  end

  def handle_unprocessable_entity(error)
    render_error(:unprocessable_entity, "errors/not_found", error, error.record&.errors&.full_messages&.to_sentence || I18n.t("errors.unprocessable"))
  end

  def handle_internal_error(error)
    render_error(:internal_server_error, "errors/internal_server_error", error, I18n.t("errors.internal"))
  end

  def render_error(status, template, error, message)
    error_id = SecureRandom.uuid
    log_error(error, error_id)

    respond_to do |format|
      format.html { render template, status:, locals: { error_id:, message: } }
      format.turbo_stream { render template, formats: [ :html ], status:, locals: { error_id:, message: } }
      format.json { render json: { error: message, error_id: error_id }, status: }
    end
  end

  def log_error(error, error_id)
    Rails.logger.error("[#{error_id}] #{error.class}: #{error.message}")
    Rails.logger.error(error.backtrace.first(15).join("\n")) if error.backtrace.present?
  end
  
  private
  
  def layout_by_resource
    if devise_controller?
      "auth"
    else
      "application"
    end
  end
end
