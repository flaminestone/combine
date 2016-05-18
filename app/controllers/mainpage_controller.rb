require 'zip'
class MainpageController < ApplicationController
  skip_before_filter :verify_authenticity_token
 helper MainpageHelper
  X2T_FOLDER = "#{Rails.public_path}/x2t"
  RESULT_FOLDER = "#{Rails.public_path}/result_file"
  UPLOAD_FOLDER = "#{Rails.public_path}/custom_file"
  ARHIVE_FOLDER = "#{Rails.public_path}/arhive"

  def index
    @x2t_last = X2t.last
    @errors = ''
    @all_convertation_result = ''
    $status = {} if $status.nil?
    @all = $status[:all]
    @current = $status[:current]
    @x2t_name = $status[:x2t]
    @data = $status[:data]
    @runing_status = $status[:runing]

    if !params["result"].nil?
      send_file "public/result_file/#{params["result"]}"
    elsif !params["error"].nil?
      @errors = params["error"]
    elsif $status[:runing] == false
      @all_convertation_result = "/public/result_file/#{$status[:result]}"
    end
  end

  def update
    case
      when !params[:x2t].nil?
        uploaded_io = params[:x2t]
        File.open(Rails.root.join('public', 'x2t', uploaded_io.original_filename), 'wb') do |file|
          file.write(uploaded_io.read)
        end
        initial_training_x2t(uploaded_io.original_filename)
        redirect_to :action => :index
      when !params[:custom_file].nil?
        uploaded_io = params[:custom_file]
        File.open(Rails.root.join('public', 'custom_file', uploaded_io.original_filename), 'wb') do |file|
          file.write(uploaded_io.read)
        end
        result = initial_convertion_custom_file(uploaded_io.original_filename)
        if File.exist?("public/result_file/#{result}") && !result.nil?
          redirect_to :action => :index, :result => result
        else
          redirect_to :action => :index, :error => 'File not found'
        end
      when !params[:convert_all_from].nil? || !params[:convert_all_to].nil?
        convert_all
        redirect_to :action => :index
    end
  end

 def result_page
   send_file "public/result_file/#{$status[:result]}"
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
    rand_folder_name = Random.new_seed
    `mkdir #{RESULT_FOLDER}/#{rand_folder_name}`
    input_files_folder = "#{ARHIVE_FOLDER}/#{params['convert_all_from']}"
    output_files_folder = "#{RESULT_FOLDER}/#{rand_folder_name}"
    bin_path = "#{X2T_FOLDER}/#{X2t.last.name}"
    result_folder = "#{output_files_folder}/#{params['convert_all_from']}_to_#{params['convert_all_to']}"
    $status = {current: nil, all: nil, result: nil, :runing => true, :x2t => "#{X2t.last.name}"}
    Thread.new do
      MainpageHelper::converter(input_files_folder,
                                output_files_folder,
                                bin_path, 'qq').convert(params['convert_all_from'] => params['convert_all_to'])

      add_result_files_to_zip(result_folder, "#{result_folder}.zip")
      $status[:result] = "#{rand_folder_name}/#{params['convert_all_from']}_to_#{params['convert_all_to']}.zip"
      $status[:runing] = false
      $status[:data] = Time.now
    end
  end

  def add_result_files_to_zip(input_data, output_data)
    MainpageHelper::zip_generator(input_data, output_data).write()
  end

  def get_current_result_number
    respond_to do |format|
      # format.html { render :xml => "<progress value=#{$status[:current]} max=#{$status[:all]} ></progress>" }
      format.json { render :json => $status.to_json }
    end
  end
end
