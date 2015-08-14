ArchivesSpace authentication with OmniAuth/CAS
==================================

Getting started
-------------

Download and unpack the latest release of the plugin into your
ArchivesSpace plugins directory:

```
	$ curl ...
	$ cd /path/to/archivesspace/plugins
    $ unzip ...
```

Initialize the `omniauthCas` plugin:

```
     # For Linux/OSX
     $ scripts/initialize-plugin.sh omniauthCas
     
     # For Windows
     % scripts\initialize-plugin.bat omniauthCas
```

Configure the plugin by adding the following to your ArchivesSpace
configuration file (`config/config.rb`), modified as appropriate to
your situation:

```
	AppConfig[:omniauthCas] = {
		:url => 'https://<CAS-SERVER-HOST>',
		:login_url => '/cas/login',
		:service_validate_url => '/cas/serviceValidate',
		:uid_key => 'user',
		:host => '<CAS-SERVER-HOST>',
		:ssl => true,
		:auth_hash_uid => [ '<OA_CAS_AUTH_HASH_UID_KEY1>', '<OA_CAS_AUTH_HASH_UID_KEY1>', ],
		:user_info_uid => '<OA_CAS_USER_INFO_UID_KEY>',
		:user_info_email => '<OA_CAS_USER_INFO_UID_KEY>',
		:email_convert_spaces => true,
#       :initialUser => { :username => '<USER_ID>',
#                         :name     => '<USER-NAME', },
	}
```

If you don't have any users in your ArchivesSpace install, you can
bootstrap an initial user by uncommenting (and configuring) a local
admin user.

The `:auth_hash_uid`, `:user_info_uid`, and `:user_info_email` values
allow parameterized access of the OmniAuth/CAS data structures.  They
can be single keys, or arrays of keys, if the OmniAuth/CAS payload has
nested hashes.  The `:user_info_*` keys are used to access the
`user_info` hash returned by
`OmniAuth::Strategies::CAS::ServiceTicketValidator#user_info` method.

The `:email_convert_spaces` flag indicates that whitespace in the
value needs to be converted to periods to make a valid email address.

Activate the `omniauthCas` plugin (uncommenting the `:plugins` line if
necessary) by adding `omniauthCas` to the list of plugins:

```
	AppConfig[:plugins] = [ 'other_plugin', 'omniauthCas' ]
```

Start, or restart ArchivesSpace to pick up the configuration.

Technical Details
---------------

The following is based on my understanding of ArchivesSpace's
architecture, and may not be completely correct:

ArchivesSpace is composed of multiple servers (backend, frontend,
public).  The frontend server mediates access to the backend server,
but the backend server doesn't trust the frontend server to
authenticate users (see the Authentication Manager code in the backend
server).  This plugin allows users to authenticate to the frontend
server and then the backend server, allowing the backend server to
create a session for the user.

Using the OmniAuth CAS strategy, the frontend server authenticates the
user.  The "Sign In" link on the home page is overridden (see
`frontend/views/shared/_header_user.html.erb`) to direct the user
through the OmniAuth/CAS flow, which, if successful, results in the
authenticated user passing through the `OacSessionController#first`
method (in `frontend/controllers/oac_session_controller.rb`).  This
method contructs a new CAS login URL with the service URL pointing at
`OacSessionController#second` (also in
`frontend/controllers/oac_session_controller.rb`).  This method
accepts the redirect from the CAS server without processing the CAS
ticket, so that the pristine ticket can be sent to the backend server
(the `/users/<USERNAME>/omniauthCas` endpoint in
`backend/controller/users.rb`).

When the `/users/<USERNAME>/omniauthCas` endpoint (in
`backend/controller/users.rb`) is invoked, it verifies that the user
that authenticated to the frontend is a valid ArchivesSpace user
before using the OmniAuth/CAS machinery to validate the pristine CAS
ticket.  If successful, the user's information in ArchivesSpace (name,
email) are updated from the CAS payload, and then a session is created
for the user and returned to the frontend.

A CAS proxy ticket might be better used than the ticket generation in
the frontend `OacSessionController#second` method, above, but lacking
specific support in OmniAuth/CAS for that part of the protocol, the
above seemed most workable.

Eric J. Bivona (<Eric.J.Bivona@Dartmouth.EDU>)  
Digital Library Technologies Group  
Dartmouth College Library  

---
