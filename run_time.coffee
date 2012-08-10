request = require 'request'
Stats = require './stats_model'

# https://github.com/mikeal/request/

class RunTime
    
  constructor: () ->
    console.log("RunTime Created")
    @s = new Stats()
    @stats = @s.stats
    console.log @stats

  now: () ->
    return new Date().getTime()

  run: () -> 
    t1 = @now()
    @stats.requests += 1
    request(@params.request, (e, r, body) =>
      # TODO: not yet handling timeouts
      @stats.responses += 1
      @stats.response_time = @now() - t1
      if r?.statusCode
        @stats.codes[r.statusCode] = if @stats.codes[r.statusCode] then @stats.codes[r.statusCode] + 1 else 1
      if r?.statusCode < 400
        @stats.pass += 1 
      else
        @stats.errors += 1
        @stats.last_error = e
    )
    return

  ramp: () -> 
    return () =>
      @stats.duration = (@now() - @stats.start_time)/1000 # in seconds
      @stats.active_connections = @stats.requests - @stats.responses

      if @stats.duration <= @params.duration
        volume = @params.pattern.start_count + Math.round (@ramp_rate * @stats.duration)
        @stats.volume = if volume > @params.pattern.end_count then @params.pattern.end_count else volume
        
        # Add runtimes based on volume minus current open requests
        add_requests = @stats.volume - @stats.active_connections
        if add_requests > 0
          for i in [1..add_requests]
            @run(@params)
      else
        @stats.volume = 0

  start: (@params) ->
    console.log("start... #{@params.duration} second pattern")
    @ramp_rate = (@params.pattern.end_count - @params.pattern.start_count)/@params.duration
    @stats.start_time = @now()
    @runId = setInterval( @ramp(@params), 100 )
    return @runId

  stop: () -> 
    console.log("stop...")


module.exports = RunTime

