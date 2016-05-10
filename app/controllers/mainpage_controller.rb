class MainpageController < ApplicationController
  def index
    p 'params'
  end

  def update
    uploaded_io = params[:x2t]
    File.open(Rails.root.join('public', 'uploads', uploaded_io.original_filename), 'wb') do |file|
      file.write(uploaded_io.read)
    end
    initial_training(uploaded_io.original_filename)
    redirect_to :back
  end

  def initial_training(filename)
    file_path = "#{Rails.public_path}/uploads/#{filename}"
    @version = get_x2t_version(file_path)
    move_x2t_to_arhive_and_rename(file_path)
    add_x2t_to_db
  end

  def move_x2t_to_arhive_and_rename(file_path)
    @name = "#{@version}_#{Random.new_seed}"
    path_to_arhive = "//app/x2t/#{@name}"
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
end
