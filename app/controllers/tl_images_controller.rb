# encoding: UTF-8

class TlImagesController < ApplicationController
  before_filter :require_admin

  # GET /tl_images
  # GET /tl_images.json
  def index
    @tl_images = TlImage.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @tl_images }
    end
  end

  # GET /tl_images/1
  # GET /tl_images/1.json
  def show
    @tl_image = TlImage.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @tl_image }
    end
  end

  # GET /tl_images/new
  # GET /tl_images/new.json
  def new
    @tl_image = TlImage.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @tl_image }
    end
  end

  # GET /tl_images/1/edit
  def edit
    @tl_image = TlImage.find(params[:id])
  end

  # POST /tl_images
  # POST /tl_images.json
  def create
    @tl_image = TlImage.new(params[:tl_image])
    @tl_image.fname = params[:tl_image][:fname].original_filename
    upload
    
    respond_to do |format|
      if @tl_image.save
        format.html { redirect_to @tl_image, notice: 'Tl image was successfully created.' }
        format.json { render json: @tl_image, status: :created, location: @tl_image }
      else
        format.html { render action: "new" }
        format.json { render json: @tl_image.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /tl_images/1
  # PUT /tl_images/1.json
  def update
    @tl_image = TlImage.find(params[:id])
    @tl_image.fname = params[:tl_image][:fname].original_filename
    upload

    respond_to do |format|
      if @tl_image.update_attributes(params[:tl_image])
        format.html { redirect_to @tl_image, notice: 'Tl image was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @tl_image.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /tl_images/1
  # DELETE /tl_images/1.json
  def destroy
    @tl_image = TlImage.find(params[:id])
    @tl_image.destroy

    respond_to do |format|
      format.html { redirect_to tl_images_url }
      format.json { head :no_content }
    end
  end

  # To save the uploaded file
  def upload
    uploaded_io = params[:tl_image][:fname]
    File.open(Rails.root.join('public', 'uploads', uploaded_io.original_filename), 'wb') do |file|
      file.write(uploaded_io.read)
    end
  end

  private
  def require_admin
    if (not current_user.nil?) and (current_user.isadmin)
      # Its admin. Cool.
    else
      flash[:warning] = "You must be admin to access tl images"
      redirect_to :root
    end
  end

end
