class MainpageController < ApplicationController
 helper MainpageHelper
  X2T_FOLDER = "#{Rails.public_path}/x2t"
  RESULT_FOLDER = "#{Rails.public_path}/result_file"
  UPLOAD_FOLDER = "#{Rails.public_path}/custom_file"
  ARHIVE_FOLDER = "#{Rails.public_path}/arhive"

  def index
    @x2t_last = X2t.last
    @errors = ''
    if !params["result"].nil?
      send_file "public/result_file/#{params["result"]}"
    elsif !params["error"].nil?
      @errors = params["error"]
    end
  end

  def update
    # delete_files
    case
      when !params[:x2t].nil?
        uploaded_io = params[:x2t]
        File.open(Rails.root.join('public', 'x2t', uploaded_io.original_filename), 'wb') do |file|
          file.write(uploaded_io.read)
        end
        initial_training_x2t(uploaded_io.original_filename)
      when !params[:custom_file].nil?
        uploaded_io = params[:custom_file]
        File.open(Rails.root.join('public', 'custom_file', uploaded_io.original_filename), 'wb') do |file|
          file.write(uploaded_io.read)
        end
        result = initial_convertion_custom_file(uploaded_io.original_filename)
      when !params[:convert_all_from].nil? || !params[:convert_all_to].nil?
        convert_all
    end
    if File.exist?("public/result_file/#{result}")
      redirect_to :action => :index, :result => result
    else
      redirect_to :action => :index, :error => 'File not found'
    end
  end

  def initial_training_x2t(filename)
    file_path = "#{X2T_FOLDER}/#{filename}"
    @version = get_x2t_version(file_path)
    move_x2t_to_arhive_and_rename(file_path)
    add_x2t_to_db
  end

  def move_x2t_to_arhive_and_rename(file_path)
    @name = "#{@version}_#{Random.new_seed}"
    path_to_arhive = "#{X2T_FOLDER}/#{@name}"
    `echo qq | sudo -S mv #{file_path} \"#{path_to_arhive}\"`
  end

  def get_x2t_version(file_path)
    `echo qq | sudo -S chmod +x #{file_path}`
    command = "echo qq | sudo -S \"#{file_path}\""
    `#{command}`.scan(%r{Version:.*}).first
  end

  def add_x2t_to_db
    x2t = X2t.new
    x2t.version = @version
    x2t.name = @name
    x2t.save
  end

  def initial_convertion_custom_file(filename)
    convert_to = params['convert_to']
    file_path = "#{UPLOAD_FOLDER}/#{filename}"
    chmod_custom_file(file_path)
    convert_file(filename, convert_to).to_s
  end

  def chmod_custom_file(file_path)
    `echo qq | sudo -S chmod 777 \"#{file_path}\"`
  end

  def convert_file(input_filename, format)
    rand_folder_name = Random.new_seed
    `mkdir #{RESULT_FOLDER}/#{rand_folder_name}`
    bit_path = "#{X2T_FOLDER}/#{X2t.last.name}"
    input_filepath = "#{UPLOAD_FOLDER}/#{input_filename}"
    output_file_path = "#{RESULT_FOLDER}/#{rand_folder_name}/#{File.basename(input_filepath, '.*')}.#{format}"
    command = "echo qq | sudo -S \"#{bit_path}\" \"#{input_filepath}\" \"#{output_file_path}\""
    `#{command}`
    "#{rand_folder_name}/#{File.basename(input_filepath, '.*')}.#{format}"
  end

  def delete_files
    `echo qq | sudo -S rm -r #{RESULT_FOLDER}/*`
    `echo qq | sudo -S rm -r #{UPLOAD_FOLDER}/*`
  end

  def convert_all
    MainpageHelper::converter(ARHIVE_FOLDER,
                RESULT_FOLDER,
                "#{X2T_FOLDER}/#{X2t.last.name}", 'qq').convert(:xls => :xlsx)

  end

end
