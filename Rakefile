require_relative "./config/initializers/thrift_services_config.rb"
require "recursive-open-struct"

def stop_service_task(service)
  task "stop_#{service}" do
    begin
      sh "docker rm -f #{service} 2> /dev/null"
    rescue
    end
  end
end

def start_service_task(service)
  task service => ["mysql", "stop_#{service}"] do
    sh "docker run --link mysql:mysql --name #{service} -d registry.edmodo.io/#{service}-development"
  end
end

def service_port(service)
  service_config
    .send(environment)
    .send(service_alias(service))
    .port
end

def service_alias(name)
  {
    "auth" => "graph",
    "planner" => "comm"
  }[name] || name
end

def service_config
  @services ||= RecursiveOpenStruct.new(ThriftConfig.load)
end

def environment
  "development"
end

def services
  %w(auth planner analytics money)
end

def dependencies
  services << "mysql"
end

def docker_images
  dependencies << "one_eye"
end

namespace :docker do
  docker_images.each do |service|
    stop_service_task(service)
  end

  services.each do |service|
    start_service_task(service)
  end

  task :mysql => :stop_mysql do
    sh "docker run --name mysql -d -e MYSQL_ROOT_PASSWORD=root mysql"
    puts "Waiting for mysql to boot"
    sleep 10
  end

  task :wait do
    puts "Waiting for services to boot"
    sleep 10
  end

  task :one_eye => :stop_one_eye do
    links = dependencies.map do |service|
      "--link #{service}:#{service}"
    end.join(" ")

    sh "docker run #{links} --name one_eye -d -p 3000:3000 registry.edmodo.io/one-eye-development ./start_docker_dev"

    trap "INT" do
      exit
    end

    trap "EXIT" do
      puts "Now shutting down all One Eye docker services"
      sh "bin/rake docker:down"
    end

    sh "docker logs -f one_eye"
  end

  namespace :pull do
    services.each do |image|
      task image do
        sh "docker pull registry.edmodo.io/#{image}-development:latest"
      end
    end

    task "one_eye" do
      sh "docker pull registry.edmodo.io/one-eye-development:latest"
    end

    task "mysql" do
      sh "docker pull mysql:latest"
    end

    task "all" => [*services, "one_eye", "mysql"]
  end

  task :up => [*dependencies, :wait, :one_eye]
  task :down => [:stop_one_eye, :stop_auth, :stop_planner, :stop_analytics, :stop_money, :stop_mysql]
  task :pull => "pull:all"

  task :build do
    sh "docker build -t registry.edmodo.io/one-eye-development ."
  end

  task :push do
    sh "docker push registry.edmodo.io/one-eye-development:latest"
  end
end

namespace :vagrant do
  task :vagrant do
    sh "vagrant up"
  end

  task :env do
    ENV["DOCKER_HOST"]       = "tcp://192.168.33.10:2376"
    ENV["DOCKER_TLS_VERIFY"] = ""
  end

  task :up => ["vagrant", "env", "docker:up"]
end
