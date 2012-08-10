RunTime = require './run_time'

# Default params, pattern array not yet implemented, times are in seconds
params = {
  request: {
    uri: "http://localhost",
    method: "GET"
  },
  poll_interval: 1,
  pattern: {
    start_count: 1,
    end_count: 1000, 
  },
  duration: 120
}

r = new RunTime()
r.start(params)
    
# Output stats to console
update = () ->
  return () ->
    console.log(r.stats)

# print updates
updatesId = setInterval( update(), params.poll_interval * 1000 )