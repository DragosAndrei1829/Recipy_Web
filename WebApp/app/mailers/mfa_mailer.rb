class MfaMailer < ApplicationMailer
  # Send MFA code to user
  def send_code(user, code)
    @user = user
    @code = code
    @expires_in = 10 # minutes
    
    mail(
      to: @user.email,
      subject: t('mfa.email.subject', code: @code)
    )
  end
end

