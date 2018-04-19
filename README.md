# [roblox-image-size](https://www.roblox.com/library/1382620367/ImageSize)

This [Roblox plugin](https://www.roblox.com/library/1382620367/ImageSize) uses a web API to fetch the real image size of the object you have selected and display it to you. It can also set the object's size to the native size, optionally maintaining one axis. This plugin also takes the texture from Decals inserted into ImageButtons and ImageLabels and sets it to the Image property and then deletes the decal.

A web server provides an endpoint which in turn fetches and responds with the height and width of a Roblox image asset.

Note: This only works for *image* assets, not *decals*

## To use the web server (self-hosting only, not required)

GET `/image-size/1287038887` - substitute your own image id

```json
{
  "width": 333,
  "height": 650,
  "type": "png"
}
```

# Goals
- [ ] Add a GUI-based message pop-up to tell the user about errors
  - [ ] Make the process of enabling after turning HTTP requests on more intuitive
