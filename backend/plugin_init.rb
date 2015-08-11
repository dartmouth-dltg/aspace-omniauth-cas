# omniauthCas/backend/plugin_init.rb

require 'aspace_logger'
require 'omniauth-cas'

begin

  logger = ASpaceLogger.new($stderr);
  OmniAuth.config.logger = logger

  logger.debug("DEBUG: AppConfig[:omniauthCas]='#{AppConfig[:omniauthCas]}'")####

# Create our initial user, if we need to.
  if ((initUserInfo = AppConfig[:omniauthCas][:initialUser]))

    ####    admin = JSONModel(:user).find(1)####
    ####    logger.debug(admin.username + ': ' + ((admin.is_admin) ? '(admin)' : '') + " #{admin.permissions}")####

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

    logger.info("Permissions:")####
    permissions.each do |permission|####
      logger.info("\t#{permission.permission_code}: #{permission.description}")####
    end####

#   Create our initial user.
    if (!(initialUser = User.find(:username => initUserInfo[:username])))
      initialUser = JSONModel(:user).from_hash('username'   => initUserInfo[:username],
                                               'name'       => initUserInfo[:name],
                                               'is_admin'   => true)
    end

    logger.debug("#{initialUser}")####
#   Configure our initial user.
    begin
      initialUser.save(:password    => SecureRandom.hex,
                       :permissions => permissions)
    rescue ValidationException => error
      logger.error("initialUser.save: #{error}")####
      ####      logger.debug("error has methods:\n\t" + error.methods.sort.join("\n\t").to_s);####
      ####      logger.debug("error.errors has methods:\n\t" + error.errors.methods.sort.join("\n\t").to_s);####
      error.errors.each do |error|####
        logger.debug("#{error}")####
      end####
      initialUser.update(:permissions => permissions)
      initialUser.refetch    
    end

    ####    logger.debug("initialUser has methods:\n\t" + initialUser.methods.sort.join("\n\t").to_s);####
    ####    logger.debug("Permissions has methods:\n\t" + Permission.methods.sort.join("\n\t").to_s);####

    logger.info("Created/updated initial user account for username '#{initialUser.username}' with permissions:")####
    initialUser.permissions.each do |permission|####
      logger.info("#{permission}")####
    end####
####    logger.info("\tis_admin:    #{initialUser.is_admin}")####
####    logger.info("\tpermissions: " + initialUser.permissions.sort.join(', '))####

  end

end
