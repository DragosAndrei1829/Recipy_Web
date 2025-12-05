module Api
  module V1
    class AuthController < BaseController
      skip_before_action :authenticate_api_user!, only: [ :login, :register, :forgot_password, :refresh_token ]

      # POST /api/v1/auth/login
      def login
        user = User.find_for_database_authentication(login: params[:login])

        if user&.valid_password?(params[:password])
          if user.access_locked?
            render_error("Account is locked. Please try again later or contact support.", :forbidden)
          else
            token = JsonWebToken.encode(user_id: user.id)
            refresh_token = JsonWebToken.encode({ user_id: user.id, type: "refresh" }, 30.days.from_now)

            render_success({
              token: token,
              refresh_token: refresh_token,
              expires_in: 7.days.to_i,
              user: user_json(user)
            })
          end
        else
          # Increment failed attempts if user exists
          user&.increment_failed_attempts if user&.respond_to?(:increment_failed_attempts)
          render_error("Invalid login credentials", :unauthorized)
        end
      end

      # POST /api/v1/auth/register
      def register
        user = User.new(register_params)

        if user.save
          # Generate confirmation code and send email
          code = user.generate_confirmation_code!
          ConfirmationMailer.send_confirmation_code(user, code).deliver_later

          token = JsonWebToken.encode(user_id: user.id)
          refresh_token = JsonWebToken.encode({ user_id: user.id, type: "refresh" }, 30.days.from_now)

          render_success({
            token: token,
            refresh_token: refresh_token,
            expires_in: 7.days.to_i,
            user: user_json(user),
            message: "Registration successful. Please check your email for confirmation code."
          }, :created)
        else
          render_error(user.errors.full_messages.join(", "), :unprocessable_entity)
        end
      end

      # POST /api/v1/auth/logout
      def logout
        # For JWT, logout is handled client-side by removing the token
        # We could implement a token blacklist here if needed
        render_success({ message: "Logged out successfully" })
      end

      # POST /api/v1/auth/refresh_token
      def refresh_token
        header = request.headers["Authorization"]
        return render_error("No token provided", :unauthorized) unless header.present?

        token = header.split(" ").last
        decoded = JsonWebToken.decode(token)

        if decoded && decoded[:type] == "refresh"
          user = User.find_by(id: decoded[:user_id])
          if user
            new_token = JsonWebToken.encode(user_id: user.id)
            render_success({
              token: new_token,
              expires_in: 7.days.to_i
            })
          else
            render_error("User not found", :unauthorized)
          end
        else
          render_error("Invalid refresh token", :unauthorized)
        end
      end

      # POST /api/v1/auth/forgot_password
      def forgot_password
        user = User.find_by(email: params[:email])

        if user
          user.send_reset_password_instructions
          render_success({ message: "Password reset instructions sent to your email" })
        else
          # Don't reveal if email exists
          render_success({ message: "If the email exists, password reset instructions will be sent" })
        end
      end

      # POST /api/v1/auth/change_password
      def change_password
        if current_api_user.valid_password?(params[:current_password])
          if current_api_user.update(password: params[:new_password], password_confirmation: params[:new_password_confirmation])
            render_success({ message: "Password changed successfully" })
          else
            render_error(current_api_user.errors.full_messages.join(", "), :unprocessable_entity)
          end
        else
          render_error("Current password is incorrect", :unauthorized)
        end
      end

      # POST /api/v1/auth/verify_email
      def verify_email
        if current_api_user.confirm_email_with_code!(params[:code])
          render_success({
            message: "Email verified successfully",
            user: user_json(current_api_user.reload)
          })
        else
          render_error("Invalid or expired confirmation code", :unprocessable_entity)
        end
      end

      # POST /api/v1/auth/resend_confirmation
      def resend_confirmation
        code = current_api_user.generate_confirmation_code!
        ConfirmationMailer.send_confirmation_code(current_api_user, code).deliver_later

        render_success({ message: "Confirmation code sent to your email" })
      end

      # GET /api/v1/auth/me
      def me
        render_success({ user: user_json(current_api_user) })
      end

      private

      def register_params
        params.permit(:email, :username, :password, :password_confirmation, :first_name, :last_name, :terms_accepted, :privacy_policy_accepted)
      end

      def user_json(user)
        {
          id: user.id,
          email: user.email,
          username: user.username,
          first_name: user.first_name,
          last_name: user.last_name,
          avatar_url: user.avatar.attached? ? url_for(user.avatar) : nil,
          email_confirmed: user.email_confirmed?,
          created_at: user.created_at,
          followers_count: user.followers.count,
          following_count: user.following.count,
          recipes_count: user.recipes.count
        }
      end
    end
  end
end




