Rails.application.routes.draw do
  root 'blur_processor#index'
  post 'blur_processor/upload', to: 'blur_processor#upload'
  get 'blur_processor/result', to: 'blur_processor#result'

  # 一時保存フォルダ内の動画にアクセスするためのルーティング
  get '/temp/:filename', to: 'blur_processor#download_temp', constraints: { filename: /[^\/]+/ }
end
