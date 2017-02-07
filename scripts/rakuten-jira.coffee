# Description:
#  Quickly file JIRA tickets with hubot
#  Also listens for mention of tickets and responds with information
#
# Dependencies:
#   None
#
# Configuration:
#   HUBOT_JIRA_URL (format: "https://jira-domain.com:9090")
#   HUBOT_JIRA_USERNAME
#   HUBOT_JIRA_PASSWORD
#   HUBOT_JIRA_PROJECTS_MAP (format: "{\"web\":\"WEB\",\"android\":\"AN\",\"ios\":\"IOS\",\"platform\":\"PLAT\"}"
#
# Commands:
#   hubot bug - File a bug in JIRA corresponding to the project of the channel
#   hubot task - File a task in JIRA corresponding to the project of the channel
#   hubot story - File a story in JIRA corresponding to the project of the channel
#
# Author:
#   ndaversa



##Global Variables

module.exports = (robot) ->
  debug = process.env.HUBOT_JIRA_DEBUG
  jiraUrl = process.env.HUBOT_JIRA_URL
  jiraUsername = process.env.HUBOT_JIRA_USERNAME
  jiraPassword = process.env.HUBOT_JIRA_PASSWORD
  projects = JSON.parse process.env.HUBOT_JIRA_PROJECTS_MAP
  prefixes = (key for team, key of projects).reduce (x,y) -> x + "-|" + y
  jiraPattern = eval "/(^|\\s|\b)(" + "hcbot" + "-)(\d+)\b/gi"
  transitions = {
    'close': 2,
    'start': 4,
    'resolve': 5
  };




  change = (transitiontype, msg) ->

    console.log "Here is the match : #{msg.match[0]}"
    console.log "Here is the match : #{msg.match[1]}"
    console.log "Here is the match : #{msg.match[2]}"


    if typeof msg.match[2] isnt 'undefined' then comment = "No Comment"

    else
      comment = msg.match[2]

    ticket = msg.match[1]
  
    console.log ticket
    #console.log state 
    console.log transitiontype 
    console.log comment
    j = {"update": {"comment": [{"add": {"body": "#{comment}"}}]},"transition": {"id": "#{transitiontype}"}}
    console.log j
    data1 = JSON.stringify(j)
    robot.http("#{jiraUrl}/rest/api/2/issue/#{ticket.trim().toUpperCase()}/transitions")
      .header('Content-Type', 'application/json')
      .auth(auth)
      .post(data1) (err, res, body) ->
          try
            data = JSON.parse body
            console.log data
            #msg.send "<@#{msg.message.user.id}> Error: #{data.errorMessages}"
          catch error
            msg.send "<@#{msg.message.user.id}> Error: #{msg.error}"
    return







#Post a new ticket, based on ticket type
  if jiraUsername != undefined && jiraUsername.length > 0
    auth = "#{jiraUsername}:#{jiraPassword}"
    console.log auth
    console.log projects
    console.log jiraPattern
    report = (project, type, msg) ->
      console.log project, type, msg
      reporter = null
      robot.http("#{jiraUrl}/rest/api/2/user/search?username=#{msg.message.user.email_address}")
        .header("Content-Type", "application/json")
        .auth(auth)
        .get() (err, res, body) ->
            
            console.log body
            try
              user = JSON.parse body

              reporter = user[0] if user and user.length is 1
            finally
              quoteRegex = /`(.*?)`/
              labelsRegex = /#\S+\s?/g
              labels = ["triage"]
              components = [{
                name : 'test'
              }]
              message = msg.match[1]

              desc = message.match(quoteRegex)[1] if quoteRegex.test(message)
              message = message.replace(quoteRegex, "") if desc

              if labelsRegex.test(message)
                labels = (message.match(labelsRegex).map((label) -> label.replace('#', '').trim())).concat(labels)
                message = message.replace(labelsRegex, "")
                console.log labels,message if debug

              issue =
                fields:
                  project:
                    key: project
                  summary: message
                  components: components
                  labels: labels
                  description: (if desc then desc + "\n\n" else "") +
                               """
                               Reported by #{msg.message.user.name} in ##{msg.message.room} on #{robot.adapterName}
                               """
                  issuetype:
                    name: type

              issue.fields.reporter = reporter if reporter
              issue = JSON.stringify issue
              console.log issue
              robot.http("#{jiraUrl}/rest/api/2/issue")
                .header("Content-Type", "application/json")
                .auth(auth)
                .post(issue) (err, res, body) ->
                  console.log body if debug
                  try
                    if res.statusCode is 201
                      json = JSON.parse body
                      msg.send "<@#{msg.message.user.id}> Ticket created: #{jiraUrl}/browse/#{json.key}"
                    else
                      msg.send "<@#{msg.message.user.id}> Unable to create ticket"
                      console.log "statusCode:", res.statusCode, "err:", err, "body:", body
                  catch error
                    msg.send "<@#{msg.message.user.id}> Unable to create ticket: #{error}"
                    console.log "statusCode:", res.statusCode, "error:", error, "err:", err, "body:", body

