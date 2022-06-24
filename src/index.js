require('dotenv').config()
const express = require('express')
const fetch = require('node-fetch')
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
    const assetInfoRequest = await fetch(`https://assetdelivery.roblox.com/v2/assetId/${req.params.asset}`)
    if (!assetInfoRequest.ok) return output({error: true})

    const { errors, locations } = await assetInfoRequest.json()
    if (errors) return output({error: true})

    const assetRequest = await fetch(locations[0].location)
    if (!assetRequest.ok) return output({error: true})

    output(imageSize(await assetRequest.buffer()))
  } catch {
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
