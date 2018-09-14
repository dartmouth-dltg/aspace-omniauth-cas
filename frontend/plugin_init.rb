# omniauthCas/frontend/plugin_init.rb

require 'aspace_logger'
require 'omniauth-cas'

OmniAuth.config.logger = ASpaceLogger.new($stderr)

unless AppConfig[:omniauthCas][:full_host].blank?
  OmniAuth.config.full_host = AppConfig[:omniauthCas][:full_host]
end
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :cas,
           AppConfig[:omniauthCas][:provider]
end

ArchivesSpace::Application.extend_aspace_routes(File.join(File.dirname(__FILE__), "routes.rb"))
