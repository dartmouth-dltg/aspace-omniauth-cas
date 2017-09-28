# omniauthCas/frontend/plugin_init.rb

require 'aspace_logger'
require 'omniauth-cas'

OmniAuth.config.logger = ASpaceLogger.new($stderr)

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :cas,
           AppConfig[:omniauthCas][:provider]
end

ArchivesSpace::Application.extend_aspace_routes(File.join(File.dirname(__FILE__), "routes.rb"))
