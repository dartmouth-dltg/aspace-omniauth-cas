# omniauthCas/backend/controllers/users.rb
require 'aspace_logger'
require 'omniauth-cas'

class ArchivesSpaceService < Sinatra::Base

  include JSONModel

  Endpoint.post('/users/:username/omniauthCas')
    .description("Authenticate via Omniauth/CAS")
    .params(["username", Username, "Your username"],
            ["url", String, "The url"],
            ["ticket", String, "Your ticket"],
            ["provider", String, "The authentication service provider"],
            ["expiring", BooleanParam, "true if the created session should expire",
             :default => true])
    .permissions([])
    .returns([200, "Login accepted"],
             [403, "Login failed"]) \
  do

    logger = ASpaceLogger.new($stderr)

    user      = nil
    json_user = nil
    session   = nil

    logger.debug("In endpoint/post/omniauthCas, username='#{params[:username]}'")####
    logger.debug("In endpoint/post/omniauthCas,      url='#{params[:url]}'")####
    logger.debug("In endpoint/post/omniauthCas, provider='#{params[:provider]}'")####
    logger.debug("In endpoint/post/omniauthCas,   ticket='#{params[:ticket]}'")####
####    request.env.each_pair  { |k, v|####
####      logger.info("request.env['#{k}']='#{v}'")####
####    }####
    logger.debug("request='#{request}'")####
####    logger.debug("request has methods:\n\t" + request.methods.sort.join("\n\t").to_s)####
####    request.instance_variables.each do |sym|####
####      logger.debug("request.#{sym}=#{request.instance_variable_get(sym)}")####
####    end####
####    logger.debug("OmniAuth.config.full_host='#{OmniAuth.config.full_host}'")####
####    OmniAuth.config.full_host = url####
####    logger.debug("OmniAuth.config.full_host='#{OmniAuth.config.full_host}'")####

#   We can only support CAS authentication.
    raise ArgumentError.new("Provider mismatch: '#{params[:provider]}' != 'cas'") if ('cas'.casecmp(params[:provider]) != 0)
#   We only allow users we know about to log in (essentially authorization).
    raise NotFoundException.new("Unknown user '#{params[:username]}'") if (!(user = User.find(:username => params[:username])))
####    logger.debug("user has methods:\n\t" + user.methods.sort.join("\n\t").to_s)####
    logger.debug("user.username='#{user.username}'")####

    begin
####      logger.debug("OmniAuth::Strategies::CAS has methods:\n\t" + OmniAuth::Strategies::CAS.methods.sort.join("\n\t").to_s)####
####      if ((user = User.find(:username => params[:username])))####
####        return json_response({:error => "Login failed: known user '#{params[:username]}'"}, 403)####
####      end####
####      logger.debug("JSONModel(:user) has methods:\n\t" + JSONModel(:user).methods.sort.join("\n\t").to_s)####
####      config  = AppConfig[:omniauthCas]####
#####     Kludge!####
####      config[:full_host] = config[:url] + '/'####
####      cas     = OmniAuth::Strategies::CAS.new(nil, config)####
      cas = OmniAuth::Strategies::CAS.new(nil, AppConfig[:omniauthCas])
####      logger.debug("cas has methods:\n\t" + cas.methods.sort.join("\n\t").to_s)####
      serviceUrl              = Addressable::URI.parse(params[:url])
      serviceUrl.path         = 'auth/' + params[:provider] + '/second'
      serviceUrl.query_values = { :url      => params[:url],
                                  :username => params[:username],
                                  :ticket   => params[:ticket] }
      logger.debug("serviceUrl='#{serviceUrl.to_s}'")####
      stv = OmniAuth::Strategies::CAS::ServiceTicketValidator.new(cas, cas.options, serviceUrl.to_s, params[:ticket]).call
####      logger.debug("stv has methods:\n\t" + stv.methods.sort.join("\n\t").to_s)####
      userInfo = stv.user_info
      logger.debug("      stv.user_info='#{userInfo}'")####
      logger.debug("stv.user_info.netid='#{userInfo['netid']}'")####
      logger.debug("  params[:username]='#{params[:username]}'")####
      raise ArgumentError.new("User mismatch: '#{params[:username]}' != '#{userInfo['netid']}'") if (params[:username].casecmp(userInfo['netid']) != 0)

      json_user = JSONModel(:user).from_hash(:username => userInfo['netid'],
                                             :name     => userInfo['name'],
                                             :email    => userInfo['user'])
      logger.debug("json_user='#{json_user}'")####
####      raise AccessDeniedException.new("Login denied for valid authentication of '#{params[:username]}': testing!")####

      begin
        user.update_from_json(json_user,
                              :lock_version => user.lock_version)
      rescue Sequel::NoExistingObject => fault
#	We'll swallow these because they only really mean that the
#	user logged in twice simultaneously.  As long as one of the
#	updates succeeded it doesn't really matter.
        Log.warn("Got an optimistic locking error when updating user: #{fault}")
        user = User.find(:username => params[:username])
      end

#     From backend/app/lib/auth_helpers.rb:
      session               = Session.new
      session[:user]        = params[:username]
      session[:login_time]  = Time.now
      session[:expirable]   = params[:expiring]
      session.save
      json_user             = User.to_jsonmodel(user)
      json_user.permissions = user.permissions

    rescue Exception => fault
      logger.debug('omniauthCas endpoint failed: ' + fault.message + "\n" + fault.backtrace.join("\n"))####
      raise AccessDeniedException.new(fault.message)
    end

    if (session && json_user)
      json_response({:session => session.id, :user => json_user})
    else
      json_response({:error => 'Login failed'}, 403)
    end

  end

end
