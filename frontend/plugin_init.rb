# omniauthCas/frontend/plugin_init.rb

require 'aspace_logger'
require 'omniauth-cas'

OmniAuth.config.logger = ASpaceLogger.new($stderr)

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :cas, 
           :url                  => AppConfig[:omniauthCas][:url],
           :login_url            => AppConfig[:omniauthCas][:login_url],
           :service_validate_url => AppConfig[:omniauthCas][:service_validate_url],
           :uid_key              => AppConfig[:omniauthCas][:uid_key],
           :host                 => AppConfig[:omniauthCas][:host],
           :ssl                  => AppConfig[:omniauthCas][:ssl]
end

myRoutes = [ File.join(File.dirname(__FILE__), "routes.rb") ]
ArchivesSpace::Application.config.paths['config/routes'].concat(myRoutes)
