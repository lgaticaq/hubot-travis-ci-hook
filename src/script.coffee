# Description
#   Clone travis integration with slack
#
# Dependencies:
#   crypto, parse-ms
#
# Configuration:
#   TRAVIS_PRO, TRAVIS_SHORT
#
# Commands:
#   None
#
# Author:
#   lgaticaq

crypto = require("crypto")
parseMs = require("parse-ms")

# coffeelint: disable=max_line_length
icons = [
  "https://cdn.travis-ci.com/images/logos/TravisCI-Mascot-1-20feeadb48fc2492ba741d89cb5a5c8a.png"
  "https://cdn.travis-ci.com/images/logos/TravisCI-Mascot-2-05e0a25826cabd8cd4ad265f9e47b0b5.png"
  "https://cdn.travis-ci.com/images/logos/TravisCI-Mascot-3-53205345fb60d55134faf2871bf4394f.png"
  "https://cdn.travis-ci.com/images/logos/TravisCI-Mascot-4-364f3fca6c400bceab00bdf565b17af1.png"
  "https://cdn.travis-ci.com/images/logos/TravisCI-Mascot-grey-8a0cb7d8c3aa57b9b1e981c0e3f1db13.png"
  "https://cdn.travis-ci.com/images/logos/TravisCI-Mascot-blue-50a7eace1d5009af5b1229b03c5b2775.png"
  "https://cdn.travis-ci.com/images/logos/TravisCI-Mascot-red-ceeabb77262f6d2203fe7c3635b77b98.png"
  "https://cdn.travis-ci.com/images/logos/TravisCI-Mascot-pride-f062dd7e4391eea78a6a164ddc770754.png"
  "https://cdn.travis-ci.com/images/logos/TravisCI-Mascot-pride-4-deadef9f32270ef494b860e76aa366e8.png"
  "https://cdn.travis-ci.com/images/logos/Tessa-1-bdfba3fb6a74f87385afbdecd397f97e.png"
  "https://cdn.travis-ci.com/images/logos/Tessa-2-4913e90413586105249b4f55ca622ec8.png"
  "https://cdn.travis-ci.com/images/logos/Tessa-3-bba95a9bf2298f829b7c08e0af8f9c46.png"
  "https://cdn.travis-ci.com/images/logos/Tessa-4-42d2e224f0ab57afc32c74fac2653853.png"
  "https://cdn.travis-ci.com/images/logos/Tessa-pride-d7cfbd39009645bbecd005212aa1d338.png"
  "https://cdn.travis-ci.com/images/logos/Tessa-pride-4-49f04b06d4009a791ea88d198934da29.png"
]

verifySignature = (signature, payload, publicKey) ->
  verifier = crypto.createVerify("sha1")
  verifier.update(payload)
  return verifier.verify(publicKey, signature, "base64")

getPublicKey = (robot) ->
  return new Promise (resolve, reject) ->
    if process.env.TRAVIS_PRO is "true"
      url = "https://api.travis-ci.com/config"
    else
      url = "https://api.travis-ci.org/config"
    robot.http(url)
      .header("User-Agent", robot.name)
      .get() (err, res, body) ->
        if err
          reject(err)
        else if res.statusCode isnt 200
          reject(new Error("Error response code #{res.statusCode}"))
        else
          try
            data = JSON.parse(body)
            resolve(data.config.notifications.webhook.public_key)
          catch err
            reject(err)

getAuthor = (robot, owner, name, sha) ->
  return new Promise (resolve, reject) ->
    robot.http("https://api.github.com/repos/#{owner}/#{name}/commits/#{sha}")
      .header("User-Agent", robot.name)
      .get() (err, res, body) ->
        if err
          reject(err)
        else if res.statusCode isnt 200
          reject(new Error("Error response code #{res.statusCode}"))
        else
          try
            data = JSON.parse(body)
            resolve
              name: data.commit.author.name
              url: data.author.html_url
              avatar: data.author.avatar_url
              commit: data.html_url
          catch err
            reject(err)

