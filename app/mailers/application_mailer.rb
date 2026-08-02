class ApplicationMailer < ActionMailer::Base
  default from: "no-reply@coordination.tools"
  layout "mailer"
end
