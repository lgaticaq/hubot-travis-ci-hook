path = require("path")
Helper = require("hubot-test-helper")
expect = require("chai").expect
http = require("http")
querystring = require("querystring")
nock = require("nock")

helper = new Helper("./../src/index.coffee")

# coffeelint: disable=max_line_length

signature = "OZN3avz+ka7LmwKX8ktcLH0gRfCD9eKZFaPUK/FOSlDM0CIV5TBtkQzf1aSmTpbKYUrIO33NVpy6oZKArrUVzNOxIi7Ql0aIcq6liok3qQRfCnXdQz/XH8fGdf+qmOfJg3Sq3r0RFfy6MSK7+XXhN6URhOL5NnA2FY5TN1PbQQs="
publicKey = "-----BEGIN PUBLIC KEY-----\nMIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDEuUFMdVHfpiNT7qD5FnpyLayS\nMrdTuvZTrvAZb+/kF7neRSYujwJQtY9HlfYZMG1PrlUA8s9WjIND+yEn4S8Sf+rG\noTvfEZeeazbt9YfSihgchDagqw+Gfl8VgPPrfSWjc5B48DCfilxat5LXhvJSr/O1\ndMW+/r4P9U0KFWndSQIDAQAB\n-----END PUBLIC KEY-----\n"

