class ConfirmationMailer < ApplicationMailer
  def send_confirmation_code(user, code)
    @user = user
    @code = code
    @expires_in = 15 # minutes
    
    mail(
      to: @user.email,
      subject: t('confirmation.email.subject', code: @code)
    )
  end
end
