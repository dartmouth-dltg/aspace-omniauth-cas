# omniauthCas/backend/plugin_init.rb

require 'aspace_logger'
require 'omniauth-cas'

include JSONModel

begin

  logger = ASpaceLogger.new($stderr);
  OmniAuth.config.logger = logger

  logger.info("omniauthCas/backend: AppConfig[:omniauthCas]='#{AppConfig[:omniauthCas]}'")####

# Create our initial user, if we need to bootstrap access to the
# system: since we override the basic username/password authentication
# mechanism, there isn't any way to log in as the admin user when this
# plugin is installed.
  if ((initUserInfo = AppConfig[:omniauthCas][:initialUser]) &&
        !(initialUser = User.find(:username => initUserInfo[:username])))
#   Create our initial user.
    
    initialUser = User.create_from_json( JSONModel(:user).from_hash('username' => initUserInfo[:username],
                                             'name'     => initUserInfo[:name],
                                             'is_admin' => true) )
    logger.info("omniauthCas/backend: initialUser='#{initialUser}'")####
  end

end