describe "travis-ci", ->
  postData = querystring.stringify
    payload: JSON.stringify
      repository:
        name: "tz-parser"
        owner_name: "lgaticaq"
      number: "234"
      status_message: "Passed"
      duration: 89
      build_url: "https://travis-ci.org/lgaticaq/tz-parser/builds/206024730"
      commit: "1ac902485e99fd4e3c95790f3858e552eb32867d"
      branch: "master"
      message: "Test webhooks"
      compare_url: "https://github.com/lgaticaq/tz-parser/compare/cf5c52f52876...1ac902485e99"
  postOptions =
    hostname: "localhost"
    port: 8080
    path: "/travis-ci/random"
    method: "POST"
    headers:
      "Content-Type": "application/x-www-form-urlencoded"
      "Content-Length": Buffer.byteLength(postData)
      "Signature": signature
  postOptionsError =
    hostname: "localhost"
    port: 8080
    path: "/travis-ci/random"
    method: "POST"
    headers:
      "Content-Type": "application/x-www-form-urlencoded"
      "Content-Length": Buffer.byteLength(postData)

  beforeEach ->
    @room = helper.createRoom({name: "random"})

  afterEach ->
    @room.destroy()

  context "POST /travis-ci/random", ->
    beforeEach (done) ->
      process.env.TRAVIS_PRO = "false"
      process.env.TRAVIS_SHORT = "false"
      @room.robot.adapter.client =
        web:
          chat:
            postMessage: (channel, text, options) =>
              @postMessage =
                channel: channel
                text: text
                options: options
              done()
      nock("https://api.github.com")
        .get("/repos/lgaticaq/tz-parser/commits/1ac902485e99fd4e3c95790f3858e552eb32867d")
        .reply 200, JSON.stringify
          commit:
            author: {name: "user"}
          html_url: "https://github.com/lgaticaq/tz-parser/commit/1ac902485e99fd4e3c95790f3858e552eb32867d"
          author:
            avatar_url: "https://avatars.githubusercontent.com/u/123456?v=3"
            html_url: "https://github.com/user"
      nock("https://api.travis-ci.org")
        .get("/config")
        .reply 200, JSON.stringify
          config:
            notifications:
              webhook:
                public_key: publicKey
      req = http.request postOptions, (response) =>
        @response = response
      req.write(postData)
      req.end()

    it "responds with status 200 and results", ->
      expect(@postMessage.channel).to.eql("#random")
      expect(@postMessage.text).to.be.null
      expect(@postMessage.options.as_user).to.be.false
      expect(@postMessage.options.link_names).to.eql(1)
      expect(@postMessage.options.username).to.eql("Travis CI")
      expect(@postMessage.options.attachments).to.eql [
        author_icon: "https://avatars.githubusercontent.com/u/123456?v=3"
        author_link: "https://github.com/user"
        author_name: "user"
        color: "good"
        fallback: "Build #234 (1ac9024) of lgaticaq/tz-parser@master by user passed in 1 min 29 sec"
        fields: [
          {
            short: true
            title: "Branch"
            value: "master"
          }
          {
            short: true
            title: "Commit"
            value: "<https://github.com/lgaticaq/tz-parser/commit/1ac902485e99fd4e3c95790f3858e552eb32867d|1ac9024>"
          }
          {
            short: true
            title: "Compare"
            value: "<https://github.com/lgaticaq/tz-parser/compare/cf5c52f52876...1ac902485e99|cf5c52f52876...1ac902485e99>"
          }
          {
            short: true
            title: "Duration"
            value: "1 min 29 sec"
          }
        ]
        text: "Test webhooks"
        title: "Passed Build #234"
        title_link: "https://travis-ci.org/lgaticaq/tz-parser/builds/206024730"
      ]

  context "POST /travis-ci/random short notification", ->
    beforeEach (done) ->
      process.env.TRAVIS_PRO = "true"
      process.env.TRAVIS_SHORT = "true"
      @room.robot.adapter.client =
        web:
          chat:
            postMessage: (channel, text, options) =>
              @postMessage =
                channel: channel
                text: text
                options: options
              done()
      nock("https://api.github.com")
        .get("/repos/lgaticaq/tz-parser/commits/1ac902485e99fd4e3c95790f3858e552eb32867d")
        .reply 200, JSON.stringify
          commit:
            author: {name: "user"}
          html_url: "https://github.com/lgaticaq/tz-parser/commit/1ac902485e99fd4e3c95790f3858e552eb32867d"
          author:
            avatar_url: "https://avatars.githubusercontent.com/u/123456?v=3"
            html_url: "https://github.com/user"
      nock("https://api.travis-ci.com")
        .get("/config")
        .reply 200, JSON.stringify
          config:
            notifications:
              webhook:
                public_key: publicKey
      req = http.request postOptions, (response) =>
        @response = response
      req.write(postData)
      req.end()

    it "responds with status 200 and results", ->
      expect(@postMessage.channel).to.eql("#random")
      expect(@postMessage.text).to.be.null
      expect(@postMessage.options.as_user).to.be.false
      expect(@postMessage.options.link_names).to.eql(1)
      expect(@postMessage.options.username).to.eql("Travis CI")
      expect(@postMessage.options.attachments).to.eql [
        color: "good"
        fallback: "Build #234 (1ac9024) of lgaticaq/tz-parser@master by user passed in 1 min 29 sec"
        text: "Build <https://travis-ci.org/lgaticaq/tz-parser/builds/206024730|#234> (<https://github.com/lgaticaq/tz-parser/compare/cf5c52f52876...1ac902485e99|1ac9024>) of lgaticaq/tz-parser@master by <https://github.com/user|user> passed in 1 min 29 sec"
      ]

  context "Server error in travis api", ->
    beforeEach (done) ->
      process.env.TRAVIS_PRO = "false"
      process.env.TRAVIS_SHORT = "false"
      nock("https://api.github.com")
        .get("/repos/lgaticaq/tz-parser/commits/1ac902485e99fd4e3c95790f3858e552eb32867d")
        .reply 200, JSON.stringify
          commit:
            author: {name: "user"}
          html_url: "https://github.com/lgaticaq/tz-parser/commit/1ac902485e99fd4e3c95790f3858e552eb32867d"
          author:
            avatar_url: "https://avatars.githubusercontent.com/u/123456?v=3"
            html_url: "https://github.com/user"
      nock("https://api.travis-ci.org")
        .get("/config")
        .replyWithError("something awful happened")
      @room.robot.on "error", (@apiError) => done()
      req = http.request postOptions
      req.on "error", done
      req.write(postData)
      req.end()

    it "responds with error", ->
      expect(@room.messages).to.eql [
        ["hubot", "An error has occurred: something awful happened"]
      ]
      expect(@apiError.message).to.eql "something awful happened"

  context "Server wrong statusCode in travis api", ->
    beforeEach (done) ->
      process.env.TRAVIS_PRO = "false"
      process.env.TRAVIS_SHORT = "false"
      nock("https://api.github.com")
        .get("/repos/lgaticaq/tz-parser/commits/1ac902485e99fd4e3c95790f3858e552eb32867d")
        .reply 200, JSON.stringify
          commit:
            author: {name: "user"}
          html_url: "https://github.com/lgaticaq/tz-parser/commit/1ac902485e99fd4e3c95790f3858e552eb32867d"
          author:
            avatar_url: "https://avatars.githubusercontent.com/u/123456?v=3"
            html_url: "https://github.com/user"
      nock("https://api.travis-ci.org")
        .get("/config")
        .reply(302)
      @room.robot.on "error", (@apiError) => done()
      req = http.request postOptions
      req.on "error", done
      req.write(postData)
      req.end()

    it "responds with error", ->
      expect(@room.messages).to.eql [
        ["hubot", "An error has occurred: Error response code 302"]
      ]
      expect(@apiError.message).to.eql "Error response code 302"

  context "Server error in github api", ->
    beforeEach (done) ->
      process.env.TRAVIS_PRO = "false"
      process.env.TRAVIS_SHORT = "false"
      nock("https://api.github.com")
        .get("/repos/lgaticaq/tz-parser/commits/1ac902485e99fd4e3c95790f3858e552eb32867d")
        .replyWithError("something awful happened")
      nock("https://api.travis-ci.org")
        .get("/config")
        .reply 200, JSON.stringify
          config:
            notifications:
              webhook:
                public_key: publicKey
      @room.robot.on "error", (@apiError) => done()
      req = http.request postOptions
      req.on "error", done
      req.write(postData)
      req.end()

    it "responds with error", ->
      expect(@room.messages).to.eql [
        ["hubot", "An error has occurred: something awful happened"]
      ]
      expect(@apiError.message).to.eql "something awful happened"

  context "Server wrong statusCode in github api", ->
    beforeEach (done) ->
      process.env.TRAVIS_PRO = "false"
      process.env.TRAVIS_SHORT = "false"
      nock("https://api.github.com")
        .get("/repos/lgaticaq/tz-parser/commits/1ac902485e99fd4e3c95790f3858e552eb32867d")
        .reply(302)
      nock("https://api.travis-ci.org")
        .get("/config")
        .reply 200, JSON.stringify
          config:
            notifications:
              webhook:
                public_key: publicKey
      @room.robot.on "error", (@apiError) => done()
      req = http.request postOptions
      req.on "error", done
      req.write(postData)
      req.end()

    it "responds with error", ->
      expect(@room.messages).to.eql [
        ["hubot", "An error has occurred: Error response code 302"]
      ]
      expect(@apiError.message).to.eql "Error response code 302"

  context "Invalid signature", ->
    beforeEach (done) ->
      process.env.TRAVIS_PRO = "false"
      process.env.TRAVIS_SHORT = "false"
      nock("https://api.github.com")
        .get("/repos/lgaticaq/tz-parser/commits/1ac902485e99fd4e3c95790f3858e552eb32867d")
        .reply 200, JSON.stringify
          commit:
            author: {name: "user"}
          html_url: "https://github.com/lgaticaq/tz-parser/commit/1ac902485e99fd4e3c95790f3858e552eb32867d"
          author:
            avatar_url: "https://avatars.githubusercontent.com/u/123456?v=3"
            html_url: "https://github.com/user"
      nock("https://api.travis-ci.org")
        .get("/config")
        .reply 200, JSON.stringify
          config:
            notifications:
              webhook:
                public_key: publicKey
      @room.robot.on "error", (@apiError) => done()
      req = http.request postOptionsError
      req.on "error", done
      req.write(postData)
      req.end()

    it "responds with error", ->
      expect(@room.messages).to.eql [
        ["hubot", "An error has occurred: Signed payload does not match signature"]
      ]
      expect(@apiError.message).to.eql "Signed payload does not match signature"

  # context "POST /travis-ci/deploy redirect", ->
  #   beforeEach (done) ->
  #     nock("https://api.github.com")
  #       .get("/repos/lgaticaq/tz-parser/commits/1234567")
  #       .reply(302)
  #     @room.robot.on "error", (@apiError) => done()
  #     req = http.request postOptions, (@response) => done()
  #     req.on "error", done
  #     req.write(postData)
  #     req.end()

  #   it "responds with status 200 and results", ->
  #     expect(@apiError.message).to.eql "Error response code 302"
