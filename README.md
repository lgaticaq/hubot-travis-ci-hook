# hubot-travis-ci-hook

[![npm version](https://img.shields.io/npm/v/hubot-travis-ci-hook.svg)](https://www.npmjs.com/package/hubot-travis-ci-hook)
[![npm downloads](https://img.shields.io/npm/dm/hubot-travis-ci-hook.svg)](https://www.npmjs.com/package/hubot-travis-ci-hook)
[![Build Status](https://travis-ci.org/lgaticaq/hubot-travis-ci-hook.svg?branch=master)](https://travis-ci.org/lgaticaq/hubot-travis-ci-hook)
[![Coverage Status](https://coveralls.io/repos/github/lgaticaq/hubot-travis-ci-hook/badge.svg)](https://coveralls.io/github/lgaticaq/hubot-travis-ci-hook)
[![Maintainability](https://api.codeclimate.com/v1/badges/88b9cc7da316027daaef/maintainability)](https://codeclimate.com/github/lgaticaq/hubot-travis-ci-hook/maintainability)
[![dependency Status](https://img.shields.io/david/lgaticaq/hubot-travis-ci-hook.svg)](https://david-dm.org/lgaticaq/hubot-travis-ci-hook#info=dependencies)
[![devDependency Status](https://img.shields.io/david/dev/lgaticaq/hubot-travis-ci-hook.svg)](https://david-dm.org/lgaticaq/hubot-travis-ci-hook#info=devDependencies)

> Clone travis integration with slack

## Install

```bash
npm i -S hubot-travis-ci-hook
```

Add `["hubot-travis-ci-hook"]` in `external-scripts.json`.

Optional set `TRAVIS_PRO=true` if use travis enterprise.

Optional set `TRAVIS_SHORT=true` if use short notification.

Configure webhook notifications in .travis-ci.yml

```yml
notifications:
  webhooks: http://your-hubot-host/travis-ci/room-name
```

Replace `room-name` with the slack or hubot channel

Full notification

![full](http://pix.toile-libre.org/upload/original/1488246621.png)

Short notification

![short](http://pix.toile-libre.org/upload/original/1488246665.png)

## License

[MIT](https://tldrlegal.com/license/mit-license)
