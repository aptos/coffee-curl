express = require 'express'
RunTime = require './run_time'

class Server
  port = 8000
  constructor: () ->
    console.log("Server listening on port #{port}")
    @runner = new RunTime()
   
  start: () ->
    app = express()
    
    app.configure () ->
      app.use(express.methodOverride())
      app.use(express.bodyParser())
      app.use(app.router)
      return
    
    app.post '/start', (req, res) =>
      console.log req
      response = @runner.start(req.body)
      res.json(response)
      
    app.get '/stats', (req, res) =>
      if @runner.stats
        response = {ok: true, data: @runner.stats}
      else
        response = {ok: false, message: "test is not running"}
      res.json(response)

    app.get '/stop', (req, res) =>
      response = @runner.stop()
      res.json(response)
      
    app.listen port
    console.log "Server started on port #{port}"
    return
    
    
  shutdown: () -> process.exit(0)

  

module.exports = Server

server = new Server()
server.start()
