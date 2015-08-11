# omniauthCas/frontend/controllers/oac_session_controller.rb

require 'omniauth-cas'

class OacSessionController < SessionController

  skip_before_filter :unauthorised_access

  def first

    ####    self.logger.debug('*** DEBUG/first: entering OacSessionController')####
    ####    self.logger.debug("self has methods:\n\t" + self.methods.sort.join("\n\t").to_s)####
    username = auth_hash.extra.netid
    ####    self.logger.debug("*** DEBUG/first:          params=#{params}")####
    ####    self.logger.debug("*** DEBUG/first:       auth_hash=#{auth_hash}")####
    ####    self.logger.debug("*** DEBUG/first:  username/NetID=#{username}")####
    serviceUrl               = Addressable::URI.parse(params[:url])
    serviceUrl.path          = "auth/#{params[:provider]}/second"
    serviceUrl.query_values  = { :url      => params[:url],
                                 :username => username }                                    
    redirectUrl              = Addressable::URI.parse(AppConfig[:omniauthCas][:url])
    redirectUrl.path         = AppConfig[:omniauthCas][:login_url]
    redirectUrl.query_values = { :service => serviceUrl.to_s }
    ####    self.logger.debug("*** DEBUG/first: init/second/URL=#{redirectUrl.to_s}")####

    ####    self.logger.debug('*** DEBUG/first: about to leave OacSessionController')####
    redirect_to redirectUrl.to_s

  end

  def second

    ####    self.logger.debug('*** DEBUG/second: entering OacSessionController')####
    ####    self.logger.debug("self has methods:\n\t" + self.methods.sort.join("\n\t").to_s)####

    ####    self.logger.debug("*** DEBUG: auth has methods:\n\t" + auth.methods.sort.join("\n\t").to_s)####
    ####    self.logger.debug("*** DEBUG:         params=#{params}")####

    if ((backend_session = self.authn(params[:username], params[:url], params[:ticket])))
      User.establish_session(self, backend_session, params[:username])
    else
      redirect_to '/' and return
    end

    self.logger.debug('*** DEBUG/second: leaving OacSessionController')####

    ####    load_repository_list

    ####    render :json => {:session => backend_session, :csrf_token => form_authenticity_token}

    redirect_to :controller => :welcome, :action => :index

  end

  def authn(username, url, ticket)

####    request.env.each_pair  { |k, v|####
####      logger.info("request.env['#{k}']='#{v}'")####
####    }####

    uri      = JSONModel(:user).uri_for("#{username}/omniauthCas")
    response = JSONModel::HTTP.post_form(uri,
                                         :url      => params[:url],
                                         :ticket   => params[:ticket],
                                         :provider => params[:provider])

    self.logger.debug("*** DEBUG: response.code=#{response.code}/#{response.body}")
    if (response.code == '200')
      ASUtils.json_parse(response.body)
    else
      flash[:error] = I18n.t("authn for '#{username}' failed: " + response.code + '/' + response.body)
      nil
    end

  end

  protected

  def auth_hash
    request.env['omniauth.auth']
  end
  
end
