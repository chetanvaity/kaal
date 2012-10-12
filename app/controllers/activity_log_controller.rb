# encoding: UTF-8

class ActivityLogController < ApplicationController
  before_filter :require_admin
  def index
    @activity_logs = ActivityLog.order(:created_at).page(params[:page])
  end
end
