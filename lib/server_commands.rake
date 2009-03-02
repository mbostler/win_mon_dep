namespace :server do
  namespace :mongrels do
    desc "Stops running mongrel processes"
    task :stop do
      unless ENV['downtime'] =~ /^(\d+)?:\d+$/ || ENV['downtime'] =~ /^\d+$/ || ENV['downtime'].blank?
        abort "\"downtime\" was specified in the wrong format. Use \#{hours}:\#{minutes} or \#{minutes}"
      end
      puts "Copying lib\\maintenance.html to public\\maintenance.html..."
      system("copy #{RAILS_ROOT.to_win}\\lib\\maintenance.html #{RAILS_ROOT.to_win}\\public\\maintenance.html")
      system("net stop \"mongrel_#{project_name}1\"")
      system("net stop \"mongrel_#{project_name}2\"")
      add_downtime_to_maintenance_file(ENV['downtime']) || ENV['downtime'].blank
    end
  
    desc "Starts running mongrel processes"
    task :start  => :check_for_pending_migrations do
      system("net start \"mongrel_#{project_name}1\"")
      system("net start \"mongrel_#{project_name}2\"")
      if File.exists?("#{RAILS_ROOT}/public/maintenance.html")
        puts "Removing public\\maintenance.html..."
        system("del #{RAILS_ROOT.to_win}\\public\\maintenance.html")
      end
      puts "Done."
    end
  
    desc "Restarts running mongrel processes"
    task :restart => [:stop, :start]
 
  end
  
  
  namespace :apache do
    desc "Stops apache server"
    task :stop do
      system("C:\\Program Files\\Apache Software Foundation\\Apache2.2\\bin\\httpd -k shutdown")
      puts "Apache stopped."
    end
    
    desc "Starts apache server"
    task :start => :check_for_pending_migrations do
      system("C:\\Program Files\\Apache Software Foundation\\Apache2.2\\bin\\httpd -k start")
    end
    
    desc "Restarts apache server"
    task :restart => :check_for_pending_migrations do
      system("C:\\Program Files\\Apache Software Foundation\\Apache2.2\\bin\\httpd -k restart")
      puts "Apache restarted."
    end
  end
  
  desc "a wrapper task that runs 'db:abort_if_pending_migrations' from the production environment"
  task :check_for_pending_migrations => :environment do
    ActiveRecord::Base.establish_connection('production')
    Rake::Task["db:abort_if_pending_migrations"].invoke
  end
  
  class String
    # replaces forward slashes with backslashes. Needed to transform RAILS_ROOT 
    # into a windows-friendly path
    def to_win
      self.gsub("/", "\\")
    end
  end
end

private

def project_name
  RAILS_ROOT.split('/').last
end

def add_downtime_to_maintenance_file(downtime)
  Dir.chdir("#{RAILS_ROOT}/public")
  open('maintenance.html', 'a') do |f|
    if downtime =~ /^(\d+)?:\d+$/
      hours, minutes = downtime.split(':').collect {|t| t.to_i}
      f.puts completion_time_notification(hours, minutes)
    elsif downtime =~ /^\d+$/
      minutes = downtime.to_i
      f.puts completion_time_notification(0, minutes)
    else
      f.puts "<p>The site should be back up soon!</p>"
    end
  end
  Dir.chdir(RAILS_ROOT)
end

def completion_time(hours, minutes)
  time = Time.now + (hours * 60 * 60 + minutes * 60) # can only add seconds to Time objects
  "#{time.strftime('%I:%M%p on %A, %B %d %y')} #{time.zone}"
end

def completion_time_notification(hours, minutes)
  "<p style='font-style:oblique'>Estimated completion time: #{completion_time(hours, minutes)}</p>"
end

