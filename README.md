#### Dependencies
ffmpeg
- libz

SDL
- libbz2
- libconv
- CoreMedia
- CoreMotion
- CoreAudio
- QuartzCore
- OpenGLES
- GameCOntroller
- AudioToolbox
- VideoToolbox

image magick
- libxml
- CoreGraphick

#### Stream server setup
- nginx-full
- rtmp-nginx-module

in

	/usr/local/etc/nginx/nginx.conf
add

	rtmp {
	    server {
	        listen 1935;
	        application live {
	            live on;
	            record all;
	            record_path /tmp;
	            record_max_size 1K;
	        }
	    }
	}