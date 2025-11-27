class ContactMailer < ApplicationMailer
  def support_message(name:, email:, category:, subject:, message:)
    @name = name
    @email = email
    @category = category
    @subject = subject
    @message = message
    
    mail(
      to: ENV["GMAIL_USERNAME"] || "recipysp@gmail.com",
      from: ENV["GMAIL_USERNAME"] || "recipysp@gmail.com",
      reply_to: email,
      subject: "[Recipy Support] #{category}: #{subject}"
    )
  end
end

