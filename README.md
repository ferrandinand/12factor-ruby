# 12factor (solid principle for Cloud Software Architecture)
## Codebase
One codebase tracked in revision control, many deploys

```
Use git or any other cvs to track any change but check that there are no branches with new features or tag with versions.
```

## Dependencies
Explicitly declare and isolate dependencies

```
In Dockerfile we are not pinning any tag then we are tied to the latest version of ruby.
FROM ruby
```

## Config
Store configuration in the environment

```
In lib/world_temperature.rb we are using configuration and secrets in the code
@forecast_api_key = "98919415974343fc1345"

In Dockerfile 
ENV forecast_api_key="99f08919415972d78b757e13a6fc1345"
```

## Backing Services
Treat backing services as attached resources

```
Make changes to app’s code to change resource

@db = SQLite3::Database.new("mydb.db")
connect_to_sqllitle

```

## Build, release, run
Strictly separate build and run stages

```
docker build -t xxxx/xxxx:xxx
docker push xxxx/xxxx:xxx
docker run xxxx/xxxx:xxx
```

## Processes
Execute the app as one or more stateless processes

```
VOLUME /logs
```


## Port binding
Export services via port binding

```
EXPOSE 3000
CMD ["shotgun", "-p", "3000", "-o", "0.0.0.0"]
```

## Concurrency
Scale out via the process model

## Disposability
Maximize robustness with fast startup and graceful shutdown

```
Reentrancy code in actions.rb

   mytemp = WorldTemp.new
   lat1, lng1 = mytemp.get_geo(@forecast_city)
   @temperature = mytemp.get_temp(lat1,lng1,forecast_units) 
   mytemp.update_db(@forecast_city)
   $LOG.info "Updated db"
```

## Dev/prod parity
Keep development, staging, and production as similar as possible

```
config/environment.rb
```

## Logs
Treat logs as event streams

```
LOG = Logger.new('log_file.log', 'monthly')
```

## Admin processes
Run admin/management tasks as one-off processes

```
docker exec
console ruby/rails available
```
