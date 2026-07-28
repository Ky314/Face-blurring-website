class BlurProcessorController < ApplicationController
  def index
    # 初期画面表示用
  end

  def process_video
    # Open3を使うためのrequire（もしファイル上部に無い場合のため）
    require 'open3'

    # フォームからアップロードされた動画ファイルを取得[cite: 1]
    uploaded_file = params[:video]
    # ユーザーが選択したモード（"mosaic" または "blur"）を取得[cite: 1]
    blur_mode = params[:blur_mode] || "mosaic"

    if uploaded_file.nil?
      flash[:alert] = "動画ファイルを選択してください。"
      redirect_to root_path and return
    end

    # 一時保存用ではなく、ブラウザからpublic経由でアクセスできるように public/outputs に保存する
    output_dir = Rails.root.join('public', 'outputs')
    FileUtils.mkdir_p(output_dir)

    timestamp = Time.now.to_i
    input_path = Rails.root.join('tmp', "input_#{timestamp}.mp4")
    
    # プレビュー表示用にファイル名を固定・一意にして public/outputs に保存する
    output_filename = "processed_#{timestamp}.mp4"
    output_path = output_dir.join(output_filename)

    # アップロードされたファイルを一時保存[cite: 1]
    File.open(input_path, 'wb') do |file|
      file.write(uploaded_file.read)
    end

    # Pythonスクリプトのパス[cite: 1]
    script_path = Rails.root.join('public', 'python', 'face_blur.py')

    # 実行環境に応じてPythonのパスを切り替え[cite: 1]
    if Rails.env.production?
      python_path = "python3"
    else
      # 開発環境（Windows）の場合[cite: 1]
      python_path = "C:/Users/knt89/AppData/Local/Python/bin/python.exe"
    end

    # 外部コマンドの組み立て[cite: 1]
    command = "#{python_path} \"#{script_path}\" \"#{input_path}\" \"#{output_path}\" \"#{blur_mode}\""

    # コマンドを実行し、エラーが発生した場合はログに出力[cite: 1]
    logger.debug "Executing command: #{command}"
    stdout, stderr, status = Open3.capture3(command)

    # 不要になった入力側の一時ファイルを削除
    File.delete(input_path) if File.exist?(input_path)

    if status.success? && File.exist?(output_path)
      # 処理が成功した場合、結果表示用のアクションへファイル名をパラメータ付きでリダイレクト
      redirect_to result_blur_processor_path(filename: output_filename)
    else
      logger.error "Python script error: #{stderr}"
      flash[:alert] = "動画の処理中にエラーが発生しました。"
      redirect_to root_path
    end
  end

  def result
    # リクエストされたファイル名を受け取り、ビューへURLを渡す
    @filename = params[:filename]
    @video_url = "/outputs/#{@filename}"
    
    if @filename.blank? || !File.exist?(Rails.root.join('public', 'outputs', @filename))
      flash[:alert] = "処理済み動画が見つからないか、有効期限が切れています。"
      redirect_to root_path
    end
  end
end