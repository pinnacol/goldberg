module ApplicationHelper
  def project_status(project)
    status(project.latest_build_status)
  end

  def build_status(build)
    status(build.status)
  end

  def status(s)
    s ? s.gsub(/ /, '_') : 'unknown'
  end

  def format_timestamp(timestamp)
    timestamp.nil? ? '' : content_tag(:span, "#{time_ago_in_words(timestamp)} ago", :class => 'timestamp', :title => timestamp.strftime("%a, %Y/%m/%d %I:%M%p %Z"))
  end
end
