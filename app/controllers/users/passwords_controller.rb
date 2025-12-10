class Users::PasswordsController < Devise::PasswordsController
  # Override create to handle errors better
  def create
    self.resource = resource_class.send_reset_password_instructions(resource_params)
    
    if successfully_sent?(resource)
      respond_with({}, location: after_sending_reset_password_instructions_path_for(resource_name))
    else
      respond_with(resource)
    end
  rescue => e
    Rails.logger.error "Password reset error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    
    # Check if it's a mailer configuration issue
    if e.message.include?("mailer") || e.message.include?("SMTP") || e.message.include?("delivery")
      flash[:alert] = "Serviciul de email nu este configurat. Te rugăm să contactezi suportul."
    else
      flash[:alert] = "A apărut o eroare. Te rugăm să încerci din nou sau să contactezi suportul."
    end
    
    redirect_to new_user_password_path(locale: I18n.locale)
  end

  protected

  # Override to redirect to login page after password reset (instead of signing in)
  def after_resetting_password_path_for(resource)
    new_user_session_path(locale: I18n.locale)
  end
end
