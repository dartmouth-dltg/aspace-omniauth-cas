ArchivesSpace::Application.routes.draw do
  [AppConfig[:frontend_proxy_prefix], AppConfig[:frontend_prefix]].uniq.each do |prefix|
    scope prefix do
      match("/auth/:provider/callback" => "oac_session#first", :via => [:get])
      match("/auth/:provider/second" => "oac_session#second", :via => [:get])
      match("/auth/:provider/logout" => "oac_session#logout", :via => [:get])
    end
  end
end
