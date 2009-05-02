# Project-specific configuration for CruiseControl.rb

Project.configure do |project|
  
  # Send email notifications about broken and fixed builds to email1@your.site, email2@your.site (default: send to nobody)
  project.email_notifier.emails = ['jamie@dang.com', 'eos8d@virginia.edu', 'mpc3c@virginia.edu', 'ndushay@stanford.edu','jkeck@stanford.edu',  'goodieboy@gmail.com']

  # Set email 'from' field to john@doe.com:
  project.email_notifier.from = 'nobody@rubyforge.org'

  case project.name
  when 'BlacklightPluginSpecs'
    project.rake_task = 'ccspec'
    project.scheduler.polling_interval = 1.minutes
    
  when 'BlacklightPluginFeatures'
    project.rake_task = 'ccfeatures'
    project.scheduler.polling_interval = 5.minutes
    
  end
  
  # Build the project by invoking rake task 'custom'
  # Build the project by invoking shell script "build_my_app.sh". Keep in mind that when the script is invoked,
  # current working directory is <em>[cruise&nbsp;data]</em>/projects/your_project/work, so if you do not keep build_my_app.sh
  # in version control, it should be '../build_my_app.sh' instead
  # project.build_command = 'build_my_app.sh'

  # Ping Subversion for new revisions every 5 minutes (default: 30 seconds)
end
