#12 Factor ruby app

As made apparent by the title, the 12-Factor App methodology is a list of principles, each explaining the ideal way to handle a subset of your application.They were created by some Heroku's engineers.

The principles describe the best practices they see for how to get a modern web app deployed properly.

##Why is it worth it?

The "Works on My Machine" Certification Program no longer needed
https://ih0.redbubble.net/image.330894217.1901/flat,800x800,075,f.u1.jpg
That is perfect for a cloud environment because there is a clear contract between the app and everything which should be around it, if you fulfil your part of the contract, your app will be deployable.

Follow this principles will make an application operable.
No matter if it is operated by the developer who wrote the code if you are in a devops atmosphere, or by your SRE team or even a third party company like Heroku or Netlify.


##12factor by example:

###Codebase
One codebase tracked in revision control, many deploys
This one seems a very pretty straightforward principle, use git or any other cvs to track any change but check that there are no branches with new features or tag with versions. Your deployable code should be on master.

This seems very obvious for developers but no question neither about your infrastructure that must be also defined as code, no matter which provisioner you are using, it should be also tracked in code following also the 12factor principles.

For this article we will use ruby code and a docker examples which lives always with the application and allow us to run the app locally but also in a kubernetes cluster.

All the code can view revied in github
https://github.com/ferrandinand/12factor-ruby

###Dependencies
Explicitly declare and isolate dependencies
Here in Flywire we are using mainly ruby our code language so we use a Gemfile and Gemfile.lock to track and pin dependencies then we know what is needed by our application to run and which versions provide stability.As you can imagine, this is key when running services in production.

For example in Gemfile we pin to the major version because maybe the new version may not be compatible with my code.
```
gem 'puma', '~> 3.10'
```
In a Dockerfile we can pin any specific tag to avoid different behaviours. Don’t use latest (without specifying a version) at least in production.
```
FROM ruby:2.3
```

###Config
Store configuration in the environment
Our code must be always separated from the configuration then our code can be applied in many different environments with different configurations.

For passwords, using this pattern doesn’t mean it is more secure than a file provisioned but for sure it will be more secure than storing them in the code!

For example if you do something like this
In config/database.rb
```
set :database, "postgresql://docker:docker@db/factor"
```

You must change the code for each different configuration. Using instead an environment variable will allow to change easily the configuration for each deployment.
```
set :database, ENV[‘DATABASE_URL’]
```

For Docker I would insert env vars at run time.
```
docker run -e DATABASE_URL=$DATABASE_URL 12factor-ruby:0.1 or docker run —env-file my_app_keys 12factor-ruby:0.1
```

Don’t store credentials inside a build because if you do this in a Dockerfile
```
ENV DATABASE_URL=$DATABASE_URL
```
This will store our credentials in an intermediate layer that can be used by other dockers in the system.

###Backing Services
Treat backing services as attached resources
Make changes to app’s code to change resource
The idea would be to have a code where, we don´t know which backing service we have and if we change it the code it is not altered. In ruby we can use tools like Active Record and configure the database in a environment variable.
```
    def add_country(country_name)
      $LOG.info "Creating country #{country_name}"
      country = Countries.new
      country.name = country_name
      country.visits = 0
      country.save
      $LOG.info "Created country #{country_name}"
    end
```
in config/database.rb
```
set :database, ENV['DATABASE_URL']
```
Like this, our code is completely agnostic to the backend used and if we want to change to other db system is just a matter of changing the DATABASE_URL environment var.

###Build, release, run
Strictly separate build and run stages

https://12factor.net/images/release.png

We must have a strict separation: build (binary), release (binary + env config), run (exec runtime)
As we said many times, our instances must be inmutable then we can’t make changes upstream.
Every change must be a new release with a unique id.

Let's do it with docker (requires login to a docker registry)

- First we create a build with and tag the release.
```
docker build -t ferrandinand/12factor-ruby:0.1 .
```

- Next we publish the image.
```
docker push ferrandinand/12factor-ruby:0.1
```

