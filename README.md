ArchivesSpace authentication with OmniAuth/CAS
==================================

Getting started
-------------

- Download and unpack the latest release of the plugin into your ArchivesSpace plugins directory:

```
	$ curl ...
	$ cd /path/to/archivesspace/plugins
    $ unzip 
```

- Initialize the `omniauthCas` plugin:

```
     # For Linux/OSX
     $ scripts/initialize-plugin.sh omniauthCas
     
     # For Windows
     % scripts\initialize-plugin.bat omniauthCas
```

- Configure the plugin by adding the following to your ArchivesSpace configuration file (`config/config.rb`), modified as appropriate to your situation:

```
	AppConfig[:omniauthCas] = {
		:url => 'https://<CAS-SERVER-HOST>',
		:login_url => '/cas/login',
		:service_validate_url => '/cas/serviceValidate',
		:uid_key => 'user',
		:host => '<CAS-SERVER-HOST>',
		:ssl => true,
####  :initialUser => { :username => '<USER_ID>',
####                             :name     => '<USER-NAME', },
	}
```

- If you don't have any users in your ArchivesSpace install, you can bootstrap an initial user by uncommenting (and configuring) a local admin user.

- Activate the `omniauthCas` plugin (uncommenting the `:plugins` line if necessary) by adding `omniauthCas` to the list of plugins:

```
	AppConfig[:plugins] = [ 'other_plugin', 'omniauthCas' ]
```

- Start, or restart ArchivesSpace to pick up the configuration.

---
