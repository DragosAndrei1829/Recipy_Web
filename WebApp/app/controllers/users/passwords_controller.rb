class Users::PasswordsController < Devise::PasswordsController
  protected

  # Override to redirect to login page after password reset (instead of signing in)
  def after_resetting_password_path_for(resource)
    new_user_session_path(locale: I18n.locale)
  end
end
