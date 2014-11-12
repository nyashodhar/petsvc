module s3Helper

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
  # Handle s3 upload for a file.
  #
  # If 'create_thumb == true' a thumb version of the image will
  # be created, resulting in two actual files being uploaded to S3.
  #
  # On success, S3Upload records are created in local db, and information
  # is returned to the caller to manage the storage of the upload ids
  # for later reference.
  #
  # If there is a problem, an error is raised.
  #
  #############################################################
  def upload_file_to_s3(upload_dir, s3_heap, s3_subheap, file_name, create_thumb)

    #
    # Part 1 - Upload the binary content of the request to a local file
    #

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

    #
    # Part 2 - Upload the full size file to S3, and optionally also upload a thumb
    # version of the image.
    #

    begin
      uploader = S3Uploader.new(upload_dir, file_name)
      uploader.set_create_thumb(create_thumb)
      uploader.store!(uploaded_file.open())
    rescue => e
      logger.error "upload_file_to_s3(): Unable to upload file #{file_name} to S3, upload_dir = #{upload_dir}, request.params = #{request.params.inspect}"
      raise e
    end

    #
    # Part 3 - Create S3Upload record(s)
    #

    # Record for the full-size version of the image
    s3_url = get_s3_url_for_file(uploader.get_bucket_region, uploader.fog_directory, upload_dir, file_name)
    s3_upload_id = create_s3_upload(uploader.fog_directory, uploader.get_bucket_region, s3_heap, s3_subheap, file_name, s3_url)

    if(create_thumb)
      # Record for the thumb version of the image
      s3_url_thumb = get_s3_url_for_file(uploader.get_bucket_region, uploader.fog_directory, upload_dir, "thumb_#{file_name}")
      s3_upload_id_thumb = create_s3_upload(uploader.fog_directory, uploader.get_bucket_region, s3_heap, s3_subheap, file_name, s3_url_thumb)
    end

    #
    # Part 4 - Return information about the outcome
    #

    s3_info = Hash.new
    s3_info[:bucket_name] = uploader.fog_directory
    s3_info[:bucket_region] = uploader.get_bucket_region
    s3_info[:upload_dir] = upload_dir
    s3_info[:file_name] = file_name
    s3_info[:url] = s3_url
    s3_info[:upload_id] = s3_upload_id
    if(create_thumb)
      s3_info[:url_thumb] = get_s3_url_for_file(uploader.get_bucket_region, uploader.fog_directory, upload_dir, "thumb_#{file_name}")
      s3_info[:upload_id_thumb] = s3_upload_id_thumb
    end

    logger.info "upload_file_to_s3(): S3 upload successful, s3 info #{s3_info}"
    return s3_info

  end

  def get_s3_url_for_file(bucket_region, bucket_name, upload_dir, file_name)
    return "https://s3-#{bucket_region}.amazonaws.com/#{bucket_name}/#{upload_dir}/#{file_name}"
  end

  private

  def create_s3_upload(bucket_name, bucket_region, s3_heap, s3_subheap, file_name, s3_url)

    #
    # Create an s3 upload
    #

    s3_upload_id = SecureRandom.uuid.to_s

    s3_upload = S3Upload.create(
        _id: s3_upload_id,
        creation_time: Time.now,
        uploader_user_id: @authenticated_user_id,
        bucket_name: bucket_name,
        bucket_region: bucket_region,
        heap: s3_heap,
        subheap: s3_subheap,
        file_name: file_name,
        url: s3_url
    )

    if(!s3_upload.valid?)
      handle_mongoid_validation_error(s3_upload, request.params)
      return
    end

    begin
      s3_upload.save!
      logger.info "create_s3_upload(): S3 upload #{s3_upload_id} created, s3_url #{s3_url}, logged in user #{@authenticated_email}:#{@authenticated_user_id}"
      return s3_upload_id
    rescue => e
      logger.error "create_s3_upload(): File uploaded to S3, but unexpected error when saving s3 upload #{s3_upload_id}, logged in user #{@authenticated_email}:#{@authenticated_user_id}, error: #{e.inspect}"
      raise e
    end

  end

end