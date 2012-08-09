request = require 'request'

# https://github.com/mikeal/request/

params = {
  poll_interval: 5000,
  uri: "http://localhost",
  method: "GET",
  request_delay: 1000, 
  pattern: {
    start_count: 1,
    end_count: 10000, 
    duration: 120000
  },
  duration: 120000
}

stats = {
    'volume': 0, 
    'total': 0, 
    'response_time': 0.0, 
    'pass': 0, 
    'errors': 0, 
    'codes':{}
}

step_size = (params['pattern']['end_count'] - params['pattern']['start_count'])/params['pattern']['duration']

if step_size < 1
  step_delay = 1/step_size
  step_size = 1
else
  step_delay = 1
  step_size = step_size.to_i

params['duration'] ||= params['pattern']['duration']

stats['start_time'] = new Date().getTime()

runners = []

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
    
update = () ->
  return () ->
    console.log(stats)
  
ramp = (params) ->
  return () -> 
    remaining = params['pattern']['end_count'] - stats['volume']
    step_size = if remaining < step_size then remaining else step_size
  
    for i in [1..step_size]
      runners.push setInterval( run(params), params['request_delay'] )
  
    stats['volume'] += step_size
    stats['duration'] = new Date().getTime() - stats['start_time']
    
stop = (duration) ->
  return () ->
    if stats['duration'] >= params['duration']
      stop_test = true
      console.log("stopping [#{runners.length}] timers")
      clearInterval id for id in runners
    

runners.push setInterval( ramp(params), step_delay )

runners.push setInterval( update(), params['poll_interval'] )

runners.push setInterval( stop(params['duration']) , 1000 )