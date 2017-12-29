
class Effects
    attr_accessor :base_url
    def initialize(effects, extra={})
        @effects=effects
        @extra={
            :page => 0,
            :count => 0,
            :effects_per_page => EFFECTS_PER_PAGE
        }.merge(extra)
    end

    def bind
        binding
    end

    def effects
        @effects
    end

    def extra
        @extra
    end

    def base_url=(url)
        @base_url = url
    end

    def base_url()
        @base_url
    end

    def previous_page
        if @extra[:page]>0
            @extra[:page]-1
        end
    end

    def next_page
        if @extra[:count]>=((@extra[:page]+1)*@extra[:effects_per_page])
            @extra[:page]+1
        end
    end

    def image(effect)
        if effect["image_url"]
            effect["image_url"]
        else
            effect["image"]
        end
    end
end

class Effect
    attr_accessor :base_url
    def initialize(base_url)
        @base_url=base_url
    end

    def bind
        binding
    end

    def base_url=(url)
        @base_url = url
    end

    def base_url()
        @base_url
    end

end

class LogIn
    attr_accessor :base_url
    attr_accessor :handle
    attr_accessor :password

    def initialize(base_url)
        @base_url=base_url
    end

    def bind
        binding
    end

    def base_url=(url)
        @base_url = url
    end

    def base_url()
        @base_url
    end

    def handle=(handle)
        @handle = handle
    end

    def handle()
        @handle
    end

    def password=(password)
        @password = password
    end

    def password()
        @password
    end

end

class Register
    attr_accessor :base_url
    attr_accessor :email
    attr_accessor :handle
    attr_accessor :password
    attr_accessor :group
    
    def initialize(base_url, group)
        @base_url=base_url
        @group=group
    end

    def bind
        binding
    end

    def base_url=(url)
        @base_url = url
    end

    def base_url()
        @base_url
    end

    def email=(email)
        @email = email
    end

    def email()
        @email
    end

    def handle=(handle)
        @handle = handle
    end

    def handle()
        @handle
    end

    def password=(password)
        @password = password
    end

    def password()
        @password
    end

    def group=(group)
        @group = group
    end

    def group()
        @group
    end

end

class GlslDatabase
    attr_accessor :use_cloudinary
    def initialize
        connect_database
        initialize_counter
        initialize_cloudinary
    end

    def use_cloudinary=(use_cloudinary)
        @use_cloudinary = use_cloudinary
    end

    def use_cloudinary()
        @use_cloudinary
    end

    def increment_code_counter
        counter=@counters.find_and_modify({
            :query => {:_id => 'code'},
            :update => {'$inc' => {:counter => 1}}
        })

        counter['counter']
    end

    def save_version(code_id, code)
        time=Time.now
        code_data=JSON.parse(code)

        data={
            :created_at => time,
            :code => code_data['code']
        }
        if @use_cloudinary == true
            res=Cloudinary::Uploader.upload(
                code_data['image'],
                :public_id => code_id.to_s)

            image_url=res['url']
        else
            image_url=code_data["image"]
        end

        @code.find_and_modify({
            :query => { :_id => code_id },
            :update => {
                '$set' => {
                    :modified_at    => time,
                    :image_url      => image_url
                },
                '$push' => { :versions => data }
            }
        })

        code=$glsl.get_code(code_id)

        version=code['versions'].length-1

        "#{code_id}.#{version}"
    end

    def save_effect(code)
        code_data=JSON.parse(code)

        if code_data['code_id'] && !code_data['code_id'].empty?
            m=code_data['code_id'].match(/^(\d+)(\.\d+)?/)
            if m
                save_version(m[1].to_i, code)
            else
                save_new_effect(code)
            end
        else
            save_new_effect(code)
        end
    end

    def save_new_effect(code)
        counter=increment_code_counter

        code_data=JSON.parse(code)

        data={
            :_id => counter,
            :created_at => Time.now,
            :modified_at => Time.now,
            :versions => [],
            :user => code_data['user']
        }

        if code_data['parent']
            m=code_data['parent'].match(%r{^(\d+)(\.(\d+))?})
            data[:parent] = m[1].to_i if m
            data[:parent_version] = m[3].to_i if m && m[3]
        end

        @code.insert(data)

        save_version(counter, code)
    end

    def get_page(page=0, effects_per_page=50)
        count=@code.count()

        effects=@code.find({}, {
            :sort => [:modified_at, 'descending'],
            :limit => effects_per_page,
            :skip => page*effects_per_page
        })

        ef=Effects.new(effects,
            :page   => page,
            :count  => count
        )

        ef
    end

    def get_code(id)
        @code.find_one({:_id => id})
    end

    def get_code_json(id, version=nil)
        code=get_code(id)

        if code
            if version
                item=code['versions'][version]
            else
                item=code['versions'].last
            end
            
            if code['user']
                user=code['user']
            else
                user=false
            end

            parent=nil
            if code['parent']
                parent="/e##{code['parent']}"
                parent+=".#{code['parent_version']}" if code['parent_version']
            end
        else
            item=nil
        end

        if item
            data={
                :code => item['code'],
                :user => user,
                :parent => parent
            }.to_json
        else
            {
                :code => '// item not found',
                :user => false
            }.to_json
        end
    end

private

    def connect_database
        conn = Mongo::Connection.new("localhost", 27017)
        @db = conn.db("glsl")

        @versions=@db.collection('versions')
        @code=@db.collection('code')
        @counters=@db.collection('counters')
    end

    def initialize_counter
        code=@counters.find_one({:_id => 'code'})
        if !code
            @counters.insert({
                :_id => 'code',
                :counter => 0
            })
        end
    end

    def initialize_cloudinary
        Cloudinary.config do |config|
            config.cloud_name = ""
            config.api_key = ""
            config.api_secret = ""
          end   
    end
end
