TuskLock::Application.routes.draw do
  get "/works" => "application#works"
  get "/broken" => "application#broken"
end
