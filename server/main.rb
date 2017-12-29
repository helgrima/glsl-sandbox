
require 'rubygems'
require 'sinatra'
require 'mongo'
require 'json'
require 'erb'
require 'cloudinary'
require "digest"

$: << './server'

require 'model'

require 'pp'

configure do
    set :public_folder, 'server/assets'

    GALLERY=ERB.new(File.read('server/assets/gallery.html'))
    EFFECT=ERB.new(File.read("server/assets/index.html"))
    LOGIN=ERB.new(File.read("server/assets/login.html"))
    REGISTER=ERB.new(File.read("server/assets/register.html"))
    REGISTER_COMPLETE=ERB.new(File.read("server/assets/register-complete.html"))

    $glsl=GlslDatabase.new

    EFFECTS_PER_PAGE=50
    BASE_URL="http://localhost:9292/"
    USE_CLOUDINARY=false
    PASSWORD_SALT=""
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

get "/login" do
    li=LogIn.new(BASE_URL)
    LOGIN.result(li.bind)
end

post "/login" do
    # login user here
end

get "/register" do
    r=Register.new(BASE_URL)
    REGISTER.result(r.bind)
end

post "/register" do
    errors = {
        :exists => false,
        :password_error => "",
        :email_error => ""
    }
    # check password and retype password match       
    if params[:password] != params[:retype]
        errors[:exists] = true
        errors[:password_error] = "Password do not match"
    end

    # check if email is already used
    if $glsl.user_exists(params[:email])
        errors[:exists] = true
        errors[:email_error] = "Account is already registered with this email"
    end

    if errors[:exists]
        r = Register.new(BASE_URL)
        r.email = params[:email]
        r.email_error = errors[:email_error]
        r.password_error = errors[:password_error]
        r.handle = params[:username]
        r.group = params[:group]
        REGISTER.result(r.bind)
    else
        # check if group exists, and if not create it
        g = $glsl.group(params[:group])
        user = {
            :email => params[:email],
            :handle => params[:username],
            :password => Digest::SHA256.hexdigest(params[:password] + PASSWORD_SALT),
            :group => g[:group],
            :level => g[:existing] ? UserLevel::BASIC : UserLevel::GROUP_ADMIN
        }
        
        $glsl.register_user(user)

        rc=RegisterComplete.new(BASE_URL, g[:existing], params[:group])
        REGISTER_COMPLETE.result(rc.bind)
    end

end

get "/register/groups" do 
    g = $glsl.groups(params[:term]).limit(20).to_a
    g = g.map { |grp| grp["name"] }
    g.to_json
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



