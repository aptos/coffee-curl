express = require 'express'

class Server
  port = 8000
  constructor: () ->
    console.log("Server ...")
   
  start: () ->
    app = express()
    
    app.configure () ->
      app.use(express.methodOverride())
      app.use(express.bodyParser())
      app.use(app.router)
      return
    
    app.post '/start', (req, res) =>
      res.json({ok: true})
      
    app.get '/', (req, res) =>
      console.dir req.headers
      res.json({ok: true, method: "GET"})

    app.get '/stop', (req, res) =>
      res.json({ok: true})
      
    app.listen port
    console.log "Server started on port #{port}"
    return
    
    
  shutdown: () -> process.exit(0)

  

module.exports = Server

server = new Server()
server.start()
