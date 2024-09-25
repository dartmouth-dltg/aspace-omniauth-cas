ArchivesSpace::Application.routes.draw do
  [AppConfig[:frontend_proxy_prefix], AppConfig[:frontend_prefix]].uniq.each do |prefix|
    scope prefix do
      get "auth/:provider/callback", to: "oac_session#first"
      get "auth/:provider/second", to: "oac_session#second"
      get "auth/:provider/logout", to: "oac_session#logout"
    end
  end
end
