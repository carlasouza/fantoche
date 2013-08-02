require 'nokogiri'
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
      doc = Nokogiri::HTML(open('http://docs.puppetlabs.com/references/latest/type.html'))
      a = doc.css('div.primary-content')

      data = {}
      last_type = ''
      last_subtype = ''
      last_element = ''
      # Now let's parse the html
      # TODO omg refactor this
      a[0].children.entries.delete_if {|e| !(e.name=='h3' || e.name=='h4' || e.name='dl')}[12..-1].each { |c|
        if c.name == 'h3'
          last_element = 'h3'
          last_type = c.children.first.text
          data[last_type] ||= {}
        elsif c.name == 'h4'
          last_element = 'h4'
          last_subtype = c.children.first.text
          data[last_type][last_subtype] ||= {}
        elsif c.name == 'dl' and last_element == 'h3'
          data[last_type]['desc'] = c.children.text.gsub("\n",' ')
          last_element = 'dl'
        elsif c.name == 'dl' and last_element == 'h4'
          last, param = '', ''
          c.children.each {|dt|
            if dt.name == 'dt'
              param=dt.children.first.text
              last='dt'
            elsif last=='dt' and dt.name == 'dd'
              data[last_type][last_subtype][param] = dt.children.first.text.gsub("\n",' ')
              last=''
            end
          }
          last_element = 'dl'
        end
      }
      data
    end

    def types
      @data ||= load_data
      @data.keys.join ', '
    end

    def desc_type type
      @data ||= load_data
      @data[type]['desc']
    end

    def parameters type
      @data ||= load_data
      @data[type]['Parameters'].keys.join ', '
    end

    def desc_param type, param
      @data ||= load_data
      @data[type]['Parameters'][param]
    end

  end

end

bot.start
