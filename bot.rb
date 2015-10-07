require 'open-uri'
require 'cinch'
require "cinch/plugins/identify"

bot = Cinch::Bot.new do
  configure do |c|
    c.server = "localhost"
    c.nick = 'fantoche'
    c.realname = 'puppet doc bot'
    c.channels = ["#yourchannel"]
    c.user = 'owner_nick' # owner's nick
    c.plugins.plugins = [Cinch::Plugins::Identify] # optionally add more plugins
    c.plugins.options[Cinch::Plugins::Identify] = {
      :username => "fantoche",
      :password => "XXX",
      :type     => :nickserv,
    }
  end

  on :message, /^!help/ do |m|
    m.reply "#{m.user.nick}: !types | !type <type> | !attributes <type> | !attribute <type> <attribute> | !link <type>"
  end

  on :message, /^!reload/ do |m|
    @data = load_data
    m.reply 'Done'
  end

  on :message, /^!types/ do |m|
    m.reply types
  end

  on :message, /^!type (.+)/ do |m, type|
    m.reply("#{m.user.nick}: #{type}: #{desc_type(type) || 'invalid type'}")
  end

  on :message, /^!link (.+)/ do |m, type|
    m.reply("#{m.user.nick}: #{type}: http://docs.puppetlabs.com/references/latest/type.html##{type}")
  end

  on :message, /^!attributes (.+)/ do |m, type|
    m.reply("#{m.user.nick}: #{type}: #{attributes(type) || 'invalid type'}")
  end

  on :message, /^!attribute (.+?) (.+)/ do |m, type, attribute|
    m.reply("#{m.user.nick}: #{type} - #{attribute}: #{desc_attribute(type,attribute) || 'invalid attribute' rescue 'invalid type'}")
  end

  on :message, /^!providers (.+)/ do |m, type|
    m.reply("#{m.user.nick}: #{type} - #{providers(type || 'invalid type')}")
  end

  on :message, /^!provider (.+?) (.+)/ do |m, type, provider|
    m.reply("#{m.user.nick}: #{type} - #{provider}: #{desc_provider(type,provider) || 'invalid provider' rescue 'invalid type'}")
  end

  on :message, /^!features (.+)/ do |m, type|
    m.reply("#{m.user.nick}: #{type} - #{features(type || 'invalid type')}")
  end

  on :message, /^!feature (.+?) (.+)/ do |m, type, feature|
    m.reply("#{m.user.nick}: #{type} - #{feature}: #{desc_feature(type,feature) || 'invalid feature' rescue 'invalid type'}")
  end

  helpers do
    def load_data
      jsonlink = 'http://docs.puppetlabs.com/references/latest/type.json'
      JSON.load(open(jsonlink).read)
    end

    def types
      @data ||= load_data
      @data.keys.join(', ')
    end

    def attributes type
      @data ||= load_data
      @data[type]['attributes'].keys.join(', ')
    end

    def features type
      @data ||= load_data
      @data[type]['features'].keys.join(', ')
    end

    def providers type
      @data ||= load_data
      @data[type]['providers'].keys.join(', ')
    end

    def desc_type type
      @data ||= load_data
      @data[type]['description']
    end

    def desc_attribute type, attribute
      @data ||= load_data
      info = @data[type]['attributes'][attribute]
      description = info['description']
      details = "#{info['kind']}#{info['namevar'] ? ', namevar':''}"
      "#{attribute} (#{details}): #{description}"
    end

    def desc_feature type, feature
      @data ||= load_data
      @data[type]['features'][feature]
    end

    def desc_provider type, provider
      @data ||= load_data
      @data[type]['providers'][provider]['description']
    end

    def munge_desc text
      text.gsub("\n",' ')
    end

    def short_desc text
      munge_desc(text).split('.').first.concat('.')
    end
  end

end

bot.start
