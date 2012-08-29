# encoding: UTF-8

class ActivityLogController < ApplicationController
  before_filter :require_admin
  def index
    @activity_logs = ActivityLog.order(:created_at).page(params[:page])
  end

  private
  def require_admin
    if (not current_user.nil?) and (not current_user.isadmin)
      flash[:warning] = "You must be admin to access activity logs"
      redirect_to :root
    end
  end

end
