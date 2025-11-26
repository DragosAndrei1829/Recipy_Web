class Users::SessionsController < Devise::SessionsController
  # Custom sessions controller to permit :login parameter
  before_action :configure_sign_in_params, only: [:create, :new]
  prepend_before_action :process_login_param, only: [:create, :new]

  protected

  def configure_sign_in_params
    devise_parameter_sanitizer.permit(:sign_in, keys: [:login, :password, :remember_me, :email, :username])
  end

  # Override sign_in_params to keep :login parameter (Devise will use it via find_for_database_authentication)
  def sign_in_params
    # Process login param first (ensure it's set)
    process_login_param
    
    # Get the sanitized params - keep :login for authentication, but don't pass it to User model
    base_params = params.fetch(:user, {}).permit(:login, :password, :remember_me)
    
    # Log for debugging
    Rails.logger.info "SessionsController#sign_in_params: #{base_params.inspect}"
    
    base_params
  end

  # Ensure :login parameter is set (it should already be from the form)
  def process_login_param
    return unless params[:user]
    
    # If :login is not present but :email or :username is, convert them
    if params[:user][:login].blank?
      if params[:user][:email].present?
        params[:user][:login] = params[:user][:email]
        params[:user].delete(:email)
        Rails.logger.info "process_login_param: converted email to login"
      elsif params[:user][:username].present?
        params[:user][:login] = params[:user][:username]
        params[:user].delete(:username)
        Rails.logger.info "process_login_param: converted username to login"
      end
    end
  end

  # Override to prevent Devise from trying to create a User with :login attribute
  def build_resource(hash = {})
    # Remove :login from hash before building resource
    hash = hash.dup
    hash.delete(:login) if hash.key?(:login)
    super(hash)
  end
end