- Finally we use the published image at running docker run, docker-compose or in kubernetes (See at the Dev/prod parity pattern below)

###Processes
Twelve-factor processes are stateless and share-nothing. Any data that needs to persist must be stored in a stateful backing service.

That's because resources in a cloud environment are ephemeral and should be also inmutables therefore it makes no sense to store files or session data in memory.

With containers we have a perfect match because containers are designed to run with just one scope and of course, they are ephemeral.

For example,this would be a bad practice in our container Dockerfile
```
VOLUME /logs
```

And if something like this is in your code too
```
log = Logger.new('log_file.log', 'monthly')
```

Remember, if you need to store data, do it in a backing service.

###Port binding
If we said in the backing service pattern that every service should be accessed via URL, that includes our app. Exporting services via port binding will allow as to become a backing service for another app via url.

So in the Dockerfile we will expose the port 4000 but we will run puma also app also binded to that port
Dockerfile

```
CMD ["bundle", "exec", "puma", "-p", "4000"]
EXPOSE 4000
```

###Concurrency
Scale out via the process model.

Seems pretty obvious… if for any reason your app is not able to scale horizontally your app won´t be prepared for the cloud.
The cloud must be synonym of automation then we must ensure that we can create replicas of our application on-demand.

###Disposability
Maximize robustness with fast startup and graceful shutdown

We must ensure that our application shutdowns clearly.
For example, we shouldn´t stop an application when is writing in a backing service.
To do this, our app must to be able to capture signals, ensure that we finish calls and then stop the app.

lib/app_signals.rb

```
require 'logger'
require 'active_record'


Signal.trap("TERM") do
  puts "Sending TERM signal to app"
  shutdown_app
  exit
end

Signal.trap("INT") do
  puts "Sending TERM signal to app"
  shutdown_app
  exit
end

def shutdown_app
  active_connections =  ActiveRecord::Base.respond_to?(:verify_active_connections!)
  puts "Closing connections" if  active_connections
  puts "No active connections" if  !active_connections
  ActiveRecord::Base.clear_active_connections! if active_connections
end
```

To send a signal and test it we can use

```
docker kill -s SIGTERM image_id
```

###Dev/prod parity
Keep development, staging, and production as similar as possible.
Seems pretty strange to hear that anyone uses a different kind of technologie for staging that for production but when it comes to development we see sometimes lightweight software for backing services.

Nowadays setting up services could be very easy with Vagrant and provisioners like chef or ansible and easier with containers.

In Flywire we use for some of our apps docker-compose which allows running our applications with all services required but also to run tests locally.

docker-compose example

```
version: '3'

services:
  db:
    image: postgres
    environment:
      POSTGRES_PASSWORD: docker
      POSTGRES_USER: docker
      POSTGRES_DB: factor
  web:
    build: .
    environment:
      DATABASE_URL: postgresql://docker:docker@db/factor
    ports:
      - "4000:4000"
    depends_on:
      - db
```

You can find the kubernetes example at github repo metioned in the codebase pattern

###Logs
Treat logs as event streams
Logs and never concerns itself with routing or storage of its output stream.

The main idea would be to do an app as much agnostic as possible then it shouldn't depend in any other system or process.

Then our app should just puts logs in stdout and if we want to collect and ship them other process/app should be in charge of that.

Following this idea this would be wrong in our app.
log = Logger.new('log_file.log', 'monthly')

The right way would be
```
log = Logger.new(STDOUT)
log.debug("Created logger")
```
Check logs with docker is very easy just typing docker log container_name (with kubernetes would be pretty the same just using kubectl logs pod_name)

###Admin processes
Run admin/management tasks as one-off processes.
Our applications must allow access to run maintenance tasks for the app, they run with the code and have the same behaviour in all environments.

For create the initial db structure in:

docker-compose
```
docker exec -it 12factorapp_id  bash -c "rake db:migrate"
```

kubernetes
```
kubectl exec -it 12factorapp-655998b74b-wflp8 -- bash -c "rake db:migrate"
```

Heroku
```
heroku login
heroku run rake db:migrate -a factor12
```

