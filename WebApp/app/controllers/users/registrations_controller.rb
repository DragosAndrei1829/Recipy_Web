class Users::RegistrationsController < Devise::RegistrationsController
  before_action :configure_sign_up_params, only: [:create]
  before_action :configure_account_update_params, only: [:update]

  def create
    build_resource(sign_up_params)
    resource.save
    yield resource if block_given?
    if resource.persisted?
      # Skip confirmation for admins
      if resource.admin?
        resource.update_columns(confirmed_at: Time.current)
        set_flash_message! :notice, :signed_up if is_flashing_format?
        redirect_to new_user_session_path(locale: I18n.locale)
      else
        # Generate and send confirmation code for new users
        code = resource.generate_confirmation_code!
        ConfirmationMailer.send_confirmation_code(resource, code).deliver_now
        
        # Redirect to confirmation page
        set_flash_message! :notice, :signed_up_but_unconfirmed if is_flashing_format?
        redirect_to confirmation_path(user_id: resource.id, locale: I18n.locale)
      end
    else
      clean_up_passwords resource
      set_minimum_password_length
      respond_with resource
    end
  end

  def update_resource(resource, params)
    if params[:password].present? || params[:password_confirmation].present?
      super
    else
      resource.update_without_password(params.except(:current_password))
    end
  end

  def after_update_path_for(resource)
    edit_user_registration_path
  end

  protected

  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [:username, :email])
  end

  def configure_account_update_params
    devise_parameter_sanitizer.permit(:account_update, keys: [:avatar, :phone, :username])
  end
end
