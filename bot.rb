require 'nokogiri'
require 'open-uri'

def init
  @data = load_data
end

def load_data
  doc = Nokogiri::HTML(open('http://docs.puppetlabs.com/references/latest/type.html'))
  a = doc.css('div.primary-content')

  data = {}
  last_type = ''
  last_subtype = ''
  last_element = ''
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
      data[last_type]['desc'] = c.children.text.gsub('\n',' ')
      last_element = 'dl'
    elsif c.name == 'dl' and last_element == 'h4'
      last, param = '', ''
      c.children.each {|dt|
        if dt.name == 'dt'
          param=dt.children.first.text
          p param
#          data[last_type][last_subtype][param] ||= ''
          last='dt'
        elsif last=='dt' and dt.name == 'dd'
          p param
          p dt.children.first.text
          p data[last_type][last_subtype][param]
          data[last_type][last_subtype][param] = dt.children.first.text
          last=''
        end
      }
      last_element = 'dl'
    end
  }
  data
end

def types
  @data.keys
end

def parameters type
  @data[type]['Parameters'].keys
end
