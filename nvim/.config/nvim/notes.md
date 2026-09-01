#Skurrilum v1.0.1

- [x] https://skurrilum.de/imprint/ -> https://skurrilum.de/impressum/
- [ ] deactivate page scroll on mobile when nav is open
- [ ] add ssh
- [ ] fingerprint all resources
- [ ] fix server problems
- [ ] add atomic deployment, see https://chatgpt.com/c/69976fcb-39b0-838b-94bd-d9f9e402b9bf
- [ ] cookie banner deutsch

Fixes:

- [x] navbar not visible on smaller screens
- [ ] robots.txt (for staging)
- [x] sitemap
- [ ] scroll issues for the room carrousel [x] barrierefreitheitserklaerung du vs sie
- [x] footer items should stack properly
- [x] fix: testimonials.min.d08…037a7febf6fc9c.js:1 Uncaught TypeError: Cannot read properties of null (reading 'children')
      at HTMLDocument.<anonymous> (testimonials.min.d08…7febf6fc9c.js:1:123)

# ESA

- search query saved in url (state -> sst)
- we remove from DOM

{
      "type": "imageCarousel",
      "slides": [
        {
          "text": "Video of rocket launch",
          "altText": "",
          "url": "assets/launch.mp4"
        },
        {
          "text": "Pressure ridge in thick Arctic sea ice, formed as two ice floes converge. (Seymour Laxon/CPOM/UCL)",
          "altText": "Pressure ridge in Arctic sea ice",
          "url": "assets/story37-image02.jpg"
        },
        {
          "text": "Sea ice in Resolute Bay, Canada, from Sentinel-2. (Modified Copernicus Sentinel data (2019), processed by Pierre Markuse)",
          "altText": "Sea ice in Resolute Bay, Canada",
          "url": "assets/story37-image04.jpg"
        },
        {
          "text": "Melting sea ice swirls off the east coast of Greenland \nin this Sentinel-2 image taken on 20 April, 2020 (contains modified Copernicus Sentinel data (2020))",
          "altText": "Melting sea ice off the east coast of Greenland",
          "url": "assets/story37-image05.jpg"
        }
      ]
    }

{
      "type": "imageScroll",
      "slides": [
        {
          "url": "assets/launch.mp4",
          "focus": "center",
          "alt": "some alt text",
          "text": "A cool video",

          "caption": "video of rocket launch"
        },
        {
          "focus": "right",
          "url": "assets/story21-image06.png",
          "text": "## Global Mean Sea Level \r\n\r\n The global sea level observed by satellites shows an upward trend of 3.3 mm per year, but a decline in 2011 due to the large amount of excess water on land. \r\n\r\n Lorem ipsum dolor sit amet consectetur. Pellentesque ut blandit massa ut non enim turpis. Venenatis enim nibh turpis potenti fringilla. ",
          "alt": "Copernicus Marine Environment Monitoring Service",
          "caption": "### Caption \r\n\r\n ESA-CCI/Copernicus Marine Environment Monitoring Service"
        },
        {
          "url": "assets/story21-image12.jpg",
          "text": "## New South Wales, Australia \r\n\r\n Copernicus Sentinel-1 radar images from March 7 and 19, 2021, show extensive flooded areas in blue. Areas burned by wildfires in the previous year are shown in brown.           ",
          "alt": "Copernicus Marine Environment Monitoring Service",
          "caption": "### Caption \r\n\r\n Contains modified Copernicus Sentinel data (2021), processed by ESA / NASA MODIS"
        }
      ]
    }
