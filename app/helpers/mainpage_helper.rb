require 'find'
require 'zip'
module MainpageHelper
  def self.converter(base_file_folder, output_folder, bin_path, pass)
    Converter.new(base_file_folder, output_folder, bin_path, pass)
  end

  def self.zip_generator(input_dir, output_file)
    ZipFileGenerator.new(input_dir, output_file)
  end
end

class Converter
  # @param [String] base_file_folder is a path to folder with all files. Can contains files other formats
  # @param [String] output_folder is a path to folder for put files after convert
  # @param [String] bin_path is a path to x2t file
  # @param [String] pass is a password to admit on computer
  def initialize(base_file_folder, output_folder, bin_path, pass)
    @base_file_folder = base_file_folder
    @base_output_folder = output_folder
    @bin_path = bin_path
    @pass = pass
    @base_file_folder.chop! if @base_file_folder.rindex('/') == (@base_file_folder.size - 1)
    @base_output_folder.chop! if @base_output_folder.rindex('/') == (@base_output_folder.size - 1)
  end

  # @param [String] path is a path to folder
  # @param [String] extension find marker. Method will find only files with this word
  def get_file_paths_list(path, extension = nil)
    list_file_in_directory(path, extension)
  end

  # @param [String] folder_name - name for new folder
  def create_folder(folder_name)
    create_folder_back(folder_name)
    create_folder_back("#{folder_name}/not_converted")
  end

  # @param [Array] base_file_list - first list of file names
  # @param [Array] last_file_list - second list of file names
  def get_file_difference(base_file_list, last_file_list)
    input_file_names = base_file_list.map { |current_path| File.basename(current_path, '.*') }
    output_file_names = last_file_list.map { |current_path| File.basename(current_path, '.*') }
    not_converted = input_file_names - output_file_names
    File.open("#{@output_folder}/not_converted.txt", 'w') { |i| i.write 'Not converted' }
    not_converted.each do |file|
      print_to_log "File Not Converted: #{file}"
      File.open("#{@output_folder}/not_converted.txt", 'a') { |i| i.write file + "\n" }
    end
    not_converted_full_name = not_converted.map { |file_name| `find #{@base_file_folder} -name '#{file_name}.#{@input_format}'`.chomp }
    not_converted_full_name.each do |not_converted_file|
      begin
        copy_file(not_converted_file, "#{@output_folder}/not_converted")
      rescue
        print_to_log "#{not_converted_file} not copy"
      end
    end
  end

  # @param [String] input_filename - input filename with format
  # @param [String] output_filename - input filename with format
  def convert_file(input_filename, output_filename)
    print_to_log "Start convert file #{input_filename} to #{output_filename}"
    command = "echo #{@pass} | sudo -S \"#{@bin_path}\" \"#{input_filename}\" \"#{output_filename}\""
    print_to_log "Run command #{command}"
    `#{command}`
    print_to_log 'End convert'
    puts 'End convert'
    puts '--' * 150
  end

  # @param [Hash] option_hash. Key - is a start format, value - result format
  def convert(option_hash)
    @input_format = option_hash.keys.first
    @output_format = option_hash.values.first
    @output_folder = "#{@base_output_folder}/#{@input_format}_to_#{@output_format}"
    create_folder @output_folder
    file_list = get_file_paths_list(@base_file_folder, @input_format)
    $status[:all] = file_list.size
    file_list.each_with_index do |current_file_to_convert, i|
      output_file_path = "#{@output_folder}/#{File.basename(current_file_to_convert, '.*')}.#{@output_format}"
      $status[:filename] = File.basename(current_file_to_convert)
      convert_file(current_file_to_convert, output_file_path)
      $status[:current] = i + 1
    end
    get_file_difference(file_list, get_file_paths_list(@output_folder, @output_format))
  end

  def create_folder_back(path)
    FileUtils.mkdir_p(path) unless File.directory?(path)
  rescue Errno::EEXIST
    true
  end

  def file_exists(file_path)
    warn '[DEPRECATION] Use file_exist? instead'
    File.exist?(file_path)
  end

  def copy_file(file_path, destination)
    FileUtils.mkdir_p(destination) unless File.directory?(destination)
    FileUtils.copy(file_path, destination)
  end

  def list_file_in_directory(directory, extension = nil)
    paths = []
    Find.find(directory) do |path|
      next if FileTest.directory?(path)
      if extension.nil?
        paths << path
      elsif File.extname(path) == ".#{extension}"
        paths << path
      end
    end
    paths
  rescue Errno::ENOENT
    []
  end

  def print_to_log(string, color_code = nil)
    message = Time.now.strftime('%T/%d.%m.%y') + '    ' + '[' + caller[0].to_s[/\w+.rb/].chomp('.rb') + '] ' + string
    color_code ? (puts colorize message, color_code) : (puts message)
  end

  def colorize(text, color_code)
    "\e[#{color_code}m#{text}\e[0m"
  end

end

class ZipFileGenerator
  # Initialize with the directory to zip and the location of the output archive.
  def initialize(input_dir, output_file)
    @input_dir = input_dir
    @output_file = output_file
  end

  # Zip the input directory.
  def write
    entries = Dir.entries(@input_dir) - %w(. ..)

    ::Zip::File.open(@output_file, ::Zip::File::CREATE) do |io|
      write_entries entries, '', io
    end
  end

  private

  # A helper method to make the recursion work.
  def write_entries(entries, path, io)
    entries.each do |e|
      zip_file_path = path == '' ? e : File.join(path, e)
      disk_file_path = File.join(@input_dir, zip_file_path)
      puts "Deflating #{disk_file_path}"

      if File.directory? disk_file_path
        recursively_deflate_directory(disk_file_path, io, zip_file_path)
      else
        put_into_archive(disk_file_path, io, zip_file_path)
      end
    end
  end

  def recursively_deflate_directory(disk_file_path, io, zip_file_path)
    io.mkdir zip_file_path
    subdir = Dir.entries(disk_file_path) - %w(. ..)
    write_entries subdir, zip_file_path, io
  end

  def put_into_archive(disk_file_path, io, zip_file_path)
    io.get_output_stream(zip_file_path) do |f|
      f.puts(File.open(disk_file_path, 'rb').read)
    end
  end
end