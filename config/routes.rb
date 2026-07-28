Rails.application.routes.draw do
  root 'blur_processor#index'
  post 'process_video', to: 'blur_processor#process_video'
  get 'result', to: 'blur_processor#result', as: 'result_blur_processor'
end
