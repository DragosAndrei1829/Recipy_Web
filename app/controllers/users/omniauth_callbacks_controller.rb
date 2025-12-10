# frozen_string_literal: true

class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  skip_before_action :verify_authenticity_token, only: [:google_oauth2, :apple, :failure, :passthru]

  def google_oauth2
    handle_oauth("Google")
  end

  def apple
    # Apple Sign In is not yet configured
    locale = session[:locale] || I18n.default_locale
    redirect_to "/#{locale}/users/sign_in", alert: "🚧 Sign in with Apple este în lucru. Te rugăm să folosești Google sau email."
  end

  def passthru
    # Handle locale parameter from query string or form data
    if params[:locale].present?
      session[:locale] = params[:locale]
    end
    
    # Get the provider from the path (e.g., /users/auth/google_oauth2 -> google_oauth2)
    provider = request.path.split('/').last
    
    # Check if provider is configured
    unless Devise.omniauth_configs[provider.to_sym]
      locale = session[:locale] || I18n.default_locale
      redirect_to "/#{locale}/users/sign_in", alert: "Provider de autentificare neconfigurat. Te rugăm să contactezi suportul."
      return
    end
    
    # If provider is configured, OmniAuth middleware should have handled this
    # If we reach here, something went wrong - redirect back to sign in
    locale = session[:locale] || I18n.default_locale
    redirect_to "/#{locale}/users/sign_in", alert: "Eroare la inițierea autentificării. Te rugăm să încerci din nou."
  end

  def failure
    locale = session[:locale] || I18n.default_locale
    error_type = params[:message] || request.env["omniauth.error.type"]
    
    error_message = case error_type&.to_s
    when "authenticity_error", "csrf_detected"
      "Te rugăm să încerci din nou."
    when "invalid_credentials"
      "Credențiale invalide."
    when "timeout"
      "Conexiunea a expirat."
    else
      "A apărut o eroare. Te rugăm să încerci din nou."
    end
    
    Rails.logger.error "OmniAuth failure: #{error_type} - #{error_message}"
    
    redirect_to "/#{locale}/users/sign_in", alert: "Autentificarea a eșuat: #{error_message}"
  end

  protected

  def handle_oauth(kind)
    auth_data = request.env["omniauth.auth"]
    
    if auth_data.nil?
      Rails.logger.error "OmniAuth #{kind}: No auth data received"
      return redirect_to_failure("Nu am primit date de autentificare de la #{kind}")
    end

    @user = User.from_omniauth(auth_data)

    if @user.persisted?
      flash[:notice] = I18n.t("devise.omniauth_callbacks.success", kind: kind)
      sign_in_and_redirect @user, event: :authentication
    else
      session["devise.#{kind.downcase}_data"] = auth_data.except(:extra)
      locale = session[:locale] || I18n.default_locale
      redirect_to "/#{locale}/users/sign_up", alert: @user.errors.full_messages.join(", ")
    end
  rescue StandardError => e
    Rails.logger.error "OmniAuth #{kind} error: #{e.message}"
    redirect_to_failure("Eroare la autentificarea cu #{kind}: #{e.message}")
  end

  def redirect_to_failure(message)
    locale = session[:locale] || I18n.default_locale
    redirect_to "/#{locale}/users/sign_in", alert: message
  end
end
