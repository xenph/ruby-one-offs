require 'net/http'
require 'json'
require 'base64'
require 'nokogiri'

def check_rate (country_code, weight_in_grams, rate_table)
  if country_code == 'UK'
    data = JSON.parse Net::HTTP.get URI.parse "http://www.royalmail.com/pricefinder/ajax/UK/GB/Packet/#{weight_in_grams}/60/0.0/g"
  else
    data = JSON.parse Net::HTTP.get URI.parse "http://www.royalmail.com/pricefinder/ajax/OV/#{country_code}/Small_Packets/#{weight_in_grams}/60/0.0/g"
  end
  
  data = Nokogiri::HTML(data['data'])
  
  data.css('.display-result-data').each do |item|
    type = item.css('strong.inline').first.content.strip
    cost = item.css('td.display-result-data-expandable').last.content.match(/\d*\.\d*/)[0]
    rate_table[type][country_code][cost] = weight_in_grams.to_i
  end
end

rate_table = Hash.new { |h, k| 
  h[k] = Hash.new {|j, l| j[l] = {}}
}
0.step(6000, 50).each do |weight_in_grams|
  ['AU', 'US', 'UK', 'IT'].each do |country_code|
    puts "Doing #{weight_in_grams}g for #{country_code}"
    check_rate country_code, weight_in_grams, rate_table
  end
end

sorted_rate_table = Hash.new { |h, k| 
  h[k] = Hash.new {|j, l| j[l] = {}}
}

rate_table.each do |shipping_type, quotes_by_country|
  quotes_by_country.each do |country_code, quotes_by_cost|
    quotes_by_cost.each do |cost, max_weight|
      sorted_rate_table[shipping_type][max_weight][country_code] = cost
    end
  end
end

sorted_rate_table.each do |shipping_type, quotes_by_weight|
  quotes_by_weight.each do |max_weight, quotes_by_country|
    weight_in_kilos = Float(max_weight) / 1000.0
    puts "#{shipping_type},#{weight_in_kilos},#{quotes_by_country['UK'] ||= 0},#{quotes_by_country['IT'] ||= 0},#{quotes_by_country['US'] ||= 0},#{quotes_by_country['AU'] ||= 0}"
  end
end

