Goldberg::Application.config.action_mailer.delivery_method = :smtp

Goldberg::Application.config.action_mailer.smtp_settings = {
  :address              => "smtp.pinnacol.com",
  :domain               => 'pinnacol.com',
  :port                 => 25
}

Goldberg::Application.config.action_mailer.default_url_options = {
  :host => "panda-dev.pinnacol.com"
}