request = require 'request'

# https://github.com/mikeal/request/

# Default params, pattern array not yet implemented, times are in seconds
params = {
  request: {
    uri: "http://localhost",
    method: "GET"
  },
  poll_interval: 1,
  pattern: {
    start_count: 1,
    end_count: 5000, 
  },
  duration: 30
}

# computed rate for ramp computation
ramp_rate = (params['pattern']['end_count'] - params['pattern']['start_count'])/params['duration']

# Initialize stats object
stats = {
    'volume': 0, 
    'total': 0, 
    'response_time': 0.0, 
    'pass': 0, 
    'errors': 0, 
    'codes':{}
}

# utilities
now = () ->
  return new Date().getTime()
  
# Start time
stats['start_time'] = now()

# Execute http request and update stats
run = (params) ->  
  t1 = now()
  request(params['request'], (e, r, body) ->
    stats['response_time'] = now() - t1
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
    stats['duration'] = (now() - stats['start_time'])/1000 # in seconds
    if stats['duration'] <= params['duration']
      volume = params['pattern']['start_count'] + Math.round (ramp_rate * stats['duration'])
      stats['volume'] = if volume > params['pattern']['end_count'] then params['pattern']['end_count'] else volume
      for i in [1..stats['volume']]
        run(params)
    
# Stop all instances once test duration is reached
stop = (duration) ->
  return () ->
    if stats['duration'] >= params['duration']
      console.log("stopping [#{runners.length}] timers")
      process.exit()
      
# Start ramping, updating console and watch for stop (end test)
runners = []

# ramp and run
runners.push setInterval( ramp(params), 1000 )

# print updates
runners.push setInterval( update(), params['poll_interval'] * 1000 )

# stop when duration is reached
runners.push setInterval( stop(params['duration']) , 1000 )