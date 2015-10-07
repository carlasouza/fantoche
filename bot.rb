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
    m.reply "#{m.user.nick}: !types | !type <type> | !parameters <type> | !parameter <type> <parameter> | !link <type>"
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

  on :message, /^!parameters (.+)/ do |m, type|
    m.reply("#{m.user.nick}: #{type}: #{parameters(type) || 'invalid type'}")
  end

  on :message, /^!parameter (.+?) (.+)/ do |m, type, param|
    m.reply("#{m.user.nick}: #{type} - #{param}: #{desc_param(type,param) || 'invalid parameter' rescue 'invalid type'}")
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

    def desc_type type
      @data ||= load_data
      @data[type]['description']
    end

    def parameters type
      @data ||= load_data
      @data[type]['attributes'].keys.join ', '
    end

    def desc_param type, param
      @data ||= load_data
      info = @data[type]['attributes'][param]
      description = info['description']
      details = "#{info['kind']}#{info['namevar'] ? ', namevar':''}"
      "#{param} (#{details}): #{description}"
    end

    def features type
      @data ||= load_data
      @data[type]['features'].keys.join(', ')
    end

    def desc_feature type, feature
      @data ||= load_data
      @data[type]['features'][feature]
    end

    def providers type
      @data ||= load_data
      @data[type]['providers'].keys.join(', ')
    end

    def desc_provider type, provider
      @data ||= load_data
      @data[type]['providers'][provider]['description']
    end

    def munge_desc
      # remove \n
      # prints short
      # prings long description
    end
  end

end

bot.start
