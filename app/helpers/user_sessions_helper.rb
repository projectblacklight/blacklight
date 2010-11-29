module UserSessionsHelper
  def referer_url
    url = params[:referer]
    url ||= request.referer
    return url
  end
end