#If a story is heard/ make a story
    robot.respond /ticket create story (.+)/i, (msg) ->
      room = msg.message.room
      project = projects[room]
      console.log room
      console.log projects
      console.log key of projects
      return msg.reply "Stories must be submitted in one of the following project channels:" + (" <\##{team}>" for team, key of projects) if not project
      report project, "Story", msg

#Create a bug
    robot.respond /ticket create bug (.+)/i, (msg) ->
      room = msg.message.room
      project = projects[room]
      return msg.reply "Bugs must be submitted in one of the following project channels:" + (" <\##{team}>" for team, key of projects) if not project
      report project, "Bug", msg

#Create a task
    robot.respond /ticket create task (.+)/i, (msg) ->
      room = msg.message.room
      project = projects[room]
      return msg.reply "Tasks must be submitted in one of the following project channels:" + (" <\##{team}>" for team, key of projects) if not project
      report project, "Task", msg
#Assign a task to someone
    robot.hear /assign (.+) (@.+)/i, (msg) ->
      
      ticket = msg.match[1]
      assignee = msg.match[2]
      
      console.log message
      console.log assignee
      console.log ticket
      name = assignee.replace('@', '')  
      users = robot.brain.usersForFuzzyName(name)
      if users.length is 1
        user = users[0]

      assigneeusername = user.email_address.substring(0, user.email_address.indexOf('@'))

      message = ticket + ": " + assigneeusername

      console.log assigneeusername

         # Do something interesting here..
      console.log users


      console.log "#{jiraUrl}/rest/api/2/issue/#{ticket.trim().toUpperCase()}"
      j = {"fields":{"summary":"Assigned to #{assigneeusername}","assignee":{"name":"#{assigneeusername}"}}}
      data1 = JSON.stringify(j)
      console.log j
      console.log data1
      robot.http("#{jiraUrl}/rest/api/2/issue/#{ticket.trim().toUpperCase()}")
        .header('Content-Type', 'application/json')
        .auth(auth)
        .post(data1) (err, res, body) ->
            try
              console.log "parsing data.... "
             
              msg.reply "#{ticket.trim().toUpperCase()} assigned to #{user.real_name}"

            catch error
              msg.reply error

    
      return 

#Move a ticket through it's states
    robot.hear /close (.*)/i, (msg) ->
    
      transition = 2

      change transition, msg

   robot.hear /resolve (.*)/i, (msg) ->
      
      transition = 5

      change transition, msg

   robot.hear /start (.*)/i, (msg) ->
        
      transition = 4

      change transition, msg

    robot.hear /(hcbot-)(\d+$)/, (msg) ->
      issue = msg.match[0]
      robot.http("#{jiraUrl}/rest/api/2/issue/#{issue.trim().toUpperCase()}")
        .auth(auth)
        .get() (err, res, body) ->
          try
            json = JSON.parse body
            message = """
                      *[#{json.key}] - #{json.fields.summary}*
                      Status: #{json.fields.status.name}
                      """

            if  json.fields.assignee and json.fields.assignee.displayName
              message += "\nAssignee: #{json.fields.assignee.displayName}\n"
            else
              message += "\nUnassigned\n"

            message += """
                       Reporter: #{json.fields.reporter.displayName}
                       JIRA: #{jiraUrl}/browse/#{json.key}\n
                       """

            robot.http("#{jiraUrl}/rest/dev-status/1.0/issue/detail?issueId=#{json.id}&applicationType=github&dataType=branch")
              .auth(auth)
              .get() (err, res, body) ->
                try
                  json = JSON.parse body
                  if json.detail?[0]?.pullRequests
                    for pr in json.detail[0].pullRequests
                      message += "PR: #{pr.url}\n"
                finally
                  msg.send message

          catch error
            try
             msg.send "*[Error]* #{json.errorMessages[0]}"
            catch busted
              msg.send "*[Error]* #{busted}"
      

      
        
            
          


