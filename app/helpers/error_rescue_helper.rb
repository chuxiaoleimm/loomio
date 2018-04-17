module ErrorRescueHelper
  def self.included(base)
    base.rescue_from(ActionView::MissingTemplate)  do |exception|
      raise exception unless %w[txt text gif png].include?(params[:format])
    end

    base.rescue_from(ActiveRecord::RecordNotFound) do
      respond_with_error message: :"errors.not_found", status: 404
    end

    base.rescue_from(Membership::InvitationAlreadyUsed) do |exception|
      session.delete(:pending_membership_token)
      if current_user.email == exception.membership.user.email
        redirect_to formal_group_url invitation.group
      else
        respond_with_error message: :"invitation.invitation_already_used"
      end
    end

    base.rescue_from(CanCan::AccessDenied) do |exception|
      if current_user.is_logged_in?
        flash[:error] = t("error.access_denied")
        redirect_to dashboard_path
      else
        authenticate_user!
      end
    end
  end

  def response_format
    params[:format] == 'json' ? 'json' : 'html'
  end

  def respond_with_error(message: "", status: 400)
    @error_description ||= t(message)
    render "errors/#{status}", layout: 'basic', status: status, formats: response_format
  end
end
