# frozen_string_literal: true

Rails.application.routes.draw do
  resources :users, except: %i[new edit] do
    get  :me,      on: :collection
    post :sign_in, on: :collection
  end

  resources :campaigns, except: %i[new edit]
  resources :hierarchy_elements, except: %i[show new edit] do
    resources :content_texts, except: %i[show new edit], shallow: true do
      patch :reorder, on: :collection
    end
  end
end
