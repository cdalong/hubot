#hubot redis ops scripts

module.exports = (robot) ->

  robot.respond /who is @?([\w .\-]+)\?*$/i, (res) ->
    input = res.match[1].trim()
    name = input.replace('@', '')  
    console.log(name)
    users = robot.brain.usersForFuzzyName(name)
    console.log(users)

    if users.length is 1
      user = users[0]
      # Do something interesting here..
      console.log typeof user
      jirausername = user.email_address.substring(0, user.email_address.indexOf('@'))


      console.log jirausername
      res.send "#{user.name} is user email: #{user.email_address}"


  robot.respond /show users/i, (msg) ->
    response = "users :"

    for own key, user of robot.brain.data.users
      	response += "#{user.id} #{user.name}"
      	response += " <#{user.email_address}>" if user.email_address
      	response += "\n"

    msg.send response