http = require 'http'
jade = require 'jade'
fs = require 'fs'
url = require 'url'
querystring = require 'querystring'

api_key = process.env['STRIPEKEY']
stripe = require('stripe') api_key


server = http.createServer (req, res) ->
  parsed_url = url.parse req.url, true
  query = parsed_url['query']
  console.log parsed_url['pathname']
  if parsed_url['pathname'] == '/'
    if !query or !query['amount'] or !query['name']
      res.writeHead 404
      res.end "404"
      return

    amount = parseInt query['amount']
    name = query['name']
    
    fs.readFile "payments.jade", (err, data) ->
      locals = {}
      locals["stripe_key"] = process.env['STRIPEPUBLICKEY']
      locals["amount"] = amount
      locals["name"] = name

      jadec = jade.compile data, {}
      res.writeHead 200, {'Content-Type': 'text/html'}
      res.end jadec(locals)
  else if parsed_url['pathname'] == '/charge'
    fullbody = ""
    req.on 'data', (chunk) ->
      fullbody += chunk.toString()
    req.on 'end', () ->
      query = querystring.parse fullbody
      if !query or !query['amount'] or !query['name'] or !query['stripeToken']
        res.writeHead 404
        res.end "404"
        return

      stripe_options = {}
      stripe_options['amount'] = parseInt(query['amount'])
      stripe_options['currency'] = 'USD'
      stripe_options['card'] = query['stripeToken']
      stripe_options['description'] = query['name']
      stripe.charges.create stripe_options, (err, charge) ->
        if err
          console.log err.message
          res.writeHead 500
          res.end "500"
        else
          console.log "Charged " + parseInt(query['amount']) + " for " +  query['name']
          res.writeHead 302, {'Location' : 'success'}
          res.end()
  else if parsed_url['pathname'] == '/success'
    res.writeHead 200, {'Content-Type': 'text/html'}
    res.end "Success"
  else
    res.writeHead 404
    res.end "404"

server.listen 9050, '127.0.0.1'
console.log 'Ready'

