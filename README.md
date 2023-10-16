## Timers

Rails Web App that allows to easily execute scheduled tasks.

There are 2 endpoints available:
1. The endpoint to schedule a task.

Request example:
```
POST /timers
{
  hours: 4,
  minutes: 0,
  seconds: 1,
  url: "https://someserver.com"
}
```

Response example:
```
{ id: 1, time_left: 14401 }
```

After 4 hours and 1 second, the server will make the following request: `POST https://someserver.com/1`

2. The endpoint to view the scheduled task.
Request example:
```
GET /timers/1
```

Response example:
```
{ id: 1, time_left: 14401 }
```

### Assumptions

- We only want to fire the task webhook once, not depending on the response: if the request times out / is rejected / webhook server error is returned - we consider the timer executed anyway. This behavior can be easily altered to accommodate for the response errors handling (see `TimerExecutionJob`)

### How this app ensures tasks are scheduled and executed exactly once without being lost

Each task/timer has a status - possible values: `pending` (default), `scheduled`, `executed`.
When the timer is created, if the execution time is less than 6 minutes from now, the background job is scheduled for that time right away, and the timer status is set to `scheduled`. Otherwise, for other execution times, there is a cron sidekiq job that runs every 5 minutes and picks up timers due in the next 5 minutes to schedule it. We don't want to schedule all timers on creation because the sidekiq queue (stored in Redis) will become too big really fast and it could impact sidekiq performance. The cron job would also pick up non `executed` timers that are overdue (in case sidekiq server is not accessible for some time or in case of scheduled jobs Redis data loss).

I did not utilize timer table row locking when calling the webhook and updating timer status to `executed` (see `TimerSchedulerJob`) as this lock time would depend on the external API request execution time, the row would be not accessible for reading in the meantime. In case of multiple jobs scheduled for the same timer the race condition could occur, resulting in calling the webhook twice. If we prefer consistency over timer data accessibility via API, we can wrap webhook call & timer status update into lock.

### Scaling possibilities

To accommodate for high API requests amount (a lot of tasks/timers constantly being created) it would be possible to run multiple instances of the web server where the app is going to be running. We'd need a load balancer to handle incoming requests and balance the load between multiple servers.

For processing these tasks/timers the project utilizes sidekiq - the service for background job processing. To handle tasks of timers scheduled for the same time we could change the number of threads and/or also create multiple sidekiq instances on several machines.

#### Scaling TODOs

`TimerSchedulerJob` - a job that schedules timers every 5 minutes: this job processes at most 1000 timers, one trip to Redis (schedule a sidekiq job) is 2ms, which would result in the job lasting for 2s: too long. We'd need to utilize batch job scheduling.

### Launch the app

Run the following commands in the terminal from the project root folder:
```
scp .env.example .env
docker compose up
```
In separate terminal process:
```
docker-compose run app rake db:create db:migrate
```

If you wish to get acquainted with the code it will be handy to navigate git commits

### Unit tests
To launch unit tests run the following command in the terminal from the project root folder

`docker-compose run app rspec spec`
