# encoding: UTF-8

class ConfigvaluesController < ApplicationController
  before_filter :require_admin

  # Constructor
  def initialize(*params)
    super(*params)
    @configcache = ConfigCache.instance
  end

  def index
    @configvalues = Configvalue.order(:paramname)
  end

  # GET /configvalues/1
  def show
    @configvalue = Configvalue.find(params[:id])

    respond_to do |format|
      format.html # show.html.haml
    end
  end

  # GET /configvalues/new
  def new
    @configvalue = Configvalue.new

    respond_to do |format|
      format.html # new.html.haml
    end
  end

  # GET /configvalues/1/edit
  def edit
    @configvalue = Configvalue.find(params[:id])
  end

  # POST /configvalues
  def create
    @configvalue = Configvalue.new(params[:configvalue])
    
    respond_to do |format|
      if @configvalue.save
        @configcache.refresh
        format.html { redirect_to @configvalue, notice: 'Config Value was successfully created.' }
      else
        format.html { render action: "new" }
      end
    end
  end

  # PUT /configvalues/1
  def update
    @configvalue = Configvalue.find(params[:id])

    respond_to do |format|
      if @configvalue.update_attributes(params[:configvalue])
        @configcache.refresh
        format.html { redirect_to @configvalue, notice: 'Config Value was successfully updated.' }
      else
        format.html { render action: "edit" }
      end
    end
  end

  # DELETE /configvalues/1
  def destroy
    @configvalue = Configvalue.find(params[:id])
    @configvalue.destroy
    @configcache.refresh

    respond_to do |format|
      format.html { redirect_to configvalues_url }
    end
  end

end
