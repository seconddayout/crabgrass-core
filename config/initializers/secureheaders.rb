SecureHeaders::Configuration.default do |config|
  config.cookies = {
    secure: true,
    httponly: true,
    samesite: {
      strict: true
    }
  }
  report_only = Rails.env.production?
  config.csp = {
    default_src: %w('self'),
    script_src: %w('self' 'unsafe-inline' 'unsafe-eval' blob:),
    img_src: %w('self' * data: blob:),
    media_src: ['*'],
    style_src: %w(* 'unsafe-inline'),
    report_uri: ["/csp_report?report_only=#{report_only}"]
  }
  config.csp_report_only = config.csp.merge({
    default_src: %w('self'),
    script_src: %w('self' 'unsafe-inline' 'unsafe-eval' ),
    img_src: %w('self' * data:),
    media_src: ['*'],
    style_src: %w(* 'unsafe-inline'),
    report_uri: ["/csp_report?report_only=#{report_only}"]
  })
end