getAttachments = (robot, req) ->
  return new Promise (resolve, reject) ->
    try
      signature = req.get("Signature") or ""
      payload = req.body.payload
      data = JSON.parse(payload)
      sha = data.commit.substr(0, 7)
      ms = parseMs(data.duration * 1000)
      days = if ms.days > 0 then "#{ms.days} d" else ""
      if ms.hours > 0
        if days is ""
          hours = "#{ms.hours} h"
        else
          hours = " #{ms.hours} h"
      else
        hours = ""
      if ms.minutes > 0
        if hours is ""
          minutes = "#{ms.minutes} min"
        else
          minutes = " #{ms.minutes} min"
      else
        minutes = ""
      if ms.seconds > 0
        if minutes is ""
          seconds = "#{ms.seconds} sec"
        else
          seconds = " #{ms.seconds} sec"
      else
        seconds = ""
      duration = "#{days}#{hours}#{minutes}#{seconds}"
      icon = icons[Math.floor(Math.random() * icons.length)]
      color = switch data.status_message
        when "Pending" then "warning"
        when "Passed" then "good"
        when "Fixed" then "good"
        when "Broken" then "danger"
        when "Failed" then "danger"
        when "Still Failing" then "danger"
        else "warning"
      promises = [
        getPublicKey(robot)
          .then (publicKey) ->
            verifySignature(signature, payload, publicKey)
        getAuthor(
          robot, data.repository.owner_name, data.repository.name, data.commit)
      ]
      Promise.all(promises)
        .then (results) ->
          [isValid, author] = results
          fallback = "Build ##{data.number} (#{sha}) of " +
            "#{data.repository.owner_name}/#{data.repository.name}" +
            "@#{data.branch} by #{author.name} " +
            "#{data.status_message.toLowerCase()} in #{duration}"
          message = "Build <#{data.build_url}|##{data.number}> " +
            "(<#{data.compare_url}|#{sha}>) of " +
            "#{data.repository.owner_name}/#{data.repository.name}" +
            "@#{data.branch} by " +
            "<#{author.url}|#{author.name}> " +
            "#{data.status_message.toLowerCase()} in #{duration}"
          compare = data.compare_url.split("/compare/").reverse().shift()
          full =
            as_user: false
            link_names: 1
            icon_url: icon
            username: "Travis CI"
            attachments: [
              fallback: fallback
              color: color
              author_name: author.name
              author_link: author.url
              author_icon: author.avatar
              title: "#{data.status_message} Build ##{data.number}"
              title_link: data.build_url
              text: data.message
              fields: [
                {
                    title: "Branch"
                    value: "#{data.branch}"
                    short: true
                },
                {
                    title: "Commit"
                    value: "<#{author.commit}|#{sha}>"
                    short: true
                },
                {
                    title: "Compare"
                    value: "<#{data.compare_url}|#{compare}>"
                    short: true
                },
                {
                    title: "Duration"
                    value: duration
                    short: true
                }
              ]
            ]
          short =
            as_user: false
            link_names: 1
            icon_url: icon
            username: "Travis CI"
            attachments: [
              fallback: fallback
              color: color
              text: message
            ]
          resolve
            isValid: isValid
            fallback: fallback
            full: full
            short: short
        .catch (err) ->
          reject(err)
    catch err
      reject(err)

module.exports = (robot) ->
  robot.router.post "/travis-ci/:room", (req, res) ->
    channel = req.params.room
    getAttachments(robot, req)
      .then (results) ->
        if results.isValid
          if robot.adapter.constructor.name in ["SlackBot", "Room"]
            if process.env.TRAVIS_SHORT is "true"
              robot.adapter.client.web.chat.postMessage(
                "##{channel}", null, results.short)
              res.send("Ok")
            else
              robot.adapter.client.web.chat.postMessage(
                "##{channel}", null, results.full)
              res.send("Ok")
          else
            robot.messageRoom(channel, results.fallback)
            res.send("Ok")
        else
          err = new Error("Signed payload does not match signature")
          robot.messageRoom(channel, "An error has occurred: #{err.message}")
          robot.emit("error", err)
          res.send("Error")
      .catch (err) ->
        robot.messageRoom(channel, "An error has occurred: #{err.message}")
        robot.emit("error", err)
        res.send("Error")
