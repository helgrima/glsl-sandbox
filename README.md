# glsl-sandbox
Online live editor for fragment shaders.
# install
Windows
Install MongoDB from https://www.mongodb.com/
Start mongodb by cding to mongodb folder and cd into Server->3.4->bin and type
>mongod.exe

Linux
Most likely mongodb is already running, if you have installed it. Even better is to run mongo on server and use for example SSH tunnel to connect mongo from development machine. Following command creates SSH tunnel from you development machines port 27017 to server's port 27017
>ssh -f your-username@server-ip -L 27017:localhost:27017 -N

Then use Mongo Compass(or some other tool) to access database and create database "glsl"

Install ruby(in windows rubyinstaller https://rubyinstaller.org/)

Install everything what rubyinstaller suggests

Open CMD with Ruby and type 
>gem install bundler

cd into project's folder and type 
>bundle install

That should install all dependencies

Make sure that you install newer version of json gem but keep old versions of other gems

# run
Modify function initialize_cloudinary in model.rb to include your cloudinary api keys
To run type in at projects folder
>rackup

If running on Linux, it is suggested that first you install rerun gem
>gem install rerun
And after that run
>rerun 'rackup'
This way ruby will catch all file changes and reload rack, so you can easily modify all files. NOTICE rerun is not supported by Windows

Point your browser to http://localhost:9292
