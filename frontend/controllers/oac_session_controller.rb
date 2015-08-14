# omniauthCas/frontend/controllers/oac_session_controller.rb

require 'omniauth-cas'

class OacSessionController < SessionController

  skip_before_filter :unauthorised_access

# Our first target for authentication, going through the OmniAuth/CAS
# strategy in the "normal" fashion.  As a filter, this ensures that
# the user can be authenticated before doing anything more with
# ArchivesSpace.  The user is then redirected to our second target,
# below, by way of the CAS login service, to generate a new ticket.
  def first

#   :local_uid can be an ordered set of keys to work through the
#   auth_hash to get to the value we use for "username".
    username                 = auth_hash
    uidKeyPath               = ((AppConfig[:omniauthCas][:auth_hash_uid].is_a?(Array)) \
                                ? AppConfig[:omniauthCas][:auth_hash_uid]
                                : [ AppConfig[:omniauthCas][:auth_hash_uid] ])
    uidKeyPath.each do |key|
      username               = username[key]
    end
    serviceUrl               = Addressable::URI.parse(params[:url])
    serviceUrl.path          = "auth/#{params[:provider]}/second"
    serviceUrl.query_values  = { :url      => params[:url],
                                 :username => username }                                    
    redirectUrl              = Addressable::URI.parse(AppConfig[:omniauthCas][:url])
    redirectUrl.path         = AppConfig[:omniauthCas][:login_url]
    redirectUrl.query_values = { :service => serviceUrl.to_s }

    redirect_to redirectUrl.to_s

  end

# Our second target, which takes the new CAS ticket of the
# authenticated user (from the redirect in #first, above), and sends
# it to the backend to validate this new, pristine ticket, thus
# authenticating the user to the backend.  See
# omniauthCas/backend/controller/users.rb for the
# /user/<USERNAME>/omniauthCas endpoint.
  def second

    uri      = JSONModel(:user).uri_for("#{params[:username]}/omniauthCas")
    response = JSONModel::HTTP.post_form(uri,
                                         :url      => params[:url],
                                         :ticket   => params[:ticket],
                                         :provider => params[:provider])

    ####self.logger.debug("omniauthCas/second: response.code=#{response.code}/#{response.body}")####
    if (response.code != '200')
      flash[:error] = I18n.t("Authentication for '#{params[:username]}' failed: " +
                             response.code + '/' + response.body)
      redirect_to '/' and return
    end

    backend_session = ASUtils.json_parse(response.body)
    User.establish_session(self, backend_session, params[:username])

#   From frontend/controller/session.rb (#become_user).
    redirect_to :controller => :welcome, :action => :index

  end

  protected

  def auth_hash
    request.env['omniauth.auth']
  end
  
end
