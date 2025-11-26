class ApplicationMailer < ActionMailer::Base
  default from: ENV["GMAIL_USERNAME"] || "recipy_support@gmail.com"
  layout "mailer"
end
