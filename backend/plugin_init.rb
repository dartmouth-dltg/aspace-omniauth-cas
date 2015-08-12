# omniauthCas/backend/plugin_init.rb

require 'aspace_logger'
require 'omniauth-cas'

begin

  logger = ASpaceLogger.new($stderr);
  OmniAuth.config.logger = logger

  logger.info("omniauthCas: AppConfig[:omniauthCas]='#{AppConfig[:omniauthCas]}'")####

# Create our initial user, if we need to bootstrap access to the
# system: since we override the basic username/password authentication
# mechanism, there isn't any way to log in as the admin user when this
# is installed.
  if ((initUserInfo = AppConfig[:omniauthCas][:initialUser]))

#   Generate the set of permissions we want our initial user to have.
    permissions     = []
    permissionCodes = [ 'system_config', 'administer_system', 'manage_users', 'become_user' ]
    Permission.each do |permission|
      if ((idx = permissionCodes.find_index { |code|
             code == permission.permission_code
           }) != nil)
        permissions.push(permission)
        permissionCodes.delete_at(idx)
        logger.info("Found permission #{permission.permission_code} (#{permissionCodes.length} remain).")####
      end
    end

#   Create our initial user.
    if (!(initialUser = User.find(:username => initUserInfo[:username])))
      initialUser = JSONModel(:user).from_hash('username'   => initUserInfo[:username],
                                               'name'       => initUserInfo[:name],
                                               'is_admin'   => true)
    end
    ####logger.info("omniauthCas: initialUser='#{initialUser}'")####

#   Configure our initial user.
    begin
      initialUser.save(:password    => SecureRandom.hex,
                       :permissions => permissions)
    rescue ValidationException => error
      logger.error("omniauthCas/initialUser.save: #{error}")####
      initialUser.update(:permissions => permissions)
      initialUser.refetch    
    end

    logger.info("omniauthCas: Created/updated initial user account for username '#{initialUser.username}' with permissions:")####
    initialUser.permissions.each do |permission|####
      logger.info("#{permission}")####
    end####

  end

end
