module S3Helper

  #############################################################
  #
  # Generate a directory name for S3. This is the dir relative
  # to the bucket name in which the file will reside.
  #
  #############################################################
  def generate_file_dir(heap_name, subheap_name)
    return "#{heap_name}/#{subheap_name}"
  end

  #############################################################
  #
  # Generates a unique file name
  #
  #############################################################
  #def generate_file_name
  #  return SecureRandom.uuid.to_s.downcase
  #end

  #############################################################
  #
  # Uploads a file to S3.
  #
  # If there is a problem, an error is raised.
  #
  # Upon success a map of S3 information about the uploaded file is returned
  #
  #############################################################
  def upload_file_to_s3(upload_dir, file_name)

    begin

      tempfile = Tempfile.new("petpal_upload")
      tempfile.binmode
      tempfile << request.body.read
      tempfile.rewind

      logger.info "upload_file_to_s3(): binary content of request piped to tempfile #{tempfile.inspect}"

      file_params = Hash.new
      file_params[:filename] = file_name
      file_params[:tempfile] = tempfile

      #
      # Note: We ignore the filename in URL and generate filename in-line for
      # now, but if we would like to store the user's original filename in some fashion
      # we can simply grab it from 'filename' URL param.
      #

      uploaded_file = ActionDispatch::Http::UploadedFile.new(file_params)

    rescue => e
      logger.error "upload_file_to_s3(): Unable to get binary content from request, upload_dir = #{upload_dir}, file_name = #{file_name}, request.params = #{request.params.inspect}"
      raise e
    end

    begin
      uploader = S3Uploader.new(upload_dir, file_name)
      uploader.store!(uploaded_file.open())
    rescue => e
      logger.error "upload_file_to_s3(): Unable to upload file #{file_name} to S3, upload_dir = #{upload_dir}, request.params = #{request.params.inspect}"
      raise e
    end

    s3_info = Hash.new
    s3_info[:bucket_name] = uploader.fog_directory
    s3_info[:bucket_region] = uploader.get_bucket_region
    s3_info[:upload_dir] = upload_dir
    s3_info[:file_name] = file_name

    logger.info "upload_file_to_s3(): File successfully uploaded to s3, info #{s3_info}"
    return s3_info

  end

  def get_s3_url_for_file(bucket_region, bucket_name, upload_dir, file_name)
    return "https://s3-#{bucket_region}.amazonaws.com/#{bucket_name}/#{upload_dir}/#{file_name}"
  end

end