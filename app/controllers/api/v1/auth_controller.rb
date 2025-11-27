module Api
  module V1
    class AuthController < BaseController
      skip_before_action :authenticate_api_user!, only: [ :login, :register, :forgot_password, :refresh_token, :google, :apple ]

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

      # POST /api/v1/auth/google
      # Authenticate with Google ID token from mobile app
      def google
        return render_error("ID token is required", :bad_request) unless params[:id_token].present?

        # Verify the Google ID token
        payload = verify_google_token(params[:id_token])
        return render_error("Invalid Google token", :unauthorized) unless payload

        # Find or create user
        user = find_or_create_oauth_user(
          provider: "google_oauth2",
          uid: payload["sub"],
          email: payload["email"],
          name: payload["name"],
          first_name: payload["given_name"],
          last_name: payload["family_name"],
          avatar_url: payload["picture"]
        )

        if user.persisted?
          token = JsonWebToken.encode(user_id: user.id)
          refresh_token = JsonWebToken.encode({ user_id: user.id, type: "refresh" }, 30.days.from_now)

          render_success({
            token: token,
            refresh_token: refresh_token,
            expires_in: 7.days.to_i,
            user: user_json(user),
            new_user: user.created_at > 1.minute.ago
          })
        else
          render_error(user.errors.full_messages.join(", "), :unprocessable_entity)
        end
      end

      # POST /api/v1/auth/apple
      # Authenticate with Apple ID token from mobile app
      def apple
        return render_error("ID token is required", :bad_request) unless params[:id_token].present?

        # Verify the Apple ID token
        payload = verify_apple_token(params[:id_token])
        return render_error("Invalid Apple token", :unauthorized) unless payload

        # Apple may not provide name on subsequent logins, so we need to handle that
        user = find_or_create_oauth_user(
          provider: "apple",
          uid: payload["sub"],
          email: payload["email"],
          name: params[:full_name], # Apple sends name separately on first login
          first_name: params[:given_name],
          last_name: params[:family_name],
          avatar_url: nil # Apple doesn't provide avatar
        )

        if user.persisted?
          token = JsonWebToken.encode(user_id: user.id)
          refresh_token = JsonWebToken.encode({ user_id: user.id, type: "refresh" }, 30.days.from_now)

          render_success({
            token: token,
            refresh_token: refresh_token,
            expires_in: 7.days.to_i,
            user: user_json(user),
            new_user: user.created_at > 1.minute.ago
          })
        else
          render_error(user.errors.full_messages.join(", "), :unprocessable_entity)
        end
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

      def verify_google_token(id_token)
        require "net/http"
        require "json"

        # Google's token verification endpoint
        uri = URI("https://oauth2.googleapis.com/tokeninfo?id_token=#{id_token}")
        response = Net::HTTP.get_response(uri)

        return nil unless response.is_a?(Net::HTTPSuccess)

        payload = JSON.parse(response.body)

        # Verify the token is for our app
        valid_client_ids = [
          ENV["GOOGLE_CLIENT_ID"],
          ENV["GOOGLE_ANDROID_CLIENT_ID"],
          ENV["GOOGLE_IOS_CLIENT_ID"]
        ].compact

        return nil unless valid_client_ids.include?(payload["aud"])
        return nil if payload["exp"].to_i < Time.now.to_i

        payload
      rescue JSON::ParserError, StandardError => e
        Rails.logger.error "Google token verification failed: #{e.message}"
        nil
      end

      def verify_apple_token(id_token)
        require "jwt"
        require "net/http"
        require "json"

        # Fetch Apple's public keys
        uri = URI("https://appleid.apple.com/auth/keys")
        response = Net::HTTP.get_response(uri)
        return nil unless response.is_a?(Net::HTTPSuccess)

        keys = JSON.parse(response.body)["keys"]

        # Decode the token header to get the key ID
        header = JWT.decode(id_token, nil, false).last
        key_data = keys.find { |k| k["kid"] == header["kid"] }
        return nil unless key_data

        # Build the public key
        jwk = JWT::JWK.new(key_data)
        public_key = jwk.public_key

        # Verify and decode the token
        decoded = JWT.decode(
          id_token,
          public_key,
          true,
          {
            algorithm: "RS256",
            iss: "https://appleid.apple.com",
            aud: ENV["APPLE_CLIENT_ID"],
            verify_iss: true,
            verify_aud: true
          }
        )

        decoded.first
      rescue JWT::DecodeError, StandardError => e
        Rails.logger.error "Apple token verification failed: #{e.message}"
        nil
      end

      def find_or_create_oauth_user(provider:, uid:, email:, name:, first_name:, last_name:, avatar_url:)
        # First, try to find by OAuth identity
        identity = OauthIdentity.find_by(provider: provider, uid: uid)
        return identity.user if identity

        # Then, try to find by email
        user = User.find_by(email: email)

        if user
          # Link the OAuth identity to existing user
          user.oauth_identities.create!(provider: provider, uid: uid)
        else
          # Create new user
          username = generate_unique_username(email, name)
          user = User.new(
            email: email,
            username: username,
            first_name: first_name || name&.split&.first,
            last_name: last_name || name&.split&.drop(1)&.join(" "),
            password: Devise.friendly_token[0, 20],
            terms_accepted: true,
            privacy_policy_accepted: true
          )

          # Skip confirmation for OAuth users
          user.skip_confirmation! if user.respond_to?(:skip_confirmation!)

          if user.save
            user.oauth_identities.create!(provider: provider, uid: uid)

            # Download and attach avatar if provided
            attach_avatar_from_url(user, avatar_url) if avatar_url.present?
          end
        end

        user
      end

      def generate_unique_username(email, name)
        base = name&.parameterize&.underscore || email.split("@").first
        base = base.gsub(/[^a-z0-9_]/, "")[0, 15]
        username = base

        counter = 1
        while User.exists?(username: username)
          username = "#{base[0, 12]}#{counter}"
          counter += 1
        end

        username
      end

      def attach_avatar_from_url(user, url)
        return unless url.present?

        require "open-uri"
        downloaded_image = URI.open(url)
        user.avatar.attach(io: downloaded_image, filename: "avatar.jpg", content_type: "image/jpeg")
      rescue StandardError => e
        Rails.logger.error "Failed to download avatar: #{e.message}"
      end
    end
  end
end

