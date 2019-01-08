###
Useful sites
https://coffeescript-cookbook.github.io/chapters/functions/splat_arguments
http://coffeescript.org/#literals
https://github.com/lapwinglabs/x-ray
http://js2coffee.thomaskalka.de/
http://js2.coffee/
https://github.com/mquandalle/meteor-jade
http://html2jade.aaron-powell.com/
https://atmospherejs.com/lai/meteor-xray
http://www.datafiddle.net/allscripts
###

if Meteor.isClient
  Template.hello.helpers
    hockeyUrl: -> "http://www.hockey-reference.com/players/s/shacked01.html"
    hockeyFormat: -> "#stats_basic_nhl > thead > tr:nth-child(2) > th"
    
  Template.hello.events
    'click #bt_ch': () ->
      Meteor.call "chScrape", tb_url.value, tb_format.value,
        (error, result) ->
          console.log "click ", result
          Session.set "header", result
          tb_ch.value = result
      
    'click #bt_jq': () ->
      Meteor.call "jqScrape", tb_url.value, tb_format.value,
        (error, result) ->
          console.log "click ", result
          Session.set "header", result
          tb_jq.value = result
          
    'click #bt_xray': () ->
      Meteor.call "xrayScrape", tb_url.value, tb_format.value,
        (error, result) ->
          console.log "click ", result
          Session.set "header", result
          tb_xray.value = result

if Meteor.isServer
  Meteor.methods
    ###  scrape using cheerio.js ###
    chScrape: (url, format) -> 
      html = Meteor.http.get(url)

      $ = Meteor.npmRequire("cheerio").load(html.content)
      chResults = $(format)
        .map (i, elem) ->
          $(elem).text()
        .get().join(" ")
      console.log "chResults ", chResults
      chResults
  
    ###  scrape using jsdom/jquery ###
    jqScrape: (url,format) ->
      html = Meteor.http.get(url)
      
      # http://stackoverflow.com/questions/21358015/error-jquery-requires-a-window-with-a-document
      jq = Meteor.npmRequire("jquery")(Meteor.npmRequire("jsdom").jsdom().parentWindow)
      jqDoc = jq(html.content)

      # http://stackoverflow.com/questions/23866237/jquery-cheerio-going-over-an-array-of-elements
      jqResults = jqDoc
        .find(format)
        .map (i, elem) ->
          jq(elem).text()
        .get().join(" ")
      console.log "jqResults ", jqResults
      jqResults
      
    ###  scrape using x-ray.js ###
    xrayScrape: (url, format) -> 
#      check coffeescript self-initiating functions
      future = new (Npm.require 'fibers/future')()
      xray url
        .select([{
          $root: ['#stats_basic_nhl tr'],
          headers: ['th']
          data: ['td']
          }])
        .run (err,rowarr)->
          rowtextarr = for row in rowarr
            rowtext = ([row.headers..., row.data...]).join(" ") 
            console.log rowtext
            rowtext
          future.return rowtextarr
      xrayResults = do future.wait
      console.log "xrayResults", xrayResults[1]
      xrayResults[1]
          
    #    .write(process.stdout)