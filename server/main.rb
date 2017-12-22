
require 'rubygems'
require 'sinatra'
require 'mongo'
require 'json'
require 'erb'
require 'cloudinary'

$: << './server'

require 'model'

require 'pp'

configure do
    set :public_folder, 'server/assets'

    GALLERY=ERB.new(File.read('server/assets/gallery.html'))
    EFFECT=ERB.new(File.read("server/assets/index.html"))

    $glsl=GlslDatabase.new

    EFFECTS_PER_PAGE=50
    BASE_URL="http://localhost:9292/"
    USE_CLOUDINARY=false
end

get '/' do
    if(params[:page])
        page=params[:page].to_i
    else
        page=0
    end

    $glsl.use_cloudinary = USE_CLOUDINARY
    ef=$glsl.get_page(page, EFFECTS_PER_PAGE)
    ef.base_url = BASE_URL
    
    GALLERY.result(ef.bind)
end

get '/e' do
    ef=Effect.new(BASE_URL)
    EFFECT.result(ef.bind)
end

get %r{/item/(\d+)([/.](\d+))?} do
    code_id=params[:captures][0].to_i
    if params[:captures][1]
        version_id=params[:captures][2].to_i
    else
        version_id=nil
    end

    $glsl.get_code_json(code_id, version_id)
end

post '/e' do
    body=request.body.read
    $glsl.save_effect(body)
end

get '/diff' do
    send_file 'server/assets/diff.html'
end


# redirects

get '/new' do
    redirect '/e', 301
end

get %r{^/(\d+)(/(\d+))?$} do
    url="/e##{params[:captures][0]}"
    url+=".#{params[:captures][2]}" if params[:captures][1]
    redirect url, 301
end



