# glsl-sandbox
Online live editor for fragment shaders.
# install
Install MongoDB from https://www.mongodb.com/
Start mongodb by cding to mongodb folder and cd into Server->3.4->bin and type
>mongodb

Then use Mongo Compass to access database and create database "glsl"

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

Point your browser to http://localhost:9292
