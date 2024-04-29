# Build my Radar

Note: You could previously build your own radar on `radar.thoughtworks.com` using custom quadrant and ring names. Going forward, on the online version of BYOR, you will need to use the 4 quadrant and ring names from the TW Tech Radar, as mentioned below:

* **Quadrant names:** Techniques, Platforms, Tools, Languages & Frameworks
* **Ring names:** Adopt, Trial, Assess, Hold

If you set up a local version of BYOR, you can configure custom quadrant and ring names. You can find more details in the readme file.

```bash
# Run docker container (linux/amd64)
docker run \
  --rm \
  --platform linux/amd64 \
  -p 8080:80 \
  -e SERVER_NAMES="localhost 127.0.0.1" \
  -v $PWD/files/:/opt/build-your-own-radar/files \
  wwwthoughtworks/build-your-own-radar:v1.1.5

# Test
http://localhost:8080

# Use following urls
http://localhost:8080/files/radar.csv
http://localhost:8080/files/vol29.csv
http://localhost:8080/files/vol30.csv
 
# Local files can be modified locally, however there is a delay until the server loads the new file.
````

File Format

```csv
Text,Adopt,Techniques,TRUE,""
Text,Trial,Techniques,TRUE,""
Text,Assess,Techniques,TRUE,""
Text,Hold,Techniques,TRUE,""

Text,Adopt,Platforms,TRUE,""
Text,Trial,Platforms,TRUE,""
Text,Assess,Platforms,TRUE,""
Text,Hold,Platforms,TRUE,""

Text,Adopt,Tools,TRUE,""
Text,Trial,Tools,TRUE,""
Text,Assess,Tools,TRUE,""
Text,Hold,Tools,TRUE,""

Text,Adopt,Languages & Frameworks,TRUE,""
Text,Trial,Languages & Frameworks,TRUE,""
Text,Assess,Languages & Frameworks,TRUE,""
Text,Hold,Languages & Frameworks,TRUE,""


```
