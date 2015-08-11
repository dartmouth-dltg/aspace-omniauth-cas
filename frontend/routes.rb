# omniauthCas/frontend/routes.rb

ArchivesSpace::Application.routes.draw do
  get "/auth/:provider/callback", to: "oac_session#first"
  get "/auth/:provider/second",   to: "oac_session#second"
end
