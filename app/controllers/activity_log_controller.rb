
# encoding: UTF-8

class ActivityLogController < ApplicationController
  before_filter :require_admin
  def index
    @activity_logs = ActivityLog.order(:created_at).page(params[:page])
  end

  private
  def require_admin
    if (not current_user.nil?) and (current_user.isadmin)
      # Its admin. Cool.
    else
      flash[:warning] = "You must be admin to access activity logs"
      redirect_to :root
    end
  end

end
