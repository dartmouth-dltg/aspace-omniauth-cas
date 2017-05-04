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

#   We can only support CAS authentication.
    if ('cas'.casecmp(params[:provider]) != 0)
      raise ArgumentError.new("Provider mismatch: '#{params[:provider]}' != 'cas'")
#   We only allow users we know about to log in (essentially authorization).
    elsif (!(user = User.find(:username => params[:username])))
      raise NotFoundException.new("Unknown user '#{params[:username]}'")
    end
    ####logger.debug("omniauthCas/backend:   user.username='#{user.username}'")####

    begin
      cas = OmniAuth::Strategies::CAS.new(nil, AppConfig[:omniauthCas][:provider])
      serviceUrl              = Addressable::URI.parse(params[:url])
      serviceUrl.path         = 'auth/' + params[:provider] + '/second'
      serviceUrl.query_values = { :url      => params[:url],
                                  :username => params[:username],
                                  :ticket   => params[:ticket] }
      ####logger.debug("omniauthCas/backend:    serviceUrl='#{serviceUrl.to_s}'")####
      stv      = OmniAuth::Strategies::CAS::ServiceTicketValidator.new(cas, cas.options, serviceUrl.to_s, params[:ticket]).call
      ####logger.debug("omniauthCas/backend: stv.user_info='#{stv.user_info}'")####
#     Use the (backend) lambdas to pull the information we need from stv.user_info.
      uid      = AppConfig[:omniauthCas][:backendUidProc].call(stv.user_info)
      email    = AppConfig[:omniauthCas][:backendEmailProc].call(stv.user_info)
      
      ## logger.debug("omniauthCas/backend:           #{stv.user_info.inspect}")####
#     If true, the authenticated user doesn't match the user the
#     frontend authenticated.
      if (params[:username].casecmp(uid) != 0)
        raise ArgumentError.new("User mismatch: '#{params[:username]}' != '#{uid}'")
      end

      json_user = JSONModel(:user).from_hash(:username => uid,
                                             :name     => stv.user_info['name'] || uid,
                                             :email    => email)

#     From backend/app/model/authentication_manager.rb:
      begin
        user.update_from_json(json_user,
                              :lock_version => user.lock_version)
      rescue Sequel::NoExistingObject => fault
#	We'll swallow these because they only really mean that the
#	user logged in twice simultaneously.  As long as one of the
#	updates succeeded it doesn't really matter.
        Log.warn("Got an optimistic locking error when updating user: #{fault}")
        user = User.find(:username => uid)
      end

#     From backend/app/lib/auth_helpers.rb:
      session               = Session.new
      session[:user]        = uid
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
