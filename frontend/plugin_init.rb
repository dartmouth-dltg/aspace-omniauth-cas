# omniauthCas/frontend/plugin_init.rb

require 'aspace_logger'
require 'omniauth-cas'

OmniAuth.config.logger = ASpaceLogger.new($stderr)

ArchivesSpace::Application.extend_aspace_routes(File.join(File.dirname(__FILE__), "routes.rb"))

unless AppConfig[:omniauthCas][:full_host].blank?
  OmniAuth.config.full_host = AppConfig[:omniauthCas][:full_host]
end

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :cas,
           AppConfig[:omniauthCas][:provider]
end

Rails.application.config.after_initialize do
  # remove the option to start a login from the front end unless it goes through omniauth controller
  class SessionController < ApplicationController
  
    def login
      backend_session = nil
  
      if backend_session
        User.establish_session(self, backend_session, params[:username])
      end
  
      load_repository_list
  
      render :json => {:session => backend_session, :csrf_token => form_authenticity_token}
    end
    
  end

end