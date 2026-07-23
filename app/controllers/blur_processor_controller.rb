class BlurProcessorController < ApplicationController
  def index
    # 初期画面表示用
  end

  def process_video
    # フォームからアップロードされた動画ファイルを取得
    uploaded_file = params[:video]
    # ユーザーが選択したモード（"mosaic" または "blur"）を取得
    blur_mode = params[:blur_mode] || "mosaic"

    if uploaded_file.nil?
      flash[:alert] = "動画ファイルを選択してください。"
      redirect_to root_path and return
    end

    # 一時保存用のパスを設定
    input_path = Rails.root.join('tmp', "input_#{Time.now.to_i}.mp4")
    output_path = Rails.root.join('tmp', "output_#{Time.now.to_i}.mp4")

    # アップロードされたファイルを一時保存
    File.open(input_path, 'wb') do |file|
      file.write(uploaded_file.read)
    end

    # Pythonスクリプトのパス
    script_path = Rails.root.join('public', 'python', 'face_blur.py')

    # 実行環境に応じてPythonのパスを切り替え
    if Rails.env.production?
      # 本番環境（Render / Linux）の場合
      python_path = "python3"
    else
      # 開発環境（Windows）の場合
      python_path = "C:/Users/knt89/AppData/Local/Python/bin/python.exe"
    end

    # 外部コマンドの組み立て
    command = "#{python_path} \"#{script_path}\" \"#{input_path}\" \"#{output_path}\" \"#{blur_mode}\""

    # コマンドを実行し、エラーが発生した場合はログに出力
    logger.debug "Executing command: #{command}"
    stdout, stderr, status = Open3.capture3(command)

    if status.success?
      # 処理が成功した場合、生成された動画をダウンロードさせる
      send_file output_path, type: 'video/mp4', disposition: 'attachment', filename: "processed_video.mp4"
    else
      logger.error "Python script error: #{stderr}"
      flash[:alert] = "動画の処理中にエラーが発生しました。"
      redirect_to root_path
    end
  end
end