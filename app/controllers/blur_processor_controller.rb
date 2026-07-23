require 'open3'

class BlurProcessorController < ApplicationController
  def index
    # アップロードフォームを表示 (index.html.erb)
  end

  def upload
    if params[:video].blank?
      flash[:alert] = "動画ファイルを選択してください。"
      redirect_to root_path and return
    end

    uploaded_file = params[:video]
    # 画面から選択されたモードを取得（未選択の場合は 'mosaic'）
    blur_mode = params[:blur_mode].presence || 'mosaic'

    temp_dir = Rails.root.join("storage", "temp")
    FileUtils.mkdir_p(temp_dir) unless Dir.exist?(temp_dir)

    file_id = SecureRandom.uuid
    input_filename = "#{file_id}_#{uploaded_file.original_filename}"
    output_filename = "#{file_id}_blurred_#{uploaded_file.original_filename}"

    input_path = temp_dir.join(input_filename)
    output_path = temp_dir.join(output_filename)

    File.open(input_path, "wb") do |file|
      file.write(uploaded_file.read)
    end

    script_path = Rails.root.join("python_engine", "processor.py").to_s
    python_path = "C:/Users/knt89/AppData/Local/Python/bin/python.exe"
    
    # モード引数を追加してPythonを実行
    command = "\"#{python_path}\" \"#{script_path}\" \"#{input_path}\" \"#{output_path}\" \"#{blur_mode}\""
    
    Rails.logger.debug "=== Python Execution Start ==="
    Rails.logger.debug "Command: #{command}"

    stdout_str, stderr_str, status = Open3.capture3(command)

    if status.success?
      Rails.logger.debug "=== Python Execution Success ==="
      redirect_to blur_processor_result_path(file_name: output_filename)
    else
      Rails.logger.error "=== Python Execution Failed ==="
      Rails.logger.error stderr_str
      flash[:alert] = "動画の処理中にエラーが発生しました: #{stderr_str}"
      redirect_to root_path
    end
  end

  def result
    @output_filename = params[:file_name]
    @download_path = "/temp/#{CGI.escape(@output_filename)}"
  end

  def download_temp
    filename = params[:filename]
    file_path = Rails.root.join("storage", "temp", filename)

    if File.exist?(file_path)
      send_file file_path, disposition: 'inline'
    else
      head :not_found
    end
  end
end