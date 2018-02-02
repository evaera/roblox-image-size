require('dotenv').config()
const express = require('express')
const request = require('request')
const imageSize = require('image-size')

const app = express()
app.enable('trust proxy')

let Cooldowns = new Map()
let Cache = new Map()

app.get('/image-size/:asset', async (req, res) => {
  // Rate limit by IP address if enabled

  if (process.env.MAX_REQS_PER_MIN) {
    if (Cooldowns.has(req.ip) && Cooldowns.get(req.ip) > parseInt(process.env.MAX_REQS_PER_MIN)) {
      return res.json({error: true})
    }

    if (!Cooldowns.has(req.ip)) {
      Cooldowns.set(req.ip, 0)
    }

    Cooldowns.set(req.ip, Cooldowns.get(req.ip) + 1)
  }

  // Cache size data in memory

  if (Cache.has(req.params.asset)) {
    return res.json(Cache.get(req.params.asset))
  }

  const output = data => {
    Cache.set(req.params.asset, data)
    return res.json(data)
  }

  // Get image

  try {
    const chunks = []

    request(`http://www.roblox.com/asset/?id=${req.params.asset}`, {
      gzip: true // Roblox images are gzipped
    }).on('data', chunk => chunks.push(chunk)).on('end', () => {
      try {
        const buffer = Buffer.concat(chunks)

        output(imageSize(buffer))
      } catch (e) {
        output({error: true})
      }
    })
  } catch (e) {
    output({error: true})
  }
})

app.listen(process.env.PORT || 8000)

// Reset the IP rate limits every minte
if (process.env.MAX_REQS_PER_MIN) {
  setInterval(() => {
    Cooldowns = new Map()
  }, 60000)
}
