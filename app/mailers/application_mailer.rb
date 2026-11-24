class ApplicationMailer < ActionMailer::Base
  default from: -> { Rails.application.config.x.mail_from },
          reply_to: -> { Rails.application.config.x.mail_reply_to }
  layout "mailer"
end
