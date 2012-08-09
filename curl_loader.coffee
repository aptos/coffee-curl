request = require 'request'

# https://github.com/mikeal/request/

# Static params, would normally be sent to a Server process
params = {
  poll_interval: 5000,
  uri: "http://localhost",
  method: "GET",
  request_delay: 1000, 
  pattern: {
    start_count: 1,
    end_count: 5000, 
    duration: 60000
  },
  duration: 60000
}

# Initialize stats object
stats = {
    'volume': 0, 
    'total': 0, 
    'response_time': 0.0, 
    'pass': 0, 
    'errors': 0, 
    'codes':{}
}

# Compute step size for ramp pattern
step_size = (params['pattern']['end_count'] - params['pattern']['start_count'])/params['pattern']['duration']

if step_size < 1
  step_delay = 1/step_size
  step_size = 1
else
  step_delay = 1
  step_size = step_size.to_i

params['duration'] ||= params['pattern']['duration']

# Start time
stats['start_time'] = new Date().getTime()

runners = []

# Execute http request and update stats
run = (params) -> 
  return () ->  
    request(params, (e, r, body) ->
      stats['total'] += 1
      stats['codes'][r.statusCode] = if stats['codes'][r.statusCode] then stats['codes'][r.statusCode] + 1 else 1
      if r.statusCode < 400
        stats['pass'] += 1 
      else
        console.log "Error: #{e}"
        stats['errors'] += 1 
    )
    
# Output stats to console
update = () ->
  return () ->
    console.log(stats)
  
# Ramp up the execution instances
ramp = (params) ->
  return () -> 
    remaining = params['pattern']['end_count'] - stats['volume']
    step_size = if remaining < step_size then remaining else step_size
  
    for i in [1..step_size]
      runners.push setInterval( run(params), params['request_delay'] )
  
    stats['volume'] += step_size
    stats['duration'] = new Date().getTime() - stats['start_time']
    
# Stop all instances once test duration is reached
stop = (duration) ->
  return () ->
    if stats['duration'] >= params['duration']
      console.log("stopping [#{runners.length}] timers")
      process.exit()
      
# Start ramping, updating console and watch for stop (end test)
runners.push setInterval( ramp(params), step_delay )

runners.push setInterval( update(), params['poll_interval'] )

runners.push setInterval( stop(params['duration']) , 1000 )