#!/usr/bin/env ruby
require 'optparse'
require 'uri'
require 'csv'
require 'net/http'
require 'json'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: verify.rb file.csv"

  opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
    options[:verbose] = v
  end
end.parse!

uri = URI('http://api.verify-email.org/api.php')
default_params = { :usr => 'mustwin', 'pwd' => 'mustwin1'}

CSV.open('verified-emails.csv', 'wb') do |verified_csv|
  CSV.open('broken-emails.csv', 'wb') do |broken_csv|
    index = 0
    CSV.foreach(ARGV[0]) do |row|
      if index == 0 # Handle headers
        verified_csv << row
        broken_csv << row
      else
        email = row[0].strip
        print "Testing: #{email}"
        uri.query = URI.encode_www_form(default_params.merge(check: email))
        res = Net::HTTP.get_response(uri)
=begin
{
  "authentication_status":1,
  "limit_status":0,
  "limit_desc": "Not Limited",
  "verify_status":1,
  "verify_status_desc":"MX record about emory.edu exists.<br\/>Connection succeeded to emory.edu.s9a1.psmtp.com SMTP.<br\/>220 Postini ESMTP 222 y706_pstn_c4 ready.  CA Business and Professions Code Section 17538.45 forbids use of this system for unsolicited electronic mail advertisements.<br\/>\n&gt; HELO verify-email.org<br\/>250 Postini says hello back<br\/>\n&gt; MAIL FROM: &lt;check@verify-email.org&gt;<br\/>=250 Ok<br\/>\n&gt; RCPT TO: &lt;ptpate@emory.edu&gt;<br\/>=250 Ok<br\/>\n"
}
=end
        result = JSON.parse(res.body)
        if result['limit_status'].to_i > 0
          puts result['limit_desc']
          exit
        end
        if result['verify_status'].to_i == 1
          puts ' +'
          verified_csv << row
        else
          puts ' -'
          broken_csv << row
        end
      end
      index += 1
    end
  end
end
