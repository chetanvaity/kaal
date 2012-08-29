# encoding: UTF-8
class ApplicationController < ActionController::Base
  protect_from_forgery
  
  include SessionsHelper
  include ApplicationHelper

  # To be used in any controller
  def record_activity(extra)
    begin
      @activity = ActivityLog.new
      unless current_user.nil?
        @activity.user_id = current_user.id
        @activity.user = current_user.name
      end
      @activity.controller = controller_name 
      @activity.action = action_name 
      @activity.params = params.inspect
      @activity.ip = request.env['REMOTE_ADDR']
      @activity.browser = request.env['HTTP_USER_AGENT']
      @activity.extra = extra
      @activity.save
    rescue => e
      logger.warn("record_activity(): #{controller_name}-#{action_name}-#{params}: #{e}")
    end
  end
  
end
