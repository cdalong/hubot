module.exports = (robot) ->
  debug = process.env.HUBOT_JIRA_DEBUG
  openstackUrl = process.env.HUBOT_OPENSTACK_URL
  openstackUsername = process.env.HUBOT_OPENSTACK_USERNAME
  openstackPassword = process.env.HUBOT_OPENSTACK_PASSWORD
 



  robot.respond /openstack list instances (.+) (.+)/i, (msg) ->
      #Do logic Post to URL



  robot.respond /openstack list delete instance (.+) (.+)/i, (msg) ->
     #Post to Openstack URL

     