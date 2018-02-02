# roblox-image-size

A web server that provides an endpoint which in turn fetches and responds with the height and width of a Roblox image asset.

Note: This only works for *image* assets, not *decals*

## To use

GET `/image-size/1287038887` - substitute your own image id

```json
{
  "width": 333,
  "height": 650,
  "type": "png"
}
```
