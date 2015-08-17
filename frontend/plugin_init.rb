# omniauthCas/frontend/plugin_init.rb

require 'aspace_logger'
require 'omniauth-cas'

OmniAuth.config.logger = ASpaceLogger.new($stderr)

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :cas,
           AppConfig[:omniauthCas][:provider]
end

myRoutes = [ File.join(File.dirname(__FILE__), "routes.rb") ]
ArchivesSpace::Application.config.paths['config/routes'].concat(myRoutes)
