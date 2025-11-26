class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def google_oauth2
    @user = User.from_omniauth(request.env['omniauth.auth'])
    
    if @user.persisted?
      sign_in_and_redirect @user, event: :authentication
      set_flash_message(:notice, :success, kind: 'Google') if is_navigational_format?
    else
      session['devise.google_data'] = request.env['omniauth.auth'].except(:extra)
      locale = session[:locale] || I18n.default_locale
      redirect_to "/#{locale}/users/sign_up", alert: @user.errors.full_messages.join("\n")
    end
  end

  def apple
    @user = User.from_omniauth(request.env['omniauth.auth'])
    
    if @user.persisted?
      sign_in_and_redirect @user, event: :authentication
      set_flash_message(:notice, :success, kind: 'Apple') if is_navigational_format?
    else
      session['devise.apple_data'] = request.env['omniauth.auth'].except(:extra)
      locale = session[:locale] || I18n.default_locale
      redirect_to "/#{locale}/users/sign_up", alert: @user.errors.full_messages.join("\n")
    end
  end

  def failure
    redirect_to root_path, alert: t('devise.omniauth_callbacks.failure', kind: 'OAuth', reason: 'unknown')
  end
end

